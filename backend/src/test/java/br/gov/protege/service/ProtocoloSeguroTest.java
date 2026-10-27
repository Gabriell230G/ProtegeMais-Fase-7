package br.gov.protege.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Protocolo com 59 bits de aleatoriedade")
class ProtocoloSeguroTest {

    @Test
    @DisplayName("formato #ANO-XXXX-XXXX-XXXX e cabe na coluna de 20 caracteres")
    void formato() {
        String p = DenunciaService.novoProtocolo(2026);
        assertTrue(p.matches("#2026-[23456789A-HJKMNP-Z]{4}-[23456789A-HJKMNP-Z]{4}-[23456789A-HJKMNP-Z]{4}"), p);
        assertEquals(20, p.length());
    }

    @Test
    @DisplayName("nao usa caracteres que se confundem (0, O, 1, I, L)")
    void semAmbiguos() {
        for (int i = 0; i < 500; i++) {
            String corpo = DenunciaService.novoProtocolo(2026).substring(6);
            assertFalse(corpo.matches(".*[01OIL].*"), corpo);
        }
    }

    @Test
    @DisplayName("10 mil sorteios sem repeticao")
    void semColisao() {
        Set<String> vistos = new HashSet<>();
        for (int i = 0; i < 10_000; i++) assertTrue(vistos.add(DenunciaService.novoProtocolo(2026)));
    }
}
