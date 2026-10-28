package br.gov.protege.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Fase 7 | Confere a estatistica inferencial contra valores publicados.
 * Quarteto de Anscombe (conjunto I): r = 0,816; y = 3,00 + 0,500 x;
 * R² = 0,667; p da inclinacao = 0,00217.
 */
@DisplayName("Fase 7 | Inferencia: correlacao, regressao e distribuicoes")
class InferenciaTest {

    private static final double[] X = {10, 8, 13, 9, 11, 14, 6, 4, 12, 7, 5};
    private static final double[] Y = {8.04, 6.95, 7.58, 8.81, 8.33, 9.96, 7.24, 4.26, 10.84, 4.82, 5.68};

    @Test
    @DisplayName("Pearson e p-valor do quarteto de Anscombe")
    void pearsonAnscombe() {
        Inferencia.Correlacao c = Inferencia.pearson(X, Y);
        assertEquals(0.8164, c.r(), 1e-4);
        assertEquals(0.00217, c.pValor(), 1e-5);
        assertTrue(c.icInferior() < c.r() && c.r() < c.icSuperior());
        assertTrue(c.significativa());
    }

    @Test
    @DisplayName("regressao simples do quarteto de Anscombe")
    void regressaoAnscombe() {
        Inferencia.Modelo m = Inferencia.regressaoSimples("x", X, Y);
        assertEquals(3.0001, m.coeficientes().get(0).valor(), 1e-3);
        assertEquals(0.5001, m.coeficientes().get(1).valor(), 1e-3);
        assertEquals(0.6665, m.r2(), 1e-3);
        assertEquals(0.00217, m.coeficientes().get(1).pValor(), 1e-5);
        assertEquals(17.99, m.f(), 1e-2);
    }

    @Test
    @DisplayName("distribuicoes t e F batem com as tabelas")
    void distribuicoes() {
        assertEquals(2.2281, Inferencia.tCritico(10), 1e-3);
        assertEquals(1.9799, Inferencia.tCritico(120), 1e-3);
        assertEquals(0.0734, Inferencia.pValorT(2.0, 10), 1e-4);
        assertEquals(0.0346, Inferencia.pValorF(4.0, 2, 20), 1e-4);
    }

    @Test
    @DisplayName("regressao multipla recupera coeficientes exatos")
    void multiplaExata() {
        double[] x1 = {1, 2, 3, 4, 5, 6, 7, 8};
        double[] x2 = {2, 1, 4, 3, 6, 5, 8, 9};
        double[] y = new double[8];
        for (int i = 0; i < 8; i++) y[i] = 1 + 2 * x1[i] - 3 * x2[i];
        Inferencia.Modelo m = Inferencia.regressao(new String[]{"x1", "x2"}, new double[][]{x1, x2}, y);
        assertNotNull(m);
        assertEquals(1, m.coeficientes().get(0).valor(), 1e-9);
        assertEquals(2, m.coeficientes().get(1).valor(), 1e-9);
        assertEquals(-3, m.coeficientes().get(2).valor(), 1e-9);
        assertEquals(1, m.r2(), 1e-12);
    }

    @Test
    @DisplayName("variavel repetida deixa a matriz singular e o modelo nao e estimado")
    void singular() {
        double[] a = {1, 2, 3, 4, 5};
        assertNull(Inferencia.regressao(new String[]{"a", "b"}, new double[][]{a, a}, new double[]{2, 4, 6, 8, 11}));
    }

    @Test
    @DisplayName("Spearman usa posto medio nos empates")
    void spearmanEmpates() {
        assertArrayEquals(new double[]{1, 2.5, 2.5, 4}, Inferencia.postos(new double[]{3, 7, 7, 9}));
        assertEquals(1.0, Inferencia.spearman(new double[]{1, 2, 2, 3, 4}, new double[]{2, 4, 4, 5, 9}).r(), 1e-12);
    }

    @Test
    @DisplayName("serie constante nao gera correlacao falsa")
    void serieConstante() {
        Inferencia.Correlacao c = Inferencia.pearson(new double[]{1, 1, 1, 1}, new double[]{1, 2, 3, 4});
        assertTrue(Double.isNaN(c.r()));
        assertFalse(c.significativa());
    }
}
