package br.gov.protege.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Fase 7 | Correlacao e regressao para apoiar decisao (Parte 3).
 *
 * Como o relatorio descritivo, e integralmente agregado: nenhum campo leva
 * a um caso individual. Valores que nao podem ser calculados (amostra
 * pequena, variavel constante) vem como null, e nao como zero, para a tela
 * nunca apresentar "correlacao zero" onde na verdade nao houve medida.
 */
public record AnalisePreditivaResponse(
        LocalDateTime geradoEm,
        int casosConcluidos,
        List<Variavel> variaveis,
        /** Pearson entre todas as variaveis, na ordem de {@code variaveis}. */
        List<List<Double>> matrizPearson,
        /** Cada variavel explicativa contra o tempo de atendimento. */
        List<CorrelacaoComTempo> correlacoesComTempo,
        Regressao regressaoSimples,
        Regressao regressaoMultipla,
        Tendencia tendenciaSemanal,
        List<Insight> insights,
        List<String> avisos
) {
    public record Variavel(String chave, String nome, String descricao) {}

    public record CorrelacaoComTempo(String chave, String nome, int n, Double pearson, Double pValor,
                                     Double icInferior, Double icSuperior, Double spearman,
                                     boolean significativa, String leitura) {}

    public record Coeficiente(String chave, String nome, Double valor, Double erroPadrao, Double t,
                              Double pValor, Double icInferior, Double icSuperior, Double padronizado,
                              boolean significativo) {}

    public record Regressao(String descricao, String equacao, int n, Double r2, Double r2Ajustado,
                            Double erroPadraoResidual, Double f, Double pValorF,
                            List<Coeficiente> coeficientes, List<Ponto> pontos) {}

    /** Par (x, y) do grafico de dispersao, sem identificacao. */
    public record Ponto(double x, double y) {}

    public record Semana(LocalDate inicio, long denuncias, Double previsto,
                         Double previstoMin, Double previstoMax, boolean projecao) {}

    public record Tendencia(LocalDate de, LocalDate ate, int semanas, Double inclinacao,
                            Double pValor, Double r2, Double mediaSemanal, List<Semana> serie,
                            Double concluidasPorSemana, int equipe, Double capacidadePorPessoa,
                            Double demandaProjetada, Integer equipeNecessaria, String observacao) {}

    /** Conclusao em linguagem simples, com a evidencia e a decisao sugerida. */
    public record Insight(String nivel, String titulo, String texto, String evidencia, String decisao) {}
}
