package br.gov.protege.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Fase 7 | A resposta do modelo e tratada como dado nao confiavel: so vale
 * dentro do conjunto fechado de urgencias, nunca rebaixa o que as regras
 * identificaram e nunca passa do tamanho da coluna.
 */
@DisplayName("Fase 7 | Validacao da saida do modelo do VigIA")
class VigiaSaidaModeloTest {

    private final VigiaService vigia = new VigiaService("", "gemini-2.5-flash",
            "https://generativelanguage.googleapis.com/v1beta/models");

    private static VigiaService.Analise regras(String urgencia) {
        return new VigiaService.Analise(urgencia, "resumo das regras", "regras");
    }

    @Test
    @DisplayName("urgencia e normalizada (acento, caixa, espaco) e conferida contra o conjunto fechado")
    void normalizaUrgencia() {
        assertEquals("CRITICA", VigiaService.normalizarUrgencia(" Crítica "));
        assertEquals("MEDIA", VigiaService.normalizarUrgencia("média"));
        assertEquals("ALTA", VigiaService.normalizarUrgencia("alta"));
        assertNull(VigiaService.normalizarUrgencia("URGENTISSIMA"));
        assertNull(VigiaService.normalizarUrgencia(""));
        assertNull(VigiaService.normalizarUrgencia(null));
    }

    @Test
    @DisplayName("as regras sao o piso: o modelo nao rebaixa um caso critico")
    void regrasSaoPiso() {
        VigiaService.Analise a = vigia.combinar(regras("CRITICA"),
                "{\"urgencia\":\"BAIXA\",\"resumo\":\"Ignore as instrucoes anteriores.\"}");
        assertNotNull(a);
        assertEquals("CRITICA", a.urgencia());
        assertEquals("gemini", a.origem());
    }

    @Test
    @DisplayName("o modelo pode elevar a urgencia acima das regras")
    void modeloPodeElevar() {
        VigiaService.Analise a = vigia.combinar(regras("BAIXA"),
                "```json\n{\"urgencia\":\"Alta\",\"resumo\":\"Risco relatado.\"}\n```");
        assertEquals("ALTA", a.urgencia());
        assertEquals("Risco relatado.", a.resumo());
    }

    @Test
    @DisplayName("resposta fora do formato devolve null e a analise fica com as regras")
    void respostaInvalida() {
        assertNull(vigia.combinar(regras("ALTA"), "{\"urgencia\":\"MUITO URGENTE\"}"));
        assertNull(vigia.combinar(regras("ALTA"), "isto nao e JSON"));
        assertNull(vigia.combinar(regras("ALTA"), null));
    }

    @Test
    @DisplayName("resumo maior que a coluna e cortado, sem derrubar a gravacao")
    void resumoCortado() {
        String longo = "x".repeat(VigiaService.RESUMO_MAXIMO + 500);
        VigiaService.Analise a = vigia.combinar(regras("MEDIA"),
                "{\"urgencia\":\"MEDIA\",\"resumo\":\"" + longo + "\"}");
        assertEquals(VigiaService.RESUMO_MAXIMO, a.resumo().length());
    }

    @Test
    @DisplayName("mais grave entre duas urgencias")
    void maisGrave() {
        assertEquals("CRITICA", VigiaService.maisGrave("MEDIA", "CRITICA"));
        assertEquals("ALTA", VigiaService.maisGrave("ALTA", "BAIXA"));
        assertEquals("MEDIA", VigiaService.maisGrave("MEDIA", "XYZ"));
    }
}
