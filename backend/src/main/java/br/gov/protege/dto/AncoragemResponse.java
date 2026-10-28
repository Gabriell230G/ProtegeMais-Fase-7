package br.gov.protege.dto;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Fase 7 | O que a ancoragem em blockchain registra (Parte 4).
 *
 * So hashes e contadores. Nenhum campo identifica pessoa, caso ou conteudo:
 * o hash do ultimo registro da trilha ja resume todos os anteriores (cada um
 * carrega o hash do antecessor), e o hash de uma evidencia e o do arquivo,
 * que o roteiro de ancoragem ainda mistura com um sal aleatorio antes de
 * publicar, para que quem tenha uma copia da foto nao consiga confirmar que
 * ela foi entregue como prova.
 */
public final class AncoragemResponse {

    private AncoragemResponse() {}

    public record Estado(
            LocalDateTime geradoEm,
            boolean trilhaIntegra,
            String motivo,
            Long rompidoNoRegistro,
            int totalRegistros,
            Long ultimoRegistro,
            String hashUltimoRegistro,
            List<EvidenciaHash> evidencias,
            Long ultimaEvidencia,
            boolean haMaisEvidencias) {}

    public record EvidenciaHash(Long id, String hashSha256) {}

    /** Conferencia de um registro ja ancorado: ele ainda existe, com o mesmo hash? */
    public record Registro(Long id, boolean existe, String hash, LocalDateTime dataHora,
                           int totalRegistros, boolean trilhaIntegra) {}
}
