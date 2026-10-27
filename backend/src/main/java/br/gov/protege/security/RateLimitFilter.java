package br.gov.protege.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Limite de requisicoes por origem nas rotas publicas.
 *
 * Duas rotas ficam expostas sem autenticacao, e cada uma tem um risco
 * proprio:
 *
 *   POST /api/auth/login  -> forca bruta de senha
 *   POST /api/denuncias   -> inundacao do canal com denuncias falsas,
 *                            que sobrecarrega a equipe e enterra os
 *                            casos legitimos na fila
 *
 * A janela deslizante e mantida em memoria por IP. Numa implantacao real
 * isso viveria num cache distribuido (Redis) para valer entre instancias;
 * aqui a versao em memoria cumpre o papel e mantem a dependencia zero.
 *
 * Fase 7 | Tres correcoes:
 *  1. A origem passou a ser o endereco REAL da conexao (getRemoteAddr). A
 *     versao anterior confiava no cabecalho X-Forwarded-For, que o proprio
 *     cliente escreve: bastava trocar o valor a cada pedido para nunca ser
 *     barrado. O cabecalho so e lido se protege.proxy-confiavel=true, ou
 *     seja, quando existe de fato um proxy reverso nosso na frente.
 *  2. Rotas que estavam sem limite ganharam um: a consulta publica por
 *     protocolo (que era o caminho para adivinhar protocolos por tentativa)
 *     e a entrada dos dispositivos IoT.
 *  3. O mapa de contagem e limpo periodicamente. Antes ele so crescia: cada
 *     IP novo ficava na memoria para sempre.
 */
public class RateLimitFilter extends OncePerRequestFilter {

    private static final long JANELA_MS = 60_000L;
    // Denuncia e mais restrita de proposito: o custo de uma denuncia falsa em
    // massa recai sobre a equipe de atendimento, nao sobre o servidor.
    private static final int LIMITE_DENUNCIA = 5;    // por minuto, por IP

    // O login e mais folgado porque a chave e o IP, nao o usuario: varios
    // servidores atras do mesmo NAT corporativo compartilham um unico endereco.
    // Um limite apertado ali barraria uma reparticao inteira por causa de
    // uma pessoa que errou a senha. Forca bruta continua contida: 20/min por IP
    // sao 28.800 tentativas por dia contra hashes BCrypt.
    private static final int LIMITE_LOGIN    = 20;   // por minuto, por IP

    // Upload e publico e grava em disco. Sem teto, um unico endereco enche o
    // volume do servidor com arquivos validos - nao e preciso explorar falha
    // nenhuma, basta repetir.
    private static final int LIMITE_UPLOAD   = 10;   // por minuto, por IP

    // Fase 7 | Consulta publica por protocolo. Folgada para uso humano (quem
    // acompanha o proprio caso consulta poucas vezes), apertada para robo:
    // 30 tentativas por minuto inviabilizam varrer o espaco de protocolos.
    static final int LIMITE_CONSULTA = 30;   // por minuto, por IP

    // Fase 7 | Dispositivos de campo. Mais alto porque varios aparelhos podem
    // sair pela mesma rede de operadora; o teto existe para conter inundacao.
    static final int LIMITE_IOT      = 120;  // por minuto, por IP

    // Limpeza do mapa a cada N requisicoes avaliadas.
    private static final int LIMPAR_A_CADA = 500;

    private final Map<String, Deque<Long>> historico = new ConcurrentHashMap<>();
    private final ObjectMapper mapper = new ObjectMapper();
    private final boolean confiarEmProxy;
    private final java.util.concurrent.atomic.AtomicInteger contador =
            new java.util.concurrent.atomic.AtomicInteger();

    public RateLimitFilter() {
        this(false);
    }

    public RateLimitFilter(boolean confiarEmProxy) {
        this.confiarEmProxy = confiarEmProxy;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
                                    @NonNull HttpServletResponse res,
                                    @NonNull FilterChain chain)
            throws ServletException, IOException {

        int limite = limiteDaRota(req);
        if (limite > 0 && excedeu(chaveDe(req), limite)) {
            responder429(res);
            return;
        }
        chain.doFilter(req, res);
    }

    private int limiteDaRota(HttpServletRequest req) {
        return limiteDaRota(req.getMethod(), req.getRequestURI());
    }

    /** Regra pura de qual limite vale para cada rota (testavel sem servidor). */
    static int limiteDaRota(String metodo, String uri) {
        if (uri == null) return 0;
        if ("GET".equalsIgnoreCase(metodo) && uri.startsWith("/api/denuncias/protocolo/")) {
            return LIMITE_CONSULTA;
        }
        if (!"POST".equalsIgnoreCase(metodo)) return 0;
        if ("/api/denuncias".equals(uri)) return LIMITE_DENUNCIA;
        if ("/api/auth/login".equals(uri)) return LIMITE_LOGIN;
        if (uri.startsWith("/api/denuncias/protocolo/") && uri.endsWith("/evidencias")) {
            return LIMITE_UPLOAD;
        }
        if (uri.startsWith("/api/iot/")) return LIMITE_IOT;
        return 0;
    }

    private String chaveDe(HttpServletRequest req) {
        // A consulta por protocolo conta por origem, e nao por protocolo:
        // quem tenta adivinhar troca de protocolo a cada pedido.
        String uri = req.getRequestURI();
        String grupo = uri.startsWith("/api/denuncias/protocolo/") && "GET".equalsIgnoreCase(req.getMethod())
                ? "consulta-protocolo"
                : uri.startsWith("/api/iot/") ? "iot" : uri;
        return grupo + "@" + origem(req, confiarEmProxy);
    }

    /**
     * Endereco de quem fez a requisicao. Por padrao, o da conexao TCP, que o
     * cliente nao consegue falsificar. O X-Forwarded-For so vale quando ha um
     * proxy reverso confiavel na frente (protege.proxy-confiavel=true).
     */
    public static String origem(HttpServletRequest req, boolean confiarEmProxy) {
        if (confiarEmProxy) {
            String fwd = req.getHeader("X-Forwarded-For");
            if (fwd != null && !fwd.isBlank()) return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }

    boolean excedeu(String chave, int limite) {
        return excedeu(chave, limite, System.currentTimeMillis());
    }

    boolean excedeu(String chave, int limite, long agora) {
        if (contador.incrementAndGet() % LIMPAR_A_CADA == 0) limpar(agora);
        Deque<Long> janela = historico.computeIfAbsent(chave, k -> new ArrayDeque<>());
        synchronized (janela) {
            while (!janela.isEmpty() && agora - janela.peekFirst() > JANELA_MS) {
                janela.pollFirst();
            }
            if (janela.size() >= limite) return true;
            janela.addLast(agora);
            return false;
        }
    }

    /** Remove do mapa as origens sem requisicao dentro da janela. */
    void limpar(long agora) {
        historico.entrySet().removeIf(e -> {
            Deque<Long> j = e.getValue();
            synchronized (j) {
                return j.isEmpty() || agora - j.peekLast() > JANELA_MS;
            }
        });
    }

    int origensEmMemoria() {
        return historico.size();
    }

    private void responder429(HttpServletResponse res) throws IOException {
        Map<String, Object> corpo = new LinkedHashMap<>();
        corpo.put("timestamp", LocalDateTime.now().toString());
        corpo.put("status", HttpStatus.TOO_MANY_REQUESTS.value());
        corpo.put("erro", HttpStatus.TOO_MANY_REQUESTS.getReasonPhrase());
        corpo.put("mensagem", "Muitas requisicoes desta origem. Aguarde um minuto e tente novamente.");

        res.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        mapper.writeValue(res.getOutputStream(), corpo);
    }
}
