package br.gov.protege.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Valores do cliente no log sem quebra de linha")
class LogSeguroTest {

    @Test
    @DisplayName("CR, LF e outros controles viram '_'; o resto fica como veio")
    void neutralizaQuebras() {
        assertEquals("Mozilla_[INFO] login admin ok", LogSeguro.limpar("Mozilla\n[INFO] login admin ok"));
        assertEquals("a__b_c", LogSeguro.limpar("a\r\nb\tc"));
        assertEquals("texto comum, sem controle", LogSeguro.limpar("texto comum, sem controle"));
        assertNull(LogSeguro.limpar(null));
    }
}
