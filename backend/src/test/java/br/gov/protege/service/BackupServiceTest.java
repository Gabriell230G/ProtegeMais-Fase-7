package br.gov.protege.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Politica de backup")
class BackupServiceTest {

    @Test
    @DisplayName("extrai o hash gravado no detalhe da trilha")
    void hashDoDetalhe() {
        assertEquals("abc123", BackupService.hashDoDetalhe("origem=manual; bytes=10; sha256=abc123"));
        assertEquals("ff", BackupService.hashDoDetalhe("sha256=ff; outro=1"));
        assertNull(BackupService.hashDoDetalhe("sem hash"));
    }

    @Test
    @DisplayName("retencao mantem so os N backups mais recentes")
    void retencao(@TempDir Path pasta) throws Exception {
        for (int d = 1; d <= 9; d++) {
            Files.writeString(pasta.resolve("protege-2026100" + d + "-020000.zip"), "x" + d);
        }
        BackupService b = new BackupService(null, null, pasta.toString(), 7, "jdbc:h2:file:./x");
        assertEquals(2, b.aplicarRetencao());
        assertFalse(Files.exists(pasta.resolve("protege-20261001-020000.zip")));
        assertTrue(Files.exists(pasta.resolve("protege-20261009-020000.zip")));
    }

    @Test
    @DisplayName("hash muda quando o arquivo e alterado")
    void hashDetectaAlteracao(@TempDir Path pasta) throws Exception {
        Path f = pasta.resolve("protege-1.zip");
        Files.writeString(f, "conteudo original");
        String antes = BackupService.sha256(f);
        Files.writeString(f, "conteudo adulterado");
        assertNotEquals(antes, BackupService.sha256(f));
    }

    @Test
    @DisplayName("backup interno so no H2 em arquivo")
    void suportado() {
        assertTrue(new BackupService(null, null, "x", 7, "jdbc:h2:file:./data/protege").suportado());
        assertFalse(new BackupService(null, null, "x", 7, "jdbc:postgresql://h/db").suportado());
        assertFalse(new BackupService(null, null, "x", 7, "jdbc:h2:mem:t").suportado());
    }

    @Test
    @DisplayName("situacao: integro, ALTERADO ou sem registro")
    void situacao() {
        assertEquals("integro", BackupService.situacao("ab", "AB"));
        assertEquals("ALTERADO", BackupService.situacao("ab", "cd"));
        assertEquals("sem registro", BackupService.situacao(null, "cd"));
    }

    @Test
    @DisplayName("manifesto fora do banco: a ultima linha de cada arquivo prevalece")
    void manifesto(@TempDir Path pasta) throws Exception {
        String h1 = "a".repeat(64), h2 = "b".repeat(64);
        Files.writeString(pasta.resolve(BackupService.MANIFESTO),
                h1 + "  protege-1.zip\n" + h2 + "  protege-1.zip\nlinha invalida\n");
        BackupService b = new BackupService(null, null, pasta.toString(), 7, "jdbc:h2:file:./x");
        assertEquals(h2, b.lerManifesto().get("protege-1.zip"));
        assertEquals(1, b.lerManifesto().size());
    }

    @Test
    @DisplayName("Fase 7 | backup manual so depois de 10 minutos do anterior")
    void intervaloMinimoManual() {
        Instant base = Instant.parse("2026-10-27T12:00:00Z");
        Duration dez = BackupService.INTERVALO_MINIMO_MANUAL;
        assertTrue(BackupService.intervaloRespeitado(null, base, dez), "sem backup anterior, libera");
        assertFalse(BackupService.intervaloRespeitado(base, base.plusSeconds(60), dez));
        assertFalse(BackupService.intervaloRespeitado(base, base.plusSeconds(599), dez));
        assertTrue(BackupService.intervaloRespeitado(base, base.plusSeconds(600), dez));
    }

    @Test
    @DisplayName("Fase 7 | pedidos manuais seguidos nao rotacionam o historico")
    void manualRecusadoLogoAposOutro(@TempDir Path pasta) throws Exception {
        Files.writeString(pasta.resolve("protege-20261027-120000-000.zip"), "recente");
        BackupService b = new BackupService(null, null, pasta.toString(), 7, "jdbc:h2:file:./x");
        assertNotNull(b.ultimoBackup());
        IllegalStateException e = assertThrows(IllegalStateException.class, b::executarManual);
        assertTrue(e.getMessage().contains("10 minutos"));
        assertTrue(Files.exists(pasta.resolve("protege-20261027-120000-000.zip")), "nada foi apagado");
    }
}
