package br.gov.protege.controller;

import br.gov.protege.audit.Auditavel;
import br.gov.protege.dto.AncoragemResponse;
import br.gov.protege.model.AuditoriaLog;
import br.gov.protege.model.Evidencia;
import br.gov.protege.repository.AuditoriaLogRepository;
import br.gov.protege.repository.EvidenciaRepository;
import br.gov.protege.service.AuditoriaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Fase 7 | Parte 4: dados para ancorar a trilha e as evidencias em blockchain.
 *
 * O servidor nao fala com a blockchain. Quem ancora e quem confere e um
 * roteiro externo (pasta blockchain/), de proposito: a verificacao tem de
 * funcionar sem confiar no proprio servidor, que e justamente o que pode ter
 * sido adulterado ou restaurado.
 *
 * Fica sob /api/auditoria, restrito a AUDITOR e ADMIN pelo SecurityConfig.
 */
@Tag(name = "Auditoria",
     description = "Trilha imutavel de acoes sensiveis, encadeada por hash")
@RestController
@RequestMapping("/api/auditoria/ancoragem")
public class AncoragemController {

    private final AuditoriaService auditoria;
    private final AuditoriaLogRepository trilha;
    private final EvidenciaRepository evidencias;

    public AncoragemController(AuditoriaService auditoria, AuditoriaLogRepository trilha,
                               EvidenciaRepository evidencias) {
        this.auditoria = auditoria;
        this.trilha = trilha;
        this.evidencias = evidencias;
    }

    @Operation(summary = "Estado da trilha para ancoragem",
               description = "Hash do ultimo registro, total de registros, resultado da verificacao "
                           + "da cadeia e os hashes das evidencias com id acima de evidenciasApos "
                           + "(ate 500 por chamada). A propria consulta entra na trilha.",
               security = @SecurityRequirement(name = "bearerAuth"))
    @Auditavel(acao = AuditoriaService.ACESSO_AUDITORIA, recurso = "Ancoragem",
               detalhe = "Estado da trilha lido para ancoragem em blockchain")
    @GetMapping("/estado")
    public AncoragemResponse.Estado estado(
            @Parameter(description = "Maior id de evidencia ja ancorado (0 na primeira vez)")
            @RequestParam(defaultValue = "0") long evidenciasApos) {

        AuditoriaService.EstadoCadeia c = auditoria.estadoDaCadeia();
        AuditoriaLog ultimo = c.ultimo();

        List<Evidencia> lote = evidencias
                .findTop500ByIdGreaterThanAndRemovidaFalseOrderByIdAsc(Math.max(evidenciasApos, 0));
        List<AncoragemResponse.EvidenciaHash> hashes = lote.stream()
                .map(e -> new AncoragemResponse.EvidenciaHash(e.getId(), e.getHashSha256()))
                .toList();
        Long ultimaEvidencia = lote.isEmpty() ? Math.max(evidenciasApos, 0)
                                              : lote.get(lote.size() - 1).getId();

        return new AncoragemResponse.Estado(
                LocalDateTime.now(), c.integra(), c.motivo(), c.rompidoNoRegistro(), c.total(),
                ultimo == null ? null : ultimo.getId(),
                ultimo == null ? null : ultimo.getHash(),
                hashes, ultimaEvidencia, lote.size() == 500);
    }

    @Operation(summary = "Confere um registro ja ancorado",
               description = "Diz se o registro ancorado ainda existe e qual o hash dele hoje. "
                           + "Devolve so o hash e a data, sem usuario nem IP, por isso nao gera "
                           + "registro: e o que um verificador externo consulta periodicamente.",
               security = @SecurityRequirement(name = "bearerAuth"))
    @GetMapping("/registro/{id}")
    public AncoragemResponse.Registro registro(@PathVariable Long id) {
        AuditoriaService.EstadoCadeia c = auditoria.estadoDaCadeia();
        return trilha.findById(id)
                .map(r -> new AncoragemResponse.Registro(id, true, r.getHash(), r.getDataHora(),
                                                         c.total(), c.integra()))
                .orElseGet(() -> new AncoragemResponse.Registro(id, false, null, null,
                                                                c.total(), c.integra()));
    }
}
