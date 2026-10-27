package br.gov.protege.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

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

    /** Ambiente com chave IoT definida, para o teste nao gravar data/iot-chave.txt. */
    private static MockEnvironment ambiente(String demo) {
        return new MockEnvironment()
                .withProperty("protege.demo", demo)
                .withProperty("protege.iot.chave", IOT_FORTE);
    }

    @Test
    @DisplayName("Fase 7 | demonstracao escuta so na propria maquina por padrao")
    void demoPresoAoLoopback() {
        MockEnvironment env = ambiente("true");
        new GuardiaoDeSegredos().postProcessEnvironment(env, null);
        assertEquals("127.0.0.1", env.getProperty("server.address"));
        // A massa de exemplo continua em demonstracao.
        assertNotEquals("never", env.getProperty("spring.sql.init.mode"));
    }

    @Test
    @DisplayName("Fase 7 | demonstracao respeita SERVER_ADDRESS definido de proposito")
    void demoRespeitaEnderecoExplicito() {
        MockEnvironment env = ambiente("true").withProperty("server.address", "0.0.0.0");
        new GuardiaoDeSegredos().postProcessEnvironment(env, null);
        assertEquals("0.0.0.0", env.getProperty("server.address"));
    }

    @Test
    @DisplayName("Fase 7 | producao sem massa de exemplo e sem Swagger publico")
    void producaoSemDataSqlNemSwagger() {
        MockEnvironment env = ambiente("false")
                .withProperty("jwt.secret", JWT_FORTE)
                .withProperty("app.admin.senha", SENHA_FORTE);
        new GuardiaoDeSegredos().postProcessEnvironment(env, null);
        assertEquals("never", env.getProperty("spring.sql.init.mode"));
        assertEquals("false", env.getProperty("springdoc.api-docs.enabled"));
        assertEquals("false", env.getProperty("springdoc.swagger-ui.enabled"));
        assertEquals("false", env.getProperty("spring.h2.console.enabled"));
        assertNull(env.getProperty("server.address"), "em producao o endereco e decisao da implantacao");
    }

    @Test
    @DisplayName("sorteio gera valores diferentes a cada chamada")
    void sorteioNaoRepete() {
        assertNotEquals(GuardiaoDeSegredos.sortear(32), GuardiaoDeSegredos.sortear(32));
        assertTrue(GuardiaoDeSegredos.sortear(48).length() >= 64);
    }
}
