package br.gov.protege.service;

import br.gov.protege.model.Denuncia;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | O relato nao sai do servidor por padrao")
class VigiaPrivacidadeTest {

    private static final String URL = "https://generativelanguage.googleapis.com/v1beta/models";

    private Denuncia denuncia() {
        Denuncia d = new Denuncia();
        d.setTipo("violencia");
        d.setLocal("Osasco, SP");
        d.setDescricao("Meu vizinho na Rua das Flores, 123 me ameaca. Meu fone e (11) 98765-4321.");
        return d;
    }

    @Test
    @DisplayName("padrao: a IA externa nao recebe o texto do relato")
    void padraoNaoEnvia() {
        VigiaService v = new VigiaService("chave", "gemini-2.5-flash", URL);
        assertFalse(v.enviaRelato());
        String enviado = v.relatoParaIa(denuncia());
        assertFalse(enviado.contains("vizinho"));
        assertFalse(enviado.contains("98765"));
    }

    @Test
    @DisplayName("ligado: o relato sai, mas mascarado")
    void ligadoEnviaMascarado() {
        VigiaService v = new VigiaService("chave", "gemini-2.5-flash", URL, true, 1000);
        String enviado = v.relatoParaIa(denuncia());
        assertTrue(enviado.contains("ameaca"));
        assertFalse(enviado.contains("Flores"));
        assertFalse(enviado.contains("98765-4321"));
    }
}
