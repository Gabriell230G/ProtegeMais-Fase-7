package br.gov.protege.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

/**
 * Fase 7 | Estatistica inferencial sem dependencia externa.
 *
 * Correlacao de Pearson e de Spearman com teste de significancia, regressao
 * linear por minimos quadrados (simples e multipla) com erro-padrao, teste t
 * e intervalo de confianca de cada coeficiente, e o teste F do modelo.
 *
 * As distribuicoes t de Student e F sao calculadas pela funcao beta
 * incompleta regularizada (fracao continuada de Lentz), a mesma base usada
 * pelas bibliotecas estatisticas. Os testes conferem os resultados contra
 * valores publicados (quarteto de Anscombe, tabelas da t de Student).
 *
 * Classe pura e sem estado: testavel sem banco e sem Spring.
 */
public final class Inferencia {

    private Inferencia() { }

    // ==================================================================
    //  Correlacao
    // ==================================================================

    /** Resultado de uma correlacao com o seu teste. */
    public record Correlacao(int n, double r, double r2, double pValor,
                             double icInferior, double icSuperior) {
        public boolean significativa() { return n > 2 && pValor < 0.05; }
    }

    public static Correlacao pearson(double[] x, double[] y) {
        int n = Math.min(x.length, y.length);
        if (n < 3) return new Correlacao(n, Double.NaN, Double.NaN, Double.NaN, Double.NaN, Double.NaN);
        double mx = media(x, n), my = media(y, n);
        double cov = 0, vx = 0, vy = 0;
        for (int i = 0; i < n; i++) {
            double dx = x[i] - mx, dy = y[i] - my;
            cov += dx * dy; vx += dx * dx; vy += dy * dy;
        }
        if (vx == 0 || vy == 0) {
            return new Correlacao(n, Double.NaN, Double.NaN, Double.NaN, Double.NaN, Double.NaN);
        }
        double r = Math.max(-1, Math.min(1, cov / Math.sqrt(vx * vy)));
        return new Correlacao(n, r, r * r, pValorCorrelacao(r, n),
                icFisher(r, n, -1), icFisher(r, n, +1));
    }

    /**
     * Spearman: Pearson aplicado aos postos. Capta relacao monotona que nao
     * e reta (ex.: o tempo cai rapido nos primeiros niveis de gravidade e
     * depois estabiliza). Empates recebem o posto medio.
     */
    public static Correlacao spearman(double[] x, double[] y) {
        int n = Math.min(x.length, y.length);
        return pearson(postos(Arrays.copyOf(x, n)), postos(Arrays.copyOf(y, n)));
    }

    static double[] postos(double[] v) {
        int n = v.length;
        Integer[] ordem = new Integer[n];
        for (int i = 0; i < n; i++) ordem[i] = i;
        Arrays.sort(ordem, Comparator.comparingDouble(i -> v[i]));
        double[] posto = new double[n];
        int i = 0;
        while (i < n) {
            int j = i;
            while (j + 1 < n && v[ordem[j + 1]] == v[ordem[i]]) j++;
            double medio = (i + j) / 2.0 + 1;
            for (int k = i; k <= j; k++) posto[ordem[k]] = medio;
            i = j + 1;
        }
        return posto;
    }

    /** Teste t para r = 0, com n - 2 graus de liberdade. */
    public static double pValorCorrelacao(double r, int n) {
        if (n < 3) return Double.NaN;
        if (Math.abs(r) >= 1) return 0;
        double t = r * Math.sqrt((n - 2) / (1 - r * r));
        return pValorT(t, n - 2);
    }

    /** Intervalo de 95% pela transformacao z de Fisher. */
    static double icFisher(double r, int n, int lado) {
        if (n < 4 || Math.abs(r) >= 1) return r;
        double z = 0.5 * Math.log((1 + r) / (1 - r));
        double zc = z + lado * 1.959963984540054 / Math.sqrt(n - 3);
        return Math.tanh(zc);
    }

    // ==================================================================
    //  Regressao linear (minimos quadrados ordinarios)
    // ==================================================================

    /** Um coeficiente do modelo, com o seu teste e intervalo de 95%. */
    public record Coeficiente(String nome, double valor, double erroPadrao, double t, double pValor,
                              double icInferior, double icSuperior, double padronizado) {
        public boolean significativo() { return pValor < 0.05; }
    }

    /** Modelo ajustado. {@code coeficientes.get(0)} e o intercepto. */
    public record Modelo(int n, int k, List<Coeficiente> coeficientes, double r2, double r2Ajustado,
                         double erroPadraoResidual, double f, double pValorF,
                         double mediaX, double sxx) {
        /** Previsao do modelo simples num ponto x (so para k = 2). */
        public double prever(double x) {
            return coeficientes.get(0).valor() + coeficientes.get(1).valor() * x;
        }

        /** Meia-largura do intervalo de predicao de 95% (so para k = 2). */
        public double margemPredicao(double x) {
            double tc = tCritico(n - k);
            return tc * erroPadraoResidual * Math.sqrt(1 + 1.0 / n + (x - mediaX) * (x - mediaX) / sxx);
        }
    }

    /** Regressao simples y = a + b x. */
    public static Modelo regressaoSimples(String nomeX, double[] x, double[] y) {
        double[][] colunas = { x };
        return regressao(new String[]{ nomeX }, colunas, y);
    }

    /**
     * Regressao multipla. {@code colunas[j][i]} e o valor da variavel j no
     * caso i. Devolve null se a matriz for singular (variavel constante ou
     * uma variavel que e combinacao exata das outras) ou se nao houver
     * casos suficientes para estimar o erro.
     */
    public static Modelo regressao(String[] nomes, double[][] colunas, double[] y) {
        int n = y.length;
        int k = colunas.length + 1;
        if (n <= k) return null;

        double[][] xtx = new double[k][k];
        double[] xty = new double[k];
        for (int i = 0; i < n; i++) {
            double[] linha = linha(colunas, i);
            for (int a = 0; a < k; a++) {
                xty[a] += linha[a] * y[i];
                for (int b = 0; b < k; b++) xtx[a][b] += linha[a] * linha[b];
            }
        }
        double[][] inv = inverter(xtx);
        if (inv == null) return null;

        double[] beta = new double[k];
        for (int a = 0; a < k; a++) for (int b = 0; b < k; b++) beta[a] += inv[a][b] * xty[b];

        double my = media(y, n);
        double sse = 0, sst = 0;
        for (int i = 0; i < n; i++) {
            double[] linha = linha(colunas, i);
            double previsto = 0;
            for (int a = 0; a < k; a++) previsto += beta[a] * linha[a];
            sse += (y[i] - previsto) * (y[i] - previsto);
            sst += (y[i] - my) * (y[i] - my);
        }
        int gl = n - k;
        double sigma2 = sse / gl;
        double r2 = sst == 0 ? 0 : 1 - sse / sst;
        double r2aj = 1 - (1 - r2) * (n - 1) / gl;
        double tc = tCritico(gl);
        double dpY = Math.sqrt(sst / (n - 1));

        List<Coeficiente> coefs = new ArrayList<>();
        for (int a = 0; a < k; a++) {
            double ep = Math.sqrt(Math.max(0, sigma2 * inv[a][a]));
            double t = ep == 0 ? (beta[a] == 0 ? 0 : Double.POSITIVE_INFINITY) : beta[a] / ep;
            double p = ep == 0 ? 0 : pValorT(t, gl);
            double padronizado = 0;
            if (a > 0 && dpY > 0) padronizado = beta[a] * desvio(colunas[a - 1]) / dpY;
            coefs.add(new Coeficiente(a == 0 ? "intercepto" : nomes[a - 1], beta[a], ep, t, p,
                    beta[a] - tc * ep, beta[a] + tc * ep, padronizado));
        }

        double f = Double.NaN, pf = Double.NaN;
        if (k > 1 && sse > 0) {
            f = ((sst - sse) / (k - 1)) / sigma2;
            pf = pValorF(f, k - 1, gl);
        } else if (k > 1) {
            f = Double.POSITIVE_INFINITY; pf = 0;
        }
        double mediaX = colunas.length == 1 ? media(colunas[0], n) : Double.NaN;
        double sxx = 0;
        if (colunas.length == 1) for (double v : colunas[0]) sxx += (v - mediaX) * (v - mediaX);
        return new Modelo(n, k, coefs, r2, r2aj, Math.sqrt(sigma2), f, pf, mediaX, sxx);
    }

    private static double[] linha(double[][] colunas, int i) {
        double[] l = new double[colunas.length + 1];
        l[0] = 1;
        for (int j = 0; j < colunas.length; j++) l[j + 1] = colunas[j][i];
        return l;
    }

    /** Gauss-Jordan com pivoteamento parcial. Null se singular. */
    static double[][] inverter(double[][] m) {
        int k = m.length;
        double[][] a = new double[k][2 * k];
        for (int i = 0; i < k; i++) {
            System.arraycopy(m[i], 0, a[i], 0, k);
            a[i][k + i] = 1;
        }
        double escala = 0;
        for (double[] l : m) for (double v : l) escala = Math.max(escala, Math.abs(v));
        double tolerancia = 1e-12 * Math.max(1, escala);
        for (int c = 0; c < k; c++) {
            int piv = c;
            for (int r = c + 1; r < k; r++) if (Math.abs(a[r][c]) > Math.abs(a[piv][c])) piv = r;
            if (Math.abs(a[piv][c]) < tolerancia) return null;
            double[] tmp = a[c]; a[c] = a[piv]; a[piv] = tmp;
            double d = a[c][c];
            for (int j = 0; j < 2 * k; j++) a[c][j] /= d;
            for (int r = 0; r < k; r++) {
                if (r == c) continue;
                double fator = a[r][c];
                if (fator == 0) continue;
                for (int j = 0; j < 2 * k; j++) a[r][j] -= fator * a[c][j];
            }
        }
        double[][] inv = new double[k][k];
        for (int i = 0; i < k; i++) System.arraycopy(a[i], k, inv[i], 0, k);
        return inv;
    }

    // ==================================================================
    //  Distribuicoes
    // ==================================================================

    /** p-valor bilateral da t de Student com gl graus de liberdade. */
    public static double pValorT(double t, double gl) {
        if (Double.isNaN(t) || gl <= 0) return Double.NaN;
        if (Double.isInfinite(t)) return 0;
        return betaIncompletaRegularizada(gl / (gl + t * t), gl / 2.0, 0.5);
    }

    /** p-valor (cauda superior) da F com d1 e d2 graus de liberdade. */
    public static double pValorF(double f, double d1, double d2) {
        if (Double.isNaN(f) || f < 0 || d1 <= 0 || d2 <= 0) return Double.NaN;
        if (Double.isInfinite(f)) return 0;
        return betaIncompletaRegularizada(d2 / (d2 + d1 * f), d2 / 2.0, d1 / 2.0);
    }

    /** Valor critico bilateral de 95% da t (ex.: 2,228 para gl = 10). */
    public static double tCritico(double gl) {
        if (gl <= 0) return Double.NaN;
        double lo = 0, hi = 1000;
        for (int i = 0; i < 200; i++) {
            double meio = (lo + hi) / 2;
            if (pValorT(meio, gl) > 0.05) lo = meio; else hi = meio;
        }
        return (lo + hi) / 2;
    }

    /** I_x(a, b), funcao beta incompleta regularizada. */
    static double betaIncompletaRegularizada(double x, double a, double b) {
        if (x <= 0) return 0;
        if (x >= 1) return 1;
        double ln = lnGama(a + b) - lnGama(a) - lnGama(b) + a * Math.log(x) + b * Math.log(1 - x);
        double frente = Math.exp(ln);
        if (x < (a + 1) / (a + b + 2)) return frente * fracaoContinua(x, a, b) / a;
        return 1 - frente * fracaoContinua(1 - x, b, a) / b;
    }

    private static double fracaoContinua(double x, double a, double b) {
        final double minimo = 1e-300;
        double qab = a + b, qap = a + 1, qam = a - 1;
        double c = 1, d = 1 - qab * x / qap;
        if (Math.abs(d) < minimo) d = minimo;
        d = 1 / d;
        double h = d;
        for (int m = 1; m <= 300; m++) {
            int m2 = 2 * m;
            double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
            d = 1 + aa * d; if (Math.abs(d) < minimo) d = minimo;
            c = 1 + aa / c; if (Math.abs(c) < minimo) c = minimo;
            d = 1 / d; h *= d * c;
            aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
            d = 1 + aa * d; if (Math.abs(d) < minimo) d = minimo;
            c = 1 + aa / c; if (Math.abs(c) < minimo) c = minimo;
            d = 1 / d;
            double delta = d * c;
            h *= delta;
            if (Math.abs(delta - 1) < 1e-14) break;
        }
        return h;
    }

    /** Logaritmo da funcao gama (aproximacao de Lanczos, g = 7). */
    static double lnGama(double z) {
        double[] c = {0.99999999999980993, 676.5203681218851, -1259.1392167224028,
                771.32342877765313, -176.61502916214059, 12.507343278686905,
                -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7};
        if (z < 0.5) return Math.log(Math.PI / Math.abs(Math.sin(Math.PI * z))) - lnGama(1 - z);
        z -= 1;
        double x = c[0];
        for (int i = 1; i < 9; i++) x += c[i] / (z + i);
        double t = z + 7.5;
        return 0.5 * Math.log(2 * Math.PI) + (z + 0.5) * Math.log(t) - t + Math.log(x);
    }

    // ==================================================================
    //  Apoio
    // ==================================================================

    static double media(double[] v, int n) {
        double s = 0;
        for (int i = 0; i < n; i++) s += v[i];
        return n == 0 ? Double.NaN : s / n;
    }

    static double desvio(double[] v) {
        int n = v.length;
        if (n < 2) return 0;
        double m = media(v, n), s = 0;
        for (double x : v) s += (x - m) * (x - m);
        return Math.sqrt(s / (n - 1));
    }

    /** Arredonda para exibicao, preservando NaN e infinito. */
    public static double casas(double v, int casas) {
        if (Double.isNaN(v) || Double.isInfinite(v)) return v;
        double f = Math.pow(10, casas);
        return Math.round(v * f) / f;
    }
}
