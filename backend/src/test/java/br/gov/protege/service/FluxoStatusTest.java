package br.gov.protege.service;

import br.gov.protege.exception.ConflitoException;
import br.gov.protege.exception.RegraDeNegocioException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Maquina de estados do caso")
class FluxoStatusTest {

    @Test
    @DisplayName("avancos do Kanban sao permitidos a qualquer perfil que trabalha o caso")
    void avancosPermitidos() {
        String[][] avancos = {
                {"recebida", "analise"}, {"analise", "encaminhada"}, {"encaminhada", "concluida"},
                {"recebida", "encaminhada"}, {"recebida", "concluida"}, {"analise", "concluida"}
        };
        for (String[] t : avancos) {
            assertEquals(FluxoStatus.Transicao.AVANCO, FluxoStatus.classificar(t[0], t[1]));
            assertTrue(FluxoStatus.validar(t[0], t[1], false), t[0] + " -> " + t[1]);
            assertTrue(FluxoStatus.validar(t[0], t[1], true), t[0] + " -> " + t[1]);
        }
    }

    @Test
    @DisplayName("pedir a etapa atual nao muda nada, para qualquer perfil")
    void mesmaEtapaNaoMuda() {
        for (String s : FluxoStatus.ETAPAS) {
            assertEquals(FluxoStatus.Transicao.MESMA, FluxoStatus.classificar(s, s));
            assertFalse(FluxoStatus.validar(s, s, false));
            assertFalse(FluxoStatus.validar(s, s, true));
        }
    }

    @Test
    @DisplayName("reabrir caso concluido: so GESTOR/ADMIN; demais recebem 409")
    void reabertura() {
        assertEquals(FluxoStatus.Transicao.RETORNO, FluxoStatus.classificar("concluida", "analise"));
        assertTrue(FluxoStatus.validar("concluida", "analise", true));
        assertTrue(FluxoStatus.validar("concluida", "recebida", true));
        ConflitoException e = assertThrows(ConflitoException.class,
                () -> FluxoStatus.validar("concluida", "encaminhada", false));
        assertTrue(e.getMessage().startsWith("Reabrir"));
    }

    @Test
    @DisplayName("voltar etapa sem estar concluido: so GESTOR/ADMIN")
    void retornoDeEtapa() {
        assertTrue(FluxoStatus.validar("encaminhada", "analise", true));
        assertTrue(FluxoStatus.validar("analise", "recebida", true));
        ConflitoException e = assertThrows(ConflitoException.class,
                () -> FluxoStatus.validar("encaminhada", "analise", false));
        assertTrue(e.getMessage().startsWith("Devolver"));
        assertThrows(ConflitoException.class, () -> FluxoStatus.validar("analise", "recebida", false));
    }

    @Test
    @DisplayName("status inexistente e recusado; status atual desconhecido conta como inicio")
    void statusInvalido() {
        assertThrows(RegraDeNegocioException.class, () -> FluxoStatus.classificar("recebida", "arquivada"));
        assertThrows(RegraDeNegocioException.class, () -> FluxoStatus.classificar("recebida", null));
        assertEquals(FluxoStatus.Transicao.AVANCO, FluxoStatus.classificar(null, "recebida"));
        assertEquals(FluxoStatus.Transicao.AVANCO, FluxoStatus.classificar("legado", "analise"));
    }
}
