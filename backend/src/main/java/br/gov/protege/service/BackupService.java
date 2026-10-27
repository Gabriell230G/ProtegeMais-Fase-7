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
import java.time.Duration;
import java.time.Instant;
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
 *  6. Manifesto fora do banco: cada backup tambem anota o seu hash em
 *     manifesto.sha256, na pasta dos backups. Depois de uma restauracao a
 *     trilha volta ao ponto do backup (e nao conhece os backups seguintes);
 *     o manifesto continua sabendo quais arquivos o sistema gerou.
 *
 * Escopo: o backup cobre o BANCO. Os arquivos de evidencia (EVIDENCIAS_DIR)
 * entram na copia do volume, responsabilidade da infraestrutura.
 *
 * No perfil PostgreSQL o backup e responsabilidade do servico gerenciado
 * (pg_dump / snapshots do provedor) e o metodo informa isso em vez de fingir.
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);
    private static final DateTimeFormatter CARIMBO = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss-SSS");
    static final String MANIFESTO = "manifesto.sha256";
    public static final String BACKUP = "BACKUP";

    /**
     * Fase 7 | Intervalo minimo entre um backup e o proximo backup MANUAL.
     * A retencao guarda os N arquivos mais recentes; sem este intervalo, N
     * pedidos seguidos (de um ADMIN comprometido, por exemplo) empurravam
     * para fora todo o historico de recuperacao em segundos. O agendado
     * diario nao passa por esta regra.
     */
    public static final Duration INTERVALO_MINIMO_MANUAL = Duration.ofMinutes(10);

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

    /**
     * Fase 7 | Backup pedido pelo ADMIN. Recusado (IllegalStateException,
     * 409 no controlador) se o ultimo backup tem menos de 10 minutos.
     */
    public synchronized Map<String, Object> executarManual() throws IOException {
        if (suportado()) {
            Instant ultimo = ultimoBackup();
            Instant agora = Instant.now();
            if (!intervaloRespeitado(ultimo, agora, INTERVALO_MINIMO_MANUAL)) {
                long faltam = Math.max(1, Duration.between(agora, ultimo.plus(INTERVALO_MINIMO_MANUAL))
                        .toMinutes() + 1);
                throw new IllegalStateException("Ja existe um backup gerado ha menos de "
                        + INTERVALO_MINIMO_MANUAL.toMinutes() + " minutos. Tente de novo em "
                        + faltam + " minuto(s).");
            }
        }
        return executar("manual");
    }

    /** Regra pura: o proximo backup manual so sai depois do intervalo minimo. */
    static boolean intervaloRespeitado(Instant ultimo, Instant agora, Duration minimo) {
        if (ultimo == null) return true;
        return !agora.isBefore(ultimo.plus(minimo));
    }

    /** Data do backup mais recente na pasta, ou null se nao houver. */
    Instant ultimoBackup() throws IOException {
        if (!Files.isDirectory(pasta)) return null;
        Instant maisRecente = null;
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(pasta, "protege-*.zip")) {
            for (Path p : ds) {
                Instant t = Files.getLastModifiedTime(p).toInstant();
                if (maisRecente == null || t.isAfter(maisRecente)) maisRecente = t;
            }
        }
        return maisRecente;
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
        Files.writeString(pasta.resolve(MANIFESTO), hash + "  " + nome + System.lineSeparator(),
                java.nio.charset.StandardCharsets.UTF_8,
                java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
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
     * Lista os backups e confere cada um contra o hash registrado no momento
     * da copia: primeiro o da trilha de auditoria, e na falta dele o do
     * manifesto. "integro" = arquivo bate com o registro; "ALTERADO" = nao
     * bate (NAO restaure); "sem registro" = arquivo que o sistema nao gerou.
     */
    public List<Map<String, Object>> listar(Map<String, String> hashesRegistrados) throws IOException {
        List<Map<String, Object>> lista = new ArrayList<>();
        if (!Files.isDirectory(pasta)) return lista;
        Map<String, String> manifesto = lerManifesto();
        try (Stream<Path> arquivos = Files.list(pasta)) {
            for (Path p : arquivos.filter(f -> f.getFileName().toString().endsWith(".zip"))
                                  .sorted(Comparator.reverseOrder()).toList()) {
                String nome = p.getFileName().toString();
                String atual = sha256(p);
                String registrado = hashesRegistrados.get(nome);
                String fonte = "trilha";
                if (registrado == null) {
                    registrado = manifesto.get(nome);
                    fonte = registrado == null ? null : "manifesto";
                }
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("arquivo", nome);
                item.put("bytes", Files.size(p));
                item.put("sha256Atual", atual);
                item.put("sha256Registrado", registrado);
                item.put("fonteDoRegistro", fonte);
                item.put("situacao", situacao(registrado, atual));
                lista.add(item);
            }
        }
        return lista;
    }

    static String situacao(String registrado, String atual) {
        if (registrado == null) return "sem registro";
        return registrado.equalsIgnoreCase(atual) ? "integro" : "ALTERADO";
    }

    /** Le "hash  nome" por linha. Uma linha posterior com o mesmo nome prevalece. */
    Map<String, String> lerManifesto() throws IOException {
        Map<String, String> m = new java.util.HashMap<>();
        Path arq = pasta.resolve(MANIFESTO);
        if (!Files.isRegularFile(arq)) return m;
        for (String linha : Files.readAllLines(arq, java.nio.charset.StandardCharsets.UTF_8)) {
            String[] partes = linha.trim().split("\\s+", 2);
            if (partes.length == 2 && partes[0].length() == 64) m.put(partes[1].trim(), partes[0]);
        }
        return m;
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
