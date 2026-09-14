package br.gov.protege.controller;

import br.gov.protege.audit.Auditavel;
import br.gov.protege.dto.AcionamentoSosRequest;
import br.gov.protege.dto.EventoIotResponse;
import br.gov.protege.dto.RegistroTotemRequest;
import br.gov.protege.dto.RegistroTotemResponse;
import br.gov.protege.dto.TelemetriaGeofenceRequest;
import br.gov.protege.dto.TelemetriaResponse;
import br.gov.protege.model.EventoIot;
import br.gov.protege.service.AuditoriaService;
import br.gov.protege.service.EventoIotService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Porta de entrada dos dispositivos fisicos.
 *
 * Estas rotas nao usam JWT, porque nao existe usuario por tras delas: existe
 * um aparelho. A autenticacao e feita por chave compartilhada no cabecalho
 * X-Device-Key, comparada em tempo constante. E uma protecao mais fraca que
 * a do restante da API, e por isso as rotas de dispositivo so conseguem
 * CRIAR evento. Nenhuma delas le, altera ou apaga caso existente.
 */
@Tag(name = "IoT", description = "Barramento de eventos de dispositivos fisicos (Fase 6)")
@RestController
@RequestMapping("/api/iot")
public class IotController {

    private final EventoIotService service;

    public IotController(EventoIotService service) {
        this.service = service;
    }

    @Operation(summary = "Acionamento de botao de panico fisico",
               description = "Recebe o evento de um dispositivo SOS. Abre uma denuncia anonima "
                           + "com o relato do acionamento e deixa a classificacao de urgencia "
                           + "com o VigIA. Acionamentos repetidos do mesmo aparelho dentro de "
                           + "120 segundos sao tratados como repique e vinculados ao mesmo caso.")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "Evento aceito; protocolo no corpo"),
        @ApiResponse(responseCode = "401", description = "Chave do dispositivo ausente ou invalida", content = @Content),
        @ApiResponse(responseCode = "400", description = "Dados invalidos", content = @Content)
    })
    @PostMapping("/acionamento")
    public ResponseEntity<?> acionar(@RequestHeader(value = "X-Device-Key", required = false) String chave,
                                     @Valid @RequestBody AcionamentoSosRequest req) {
        if (!service.autorizado(chave)) {
            return ResponseEntity.status(401)
                    .body(Map.of("erro", "Chave de dispositivo ausente ou invalida"));
        }
        EventoIot evento = service.registrarAcionamento(req);
        return ResponseEntity.status(201).body(EventoIotResponse.de(evento));
    }

    @Operation(summary = "Telemetria de equipamento de monitoracao eletronica",
               description = "Recebe a posicao de uma tornozeleira e avalia o perimetro da medida "
                           + "protetiva NO SERVIDOR. Quando o perimetro e violado, abre um caso "
                           + "critico sozinho. Leituras repetidas dentro de 600 segundos nao "
                           + "geram caso novo: a violacao ja esta alertada.")
    @ApiResponses({
        @ApiResponse(responseCode = "202", description = "Leitura aceita e avaliada"),
        @ApiResponse(responseCode = "401", description = "Chave do dispositivo ausente ou invalida", content = @Content),
        @ApiResponse(responseCode = "400", description = "Dados invalidos", content = @Content)
    })
    @PostMapping("/telemetria")
    public ResponseEntity<?> telemetria(@RequestHeader(value = "X-Device-Key", required = false) String chave,
                                        @Valid @RequestBody TelemetriaGeofenceRequest req) {
        if (!service.autorizado(chave)) {
            return ResponseEntity.status(401)
                    .body(Map.of("erro", "Chave de dispositivo ausente ou invalida"));
        }
        EventoIotService.TelemetriaResultado r = service.registrarTelemetria(req);
        return ResponseEntity.accepted()
                .body(TelemetriaResponse.aceita(r.alertaAberto(), r.protocolo()));
    }

    @Operation(summary = "Registro feito em totem de atendimento publico",
               description = "O totem envia apenas o identificador do equipamento, o tipo e o "
                           + "texto digitado. O lugar do registro vem do cadastro da instalacao, "
                           + "nunca da requisicao.")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "Registro aceito e caso aberto"),
        @ApiResponse(responseCode = "200", description = "Reenvio do mesmo registro; protocolo repetido"),
        @ApiResponse(responseCode = "401", description = "Chave do dispositivo ausente ou invalida", content = @Content),
        @ApiResponse(responseCode = "422", description = "Totem nao habilitado ou relato insuficiente", content = @Content)
    })
    @PostMapping("/totem")
    public ResponseEntity<?> totem(@RequestHeader(value = "X-Device-Key", required = false) String chave,
                                   @Valid @RequestBody RegistroTotemRequest req) {
        if (!service.autorizado(chave)) {
            return ResponseEntity.status(401)
                    .body(Map.of("erro", "Chave de dispositivo ausente ou invalida"));
        }

        EventoIotService.TotemResultado r = service.registrarTotem(req);

        if (r.foiRecusado()) {
            // 422 e nao 400: o corpo da requisicao esta bem formado, o que nao
            // serve e o conteudo. A distincao importa para o proprio totem,
            // que precisa saber se reapresenta a tela de digitacao ou se
            // avisa que o equipamento esta fora de servico.
            return ResponseEntity.unprocessableEntity().body(Map.of("erro", r.recusa()));
        }

        RegistroTotemResponse corpo = r.duplicado()
                ? RegistroTotemResponse.duplicado(r.protocolo(), EventoIotService.SEGUNDOS_TELA_LIMPA)
                : RegistroTotemResponse.aceito(r.protocolo(), EventoIotService.SEGUNDOS_TELA_LIMPA);

        return r.duplicado() ? ResponseEntity.ok(corpo)
                             : ResponseEntity.status(201).body(corpo);
    }

    @Operation(summary = "Ultimos eventos recebidos dos dispositivos",
               description = "Alimenta a tela de dispositivos no painel do orgao.")
    @SecurityRequirement(name = "bearerAuth")
    @Auditavel(acao = AuditoriaService.CONSULTA_SENSIVEL, recurso = "EventoIot",
               detalhe = "Leitura do fluxo de eventos de dispositivos")
    @GetMapping("/eventos")
    public List<EventoIotResponse> eventos(@RequestParam(required = false) String origem,
                                           @RequestParam(defaultValue = "50") int limite) {
        return service.ultimos(origem, limite).stream().map(EventoIotResponse::de).toList();
    }

    @Operation(summary = "Totais por origem de dispositivo")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/resumo")
    public Map<String, Long> resumo() {
        return Map.of(
                EventoIot.SOS,      service.totalPorOrigem(EventoIot.SOS),
                EventoIot.GEOFENCE, service.totalPorOrigem(EventoIot.GEOFENCE),
                EventoIot.TOTEM,    service.totalPorOrigem(EventoIot.TOTEM));
    }
}
