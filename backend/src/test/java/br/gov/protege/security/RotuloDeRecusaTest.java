package br.gov.protege.security;

import br.gov.protege.service.AuditoriaService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Rotulo das recusas na trilha de auditoria")
class RotuloDeRecusaTest {

    private static String acao(String metodo, String uri) {
        return RespostasDeSeguranca.classificarRecusa(metodo, uri)[0];
    }

    private static String recurso(String metodo, String uri) {
        return RespostasDeSeguranca.classificarRecusa(metodo, uri)[1];
    }

    @Test
    @DisplayName("PUT e PATCH negados nao viram EXCLUSAO na trilha")
    void metodoDefineAcao() {
        assertEquals(AuditoriaService.ALTERACAO_DADOS, acao("PUT", "/api/denuncias/5"));
        assertEquals(AuditoriaService.ALTERACAO_STATUS, acao("PATCH", "/api/denuncias/5/status"));
        assertEquals(AuditoriaService.ATRIBUICAO, acao("PATCH", "/api/denuncias/5/responsavel"));
        assertEquals(AuditoriaService.EXCLUSAO, acao("DELETE", "/api/denuncias/5"));
        assertEquals(AuditoriaService.CONSULTA_SENSIVEL, acao("GET", "/api/denuncias/5"));
    }

    @Test
    @DisplayName("evidencias, fila, IA, equipe e backup recebem rotulo proprio")
    void rotasDoPainel() {
        assertEquals("Evidencia", recurso("GET", "/api/evidencias/3/arquivo"));
        assertEquals(AuditoriaService.CONSULTA_SENSIVEL, acao("GET", "/api/denuncias/5/evidencias"));
        assertEquals(AuditoriaService.EXCLUSAO, acao("DELETE", "/api/evidencias/3"));
        assertEquals(AuditoriaService.ALTERACAO_STATUS, acao("POST", "/api/fluxo/desfazer"));
        assertEquals(AuditoriaService.REANALISE_IA, acao("POST", "/api/vigia/analisar/5"));
        assertEquals(AuditoriaService.ALTERACAO_EQUIPE, acao("POST", "/api/equipe"));
        assertEquals("Banco", recurso("POST", "/api/backup"));
        assertEquals(AuditoriaService.ACESSO_AUDITORIA, acao("GET", "/api/auditoria"));
        assertEquals("Rota", recurso("GET", "/api/qualquer"));
    }
}
