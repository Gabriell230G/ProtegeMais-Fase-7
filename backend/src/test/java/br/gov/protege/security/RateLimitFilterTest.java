package br.gov.protege.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Limite de requisicoes")
class RateLimitFilterTest {

    @Test
    @DisplayName("consulta por protocolo e entrada IoT passaram a ter limite")
    void novasRotasTemLimite() {
        assertEquals(RateLimitFilter.LIMITE_CONSULTA,
                RateLimitFilter.limiteDaRota("GET", "/api/denuncias/protocolo/2026-ABCD-EFGH-JKMN"));
        assertEquals(RateLimitFilter.LIMITE_IOT, RateLimitFilter.limiteDaRota("POST", "/api/iot/sos"));
        assertEquals(0, RateLimitFilter.limiteDaRota("GET", "/api/denuncias"));
    }

    @Test
    @DisplayName("X-Forwarded-For e ignorado sem proxy confiavel")
    void ignoraCabecalhoForjado() {
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setRemoteAddr("203.0.113.9");
        req.addHeader("X-Forwarded-For", "1.2.3.4");
        assertEquals("203.0.113.9", RateLimitFilter.origem(req, false));
        assertEquals("1.2.3.4", RateLimitFilter.origem(req, true));
    }

    @Test
    @DisplayName("bloqueia ao passar do limite dentro da janela de um minuto")
    void bloqueiaNoLimite() {
        RateLimitFilter f = new RateLimitFilter();
        long t = 1_000_000L;
        for (int i = 0; i < 5; i++) assertFalse(f.excedeu("k", 5, t + i));
        assertTrue(f.excedeu("k", 5, t + 10));
        assertFalse(f.excedeu("k", 5, t + 61_000), "janela expirou, volta a aceitar");
    }

    @Test
    @DisplayName("limpeza remove origens inativas da memoria")
    void limpezaRemoveInativos() {
        RateLimitFilter f = new RateLimitFilter();
        f.excedeu("a", 5, 0L);
        f.excedeu("b", 5, 0L);
        assertEquals(2, f.origensEmMemoria());
        f.limpar(120_000L);
        assertEquals(0, f.origensEmMemoria());
    }
}
