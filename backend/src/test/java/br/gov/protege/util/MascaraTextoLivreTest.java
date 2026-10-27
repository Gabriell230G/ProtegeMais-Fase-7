package br.gov.protege.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Mascaramento de dado pessoal no relato livre")
class MascaraTextoLivreTest {

    @Test
    @DisplayName("remove CPF, telefone e e-mail")
    void removeIdentificadores() {
        String r = MascaraUtil.textoLivre("CPF 123.456.789-09, fone (11) 98765-4321, maria.silva@gmail.com");
        assertFalse(r.contains("123.456.789-09"));
        assertFalse(r.contains("98765-4321"));
        assertFalse(r.contains("maria.silva"));
        assertTrue(r.contains("[cpf]") && r.contains("[telefone]") && r.contains("[email]"));
    }

    @Test
    @DisplayName("remove logradouro com numero e CEP")
    void removeEndereco() {
        String r = MascaraUtil.textoLivre("Ele mora na Rua das Flores, 123, CEP 06010-000, Osasco");
        assertFalse(r.contains("Flores"));
        assertFalse(r.contains("06010-000"));
        assertTrue(r.contains("Osasco"), "municipio nao identifica a pessoa e ajuda a triagem");
    }

    @Test
    @DisplayName("preserva o conteudo que importa para a triagem")
    void preservaContexto() {
        String original = "Aconteceu ontem as 22h, ele tinha uma faca e ameacou de morte";
        assertEquals(original, MascaraUtil.textoLivre(original));
    }

    @Test
    @DisplayName("aceita nulo e vazio sem erro")
    void nuloEVazio() {
        assertNull(MascaraUtil.textoLivre(null));
        assertEquals("", MascaraUtil.textoLivre(""));
    }
}
