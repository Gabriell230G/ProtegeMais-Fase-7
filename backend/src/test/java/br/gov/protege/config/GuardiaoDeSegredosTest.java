package br.gov.protege.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Guardiao de segredos (modo producao)")
class GuardiaoDeSegredosTest {

    private static final String JWT_FORTE = "x".repeat(40);
    private static final String SENHA_FORTE = "Senh@Forte2026!";
    private static final String IOT_FORTE = "chave-iot-lote-07-abc";

    @Test
    @DisplayName("aceita segredos fortes")
    void aceitaSegredosFortes() {
        assertTrue(GuardiaoDeSegredos.validarProducao(JWT_FORTE, SENHA_FORTE, IOT_FORTE).isEmpty());
    }

    @Test
    @DisplayName("recusa subir sem segredos, apontando os tres problemas")
    void recusaSemSegredos() {
        List<String> p = GuardiaoDeSegredos.validarProducao("", "", "");
        assertEquals(3, p.size());
    }

    @Test
    @DisplayName("recusa a senha de demonstracao mesmo que alguem a configure")
    void recusaSenhaDeDemonstracao() {
        List<String> p = GuardiaoDeSegredos.validarProducao(JWT_FORTE, "admin123", IOT_FORTE);
        assertEquals(1, p.size());
        assertTrue(p.get(0).contains("ADMIN_SENHA"));
    }

    @Test
    @DisplayName("recusa segredo de token curto demais")
    void recusaJwtCurto() {
        List<String> p = GuardiaoDeSegredos.validarProducao("curto", SENHA_FORTE, IOT_FORTE);
        assertTrue(p.get(0).contains("JWT_SECRET"));
    }

    @Test
    @DisplayName("sorteio gera valores diferentes a cada chamada")
    void sorteioNaoRepete() {
        assertNotEquals(GuardiaoDeSegredos.sortear(32), GuardiaoDeSegredos.sortear(32));
        assertTrue(GuardiaoDeSegredos.sortear(48).length() >= 64);
    }
}
