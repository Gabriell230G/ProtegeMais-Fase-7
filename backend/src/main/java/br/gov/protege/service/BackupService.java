package br.gov.protege.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

/**
 * Fase 7 | Politica de backup (pilar DISPONIBILIDADE da triade CIA).
 *
 * Regras da politica, implementadas aqui:
 *  1. Backup online, sem parar o sistema: o comando BACKUP TO do H2 gera um
 *     .zip consistente do banco enquanto ele esta em uso.
 *  2. Frequencia: diaria (02:30) por agendamento, e sob demanda pelo ADMIN.
 *  3. Retencao: os N mais recentes (padrao 7); os mais antigos sao apagados.
 *  4. Integridade do proprio backup: o SHA-256 do arquivo e calculado no
 *     momento da copia e gravado na trilha de auditoria encadeada. Assim, um
 *     backup trocado ou corrompido depois e detectado ANTES de ser restaurado.
 *  5. Separacao: a pasta de backups e configuravel (BACKUP_DIR) para ficar
 *     em outro disco ou volume, e nao ao lado do banco que ela protege.
 *
 * No perfil PostgreSQL o backup e responsabilidade do servico gerenciado
 * (pg_dump / snapshots do provedor) e o metodo informa isso em vez de fingir.
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);
    private static final DateTimeFormatter CARIMBO = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");
    public static final String BACKUP = "BACKUP";

    private final JdbcTemplate jdbc;
    private final AuditoriaService auditoria;
    private final Path pasta;
    private final int retencao;
    private final String urlBanco;

    public BackupService(JdbcTemplate jdbc,
                         AuditoriaService auditoria,
                         @Value("${protege.backup.dir:./data/backups}") String pasta,
                         @Value("${protege.backup.retencao:7}") int retencao,
                         @Value("${spring.datasource.url:}") String urlBanco) {
        this.jdbc = jdbc;
        this.auditoria = auditoria;
        this.pasta = Path.of(pasta);
        this.retencao = Math.max(1, retencao);
        this.urlBanco = urlBanco == null ? "" : urlBanco;
    }

    public boolean suportado() {
        return urlBanco.startsWith("jdbc:h2:file:");
    }

    /** Backup diario agendado. */
    @Scheduled(cron = "${protege.backup.cron:0 30 2 * * *}")
    public void backupAgendado() {
        if (!suportado()) return;
        try {
            executar("agendado");
        } catch (Exception e) {
            log.error("[Protege+] Falha no backup agendado: {}", e.getMessage());
        }
    }

    /** Gera um backup agora e devolve nome, tamanho e hash. */
    public synchronized Map<String, Object> executar(String origem) throws IOException {
        if (!suportado()) {
            throw new IllegalStateException(
                    "Backup interno disponivel apenas no H2 em arquivo. No PostgreSQL, use o "
                    + "backup do servico gerenciado (pg_dump ou snapshot do provedor).");
        }
        Files.createDirectories(pasta);
        String nome = "protege-" + LocalDateTime.now().format(CARIMBO) + ".zip";
        Path destino = pasta.resolve(nome).toAbsolutePath().normalize();

        // Caminho com barras normais: o H2 aceita em qualquer sistema.
        String alvo = destino.toString().replace('\\', '/').replace("'", "''");
        jdbc.execute("BACKUP TO '" + alvo + "'");

        String hash = sha256(destino);
        long tamanho = Files.size(destino);
        auditoria.registrar(BACKUP, "Banco", nome, AuditoriaService.PERMITIDO,
                "origem=" + origem + "; bytes=" + tamanho + "; sha256=" + hash);
        int removidos = aplicarRetencao();
        log.info("[Protege+] Backup {} gerado ({} bytes, {} antigos removidos)", nome, tamanho, removidos);

        Map<String, Object> r = new LinkedHashMap<>();
        r.put("arquivo", nome);
        r.put("bytes", tamanho);
        r.put("sha256", hash);
        r.put("removidosPorRetencao", removidos);
        return r;
    }

    /**
     * Lista os backups e confere cada um contra o hash gravado na trilha.
     * "integro" = arquivo bate com o registro; "ALTERADO" = nao bate;
     * "sem registro" = arquivo que o sistema nao gerou (suspeito).
     */
    public List<Map<String, Object>> listar(Map<String, String> hashesRegistrados) throws IOException {
        List<Map<String, Object>> lista = new ArrayList<>();
        if (!Files.isDirectory(pasta)) return lista;
        try (Stream<Path> arquivos = Files.list(pasta)) {
            for (Path p : arquivos.filter(f -> f.getFileName().toString().endsWith(".zip"))
                                  .sorted(Comparator.reverseOrder()).toList()) {
                String nome = p.getFileName().toString();
                String atual = sha256(p);
                String registrado = hashesRegistrados.get(nome);
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("arquivo", nome);
                item.put("bytes", Files.size(p));
                item.put("sha256", atual);
                item.put("situacao", registrado == null ? "sem registro"
                                   : registrado.equals(atual) ? "integro" : "ALTERADO");
                lista.add(item);
            }
        }
        return lista;
    }

    int aplicarRetencao() throws IOException {
        List<Path> zips = new ArrayList<>();
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(pasta, "protege-*.zip")) {
            ds.forEach(zips::add);
        }
        zips.sort(Comparator.reverseOrder()); // nome tem carimbo: mais novo primeiro
        int removidos = 0;
        for (int i = retencao; i < zips.size(); i++) {
            Files.deleteIfExists(zips.get(i));
            removidos++;
        }
        return removidos;
    }

    static String sha256(Path arquivo) throws IOException {
        try (InputStream in = Files.newInputStream(arquivo)) {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) md.update(buf, 0, n);
            return HexFormat.of().formatHex(md.digest());
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Extrai "sha256=..." do detalhe gravado na trilha. */
    public static String hashDoDetalhe(String detalhe) {
        if (detalhe == null) return null;
        int i = detalhe.indexOf("sha256=");
        if (i < 0) return null;
        String resto = detalhe.substring(i + 7).trim();
        int fim = resto.indexOf(';');
        return fim < 0 ? resto : resto.substring(0, fim);
    }
}
