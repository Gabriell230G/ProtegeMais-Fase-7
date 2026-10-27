package br.gov.protege.controller;

import br.gov.protege.model.AuditoriaLog;
import br.gov.protege.repository.AuditoriaLogRepository;
import br.gov.protege.service.BackupService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Fase 7 | Backup do banco (pilar Disponibilidade) com verificacao de
 * integridade (pilar Integridade).
 */
@Tag(name = "Backup", description = "Backup online do banco, retencao e conferencia por hash")
@RestController
@RequestMapping("/api/backup")
public class BackupController {

    private static final org.slf4j.Logger log =
            org.slf4j.LoggerFactory.getLogger(BackupController.class);

    private final BackupService backup;
    private final AuditoriaLogRepository trilha;

    public BackupController(BackupService backup, AuditoriaLogRepository trilha) {
        this.backup = backup;
        this.trilha = trilha;
    }

    @Operation(summary = "Gera um backup agora (ADMIN)",
               description = "Copia consistente do banco sem parar o sistema. O SHA-256 do "
                           + "arquivo fica gravado na trilha de auditoria encadeada.",
               security = @SecurityRequirement(name = "bearerAuth"))
    @PostMapping
    public ResponseEntity<?> gerar() {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(backup.executar("manual"));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("erro", e.getMessage()));
        } catch (Exception e) {
            log.error("[Protege+] Falha no backup manual", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("erro", "Falha ao gerar o backup"));
        }
    }

    @Operation(summary = "Lista os backups e confere cada um contra o hash da trilha (ADMIN, AUDITOR)",
               security = @SecurityRequirement(name = "bearerAuth"))
    @GetMapping
    public ResponseEntity<?> listar() throws Exception {
        Map<String, String> registrados = new HashMap<>();
        for (AuditoriaLog a : trilha.findByAcaoOrderByIdAsc(BackupService.BACKUP)) {
            String h = BackupService.hashDoDetalhe(a.getDetalhe());
            if (h != null) registrados.put(a.getRecursoId(), h);
        }
        List<Map<String, Object>> itens = backup.listar(registrados);
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("suportado", backup.suportado());
        r.put("total", itens.size());
        r.put("integros", itens.stream().filter(i -> "integro".equals(i.get("situacao"))).count());
        r.put("backups", itens);
        return ResponseEntity.ok(r);
    }
}
