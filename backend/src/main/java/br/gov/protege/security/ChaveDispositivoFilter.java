package br.gov.protege.security;

import br.gov.protege.service.EventoIotService;
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
import java.util.Map;

/**
 * Fase 7 | Confere a chave do dispositivo ANTES de o corpo ser lido.
 *
 * Antes a chave era conferida dentro do controlador, depois que o Spring ja
 * tinha lido o corpo, convertido o JSON e rodado a validacao. Requisicao sem
 * chave valida custava o mesmo que uma legitima. Agora ela para aqui, com o
 * mesmo 401 de antes, sem tocar no corpo. O controlador mantem a sua
 * conferencia como segunda barreira.
 *
 * Proximo passo (fora desta fase): chave POR DISPOSITIVO, com credencial
 * propria de cada aparelho (por exemplo MQTT com usuario e certificado por
 * equipamento), para que comprometer um totem nao comprometa a tornozeleira.
 */
public class ChaveDispositivoFilter extends OncePerRequestFilter {

    public static final String CABECALHO = "X-Device-Key";

    private final String chaveEsperada;
    private final ObjectMapper mapper = new ObjectMapper();

    public ChaveDispositivoFilter(String chaveEsperada) {
        this.chaveEsperada = chaveEsperada;
    }

    /** So as rotas de entrada de dispositivo (POST /api/iot/...). */
    static boolean rotaDeDispositivo(String metodo, String uri) {
        return "POST".equalsIgnoreCase(metodo) && uri != null && uri.startsWith("/api/iot/");
    }

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest req) {
        return !rotaDeDispositivo(req.getMethod(), req.getRequestURI());
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest req,
                                    @NonNull HttpServletResponse res,
                                    @NonNull FilterChain chain)
            throws ServletException, IOException {

        if (!EventoIotService.chaveValida(chaveEsperada, req.getHeader(CABECALHO))) {
            res.setStatus(HttpStatus.UNAUTHORIZED.value());
            res.setContentType(MediaType.APPLICATION_JSON_VALUE);
            res.setCharacterEncoding("UTF-8");
            mapper.writeValue(res.getOutputStream(),
                    Map.of("erro", "Chave de dispositivo ausente ou invalida"));
            return;
        }
        chain.doFilter(req, res);
    }
}
