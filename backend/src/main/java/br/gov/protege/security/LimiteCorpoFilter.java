package br.gov.protege.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Fase 7 | Teto para o corpo das requisicoes que nao sao upload.
 *
 * O multipart ja tinha limite (6/8 MB), mas o corpo JSON nao: um POST
 * publico com dezenas de megabytes era lido inteiro para a memoria e
 * desserializado antes de qualquer validacao. Os maiores corpos legitimos
 * da API (relato de 4000 caracteres, relato do totem de 8000) ficam muito
 * abaixo de 256 KB.
 *
 * Duas barreiras:
 *  1. Content-Length declarado acima do teto: 413 na hora, sem ler nada.
 *  2. Sem Content-Length (envio em blocos) ou com valor mentiroso: o corpo
 *     e lido por um contador, que interrompe a leitura ao passar do teto. O
 *     GlobalExceptionHandler converte essa interrupcao em 413.
 *
 * Upload (multipart/form-data) fica de fora: tem limite proprio.
 */
public class LimiteCorpoFilter extends OncePerRequestFilter {

    /** 256 KB. */
    public static final long LIMITE_BYTES = 256L * 1024;

    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
                                    @NonNull HttpServletResponse res,
                                    @NonNull FilterChain chain)
            throws ServletException, IOException {

        if (ehMultipart(req)) {
            chain.doFilter(req, res);
            return;
        }
        if (req.getContentLengthLong() > LIMITE_BYTES) {
            responder413(res);
            return;
        }
        chain.doFilter(new CorpoLimitado(req, LIMITE_BYTES), res);
    }

    static boolean ehMultipart(HttpServletRequest req) {
        String tipo = req.getContentType();
        return tipo != null && tipo.toLowerCase(java.util.Locale.ROOT).startsWith("multipart/");
    }

    private void responder413(HttpServletResponse res) throws IOException {
        Map<String, Object> corpo = new LinkedHashMap<>();
        corpo.put("timestamp", LocalDateTime.now().toString());
        corpo.put("status", HttpStatus.PAYLOAD_TOO_LARGE.value());
        corpo.put("erro", HttpStatus.PAYLOAD_TOO_LARGE.getReasonPhrase());
        corpo.put("mensagem", "Corpo da requisicao acima do limite de " + (LIMITE_BYTES / 1024) + " KB");

        res.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        mapper.writeValue(res.getOutputStream(), corpo);
    }

    /** Sinaliza que a leitura passou do teto. Tratada como 413. */
    public static class CorpoGrandeDemaisException extends IOException {
        public CorpoGrandeDemaisException(long limite) {
            super("Corpo da requisicao acima de " + limite + " bytes");
        }
    }

    /** Requisicao cujo corpo so pode ser lido ate o teto. */
    static class CorpoLimitado extends HttpServletRequestWrapper {

        private final long limite;
        private ServletInputStream entrada;
        private BufferedReader leitor;

        CorpoLimitado(HttpServletRequest req, long limite) {
            super(req);
            this.limite = limite;
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            if (entrada == null) {
                entrada = new EntradaContada(super.getInputStream(), limite);
            }
            return entrada;
        }

        @Override
        public BufferedReader getReader() throws IOException {
            if (leitor == null) {
                String nome = getCharacterEncoding();
                Charset cs = nome == null ? StandardCharsets.UTF_8 : Charset.forName(nome);
                leitor = new BufferedReader(new InputStreamReader(getInputStream(), cs));
            }
            return leitor;
        }
    }

    /** Conta os bytes lidos e interrompe ao passar do teto. */
    static class EntradaContada extends ServletInputStream {

        private final ServletInputStream origem;
        private final long limite;
        private long lidos;

        EntradaContada(ServletInputStream origem, long limite) {
            this.origem = origem;
            this.limite = limite;
        }

        @Override
        public int read() throws IOException {
            int b = origem.read();
            if (b >= 0) contar(1);
            return b;
        }

        @Override
        public int read(byte[] b, int off, int len) throws IOException {
            int n = origem.read(b, off, len);
            if (n > 0) contar(n);
            return n;
        }

        private void contar(int n) throws IOException {
            lidos += n;
            if (lidos > limite) throw new CorpoGrandeDemaisException(limite);
        }

        @Override
        public boolean isFinished() {
            return origem.isFinished();
        }

        @Override
        public boolean isReady() {
            return origem.isReady();
        }

        @Override
        public void setReadListener(ReadListener listener) {
            origem.setReadListener(listener);
        }
    }
}
