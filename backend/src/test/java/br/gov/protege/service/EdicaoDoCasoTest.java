package br.gov.protege.service;

import br.gov.protege.dto.DenunciaRequest;
import br.gov.protege.model.Denuncia;
import br.gov.protege.util.MascaraUtil;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Edicao do caso pelo orgao")
class EdicaoDoCasoTest {

    private static final String RELATO = "Relato original escrito pela vitima, com detalhes.";

    private Denuncia caso() {
        Denuncia d = new Denuncia();
        d.setTipo("violencia");
        d.setDescricao(RELATO);
        d.setEstado("SP");
        d.setCidade("Osasco");
        d.setEndereco("Rua das Flores, 123");
        d.setAnonimo(true);
        d.setLocal("Osasco, SP");
        return d;
    }

    private DenunciaRequest pedido(String tipo, String descricao, String endereco) {
        DenunciaRequest r = new DenunciaRequest();
        r.setTipo(tipo);
        r.setDescricao(descricao);
        r.setEstado("sp");
        r.setCidade("Osasco");
        r.setEndereco(endereco);
        r.setAnonimo(true);
        return r;
    }

    @Test
    @DisplayName("o relato do denunciante nao e reescrito; a tentativa vai para a trilha")
    void relatoImutavel() {
        Denuncia d = caso();
        EdicaoDoCaso.Edicao e = EdicaoDoCaso.aplicar(d,
                pedido("violencia", "Texto trocado pelo servidor.", "Rua das Flores, 123"), true);

        assertEquals(RELATO, d.getDescricao());
        assertEquals(List.of("descricao"), e.ignorados());
        assertTrue(e.alterados().isEmpty());
        assertTrue(e.resumo().contains("descricao"));
        assertFalse(e.resumo().contains("trocado"), "a trilha leva o nome do campo, nunca o valor");
    }

    @Test
    @DisplayName("ATENDENTE: endereco vazio ou mascarado nao apaga o endereco real")
    void atendenteNaoApagaEndereco() {
        Denuncia d = caso();
        EdicaoDoCaso.Edicao e = EdicaoDoCaso.aplicar(d, pedido("assedio", RELATO, ""), false);
        assertEquals("Rua das Flores, 123", d.getEndereco());
        assertEquals(List.of("tipo"), e.alterados());

        EdicaoDoCaso.aplicar(d, pedido("assedio", RELATO, MascaraUtil.ENDERECO_PROTEGIDO), false);
        assertEquals("Rua das Flores, 123", d.getEndereco());

        EdicaoDoCaso.aplicar(d, pedido("assedio", RELATO, null), false);
        assertEquals("Rua das Flores, 123", d.getEndereco());
    }

    @Test
    @DisplayName("GESTOR: altera ou limpa o endereco; o marcador nunca e gravado")
    void gestorEditaEndereco() {
        Denuncia d = caso();
        EdicaoDoCaso.Edicao e = EdicaoDoCaso.aplicar(d, pedido("violencia", RELATO, "Av. Brasil, 9"), true);
        assertEquals("Av. Brasil, 9", d.getEndereco());
        assertEquals(List.of("endereco"), e.alterados());

        EdicaoDoCaso.aplicar(d, pedido("violencia", RELATO, MascaraUtil.ENDERECO_PROTEGIDO), true);
        assertEquals("Av. Brasil, 9", d.getEndereco());

        EdicaoDoCaso.aplicar(d, pedido("violencia", RELATO, ""), true);
        assertEquals("", d.getEndereco());
    }

    @Test
    @DisplayName("anonimato declarado e preservado; estado normalizado e local remontado")
    void anonimatoEstadoLocal() {
        Denuncia d = caso();
        DenunciaRequest r = pedido("violencia", RELATO, "Rua das Flores, 123");
        r.setAnonimo(false);
        r.setCidade("Barueri");
        EdicaoDoCaso.Edicao e = EdicaoDoCaso.aplicar(d, r, true);

        assertTrue(d.isAnonimo());
        assertEquals("SP", d.getEstado());
        assertEquals("Barueri, SP", d.getLocal());
        assertEquals(List.of("cidade"), e.alterados());
        assertEquals(List.of("anonimo"), e.ignorados());
        assertEquals("Campos alterados: cidade; ignorados (registro original do denunciante preservado): anonimo",
                e.resumo());
    }

    @Test
    @DisplayName("sem mudanca, o resumo diz que nada foi alterado")
    void semMudanca() {
        Denuncia d = caso();
        EdicaoDoCaso.Edicao e = EdicaoDoCaso.aplicar(d, pedido("violencia", RELATO, "Rua das Flores, 123"), true);
        assertEquals("Nenhum campo alterado", e.resumo());
    }
}
