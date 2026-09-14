package br.gov.protege.controller;

import br.gov.protege.audit.Auditavel;
import br.gov.protege.service.AuditoriaService;
import br.gov.protege.service.ReincidenciaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Focos de reincidencia.
 *
 * Rota protegida e auditada. A leitura devolve protocolos agrupados, e um
 * agrupamento diz mais do que os itens separados: saber que seis relatos
 * anonimos descrevem a mesma situacao e uma informacao sensivel sobre um
 * lugar e sobre as pessoas que vivem nele. Por isso a consulta fica no
 * mesmo regime de auditoria das demais leituras sensiveis.
 */
@RestController
@RequestMapping("/api/reincidencia")
public class ReincidenciaController {

    private final ReincidenciaService service;

    public ReincidenciaController(ReincidenciaService service) {
        this.service = service;
    }

    @Operation(summary = "Focos de reincidencia detectados na janela",
               description = "Agrupa denuncias encadeadas no tempo por componentes conexos. "
                           + "Um foco e uma cadeia continua, e nao um balde: o agrupamento "
                           + "termina quando a cadeia se interrompe.")
    @SecurityRequirement(name = "bearerAuth")
    @Auditavel(acao = AuditoriaService.CONSULTA_SENSIVEL, recurso = "Reincidencia",
               detalhe = "Leitura dos focos de reincidencia")
    @GetMapping("/focos")
    public List<ReincidenciaService.Foco> focos(@RequestParam(defaultValue = "90") int dias) {
        return service.focos(dias);
    }

    @Operation(summary = "Parametros da analise",
               description = "Expoe as constantes que governam o agrupamento, para que a tela "
                           + "possa explicar ao usuario o criterio em vez de apenas exibir o "
                           + "resultado.")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/parametros")
    public Map<String, Integer> parametros() {
        return Map.of("janelaEloDias",  ReincidenciaService.JANELA_ELO_DIAS,
                      "minimoParaFoco", ReincidenciaService.MINIMO_PARA_FOCO);
    }
}
