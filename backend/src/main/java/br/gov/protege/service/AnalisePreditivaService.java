package br.gov.protege.service;

import br.gov.protege.dto.AnalisePreditivaResponse;
import br.gov.protege.dto.AnalisePreditivaResponse.CorrelacaoComTempo;
import br.gov.protege.dto.AnalisePreditivaResponse.Insight;
import br.gov.protege.dto.AnalisePreditivaResponse.Ponto;
import br.gov.protege.dto.AnalisePreditivaResponse.Regressao;
import br.gov.protege.dto.AnalisePreditivaResponse.Semana;
import br.gov.protege.dto.AnalisePreditivaResponse.Tendencia;
import br.gov.protege.dto.AnalisePreditivaResponse.Variavel;
import br.gov.protege.model.Denuncia;
import br.gov.protege.repository.DenunciaRepository;
import br.gov.protege.repository.MembroRepository;
import br.gov.protege.util.Inferencia;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import java.util.function.ToDoubleFunction;

/**
 * Fase 7 | Parte 3 | Correlacao e regressao sobre os dados do canal.
 *
 * Tres perguntas de gestao, cada uma respondida com um metodo:
 *
 *  1. O que explica o tempo ate a conclusao de um caso? Correlacao de
 *     Pearson e de Spearman de cada variavel com o tempo, com p-valor e
 *     intervalo de 95%. Responde se a triagem atual faz diferenca.
 *  2. Quanto cada fator pesa, controlando os outros? Regressao linear
 *     multipla com teste t por coeficiente e teste F do modelo.
 *  3. Quanta gente a equipe precisa nas proximas semanas? Regressao do
 *     volume semanal no tempo, com intervalo de predicao, cruzada com a
 *     capacidade observada por pessoa.
 *
 * As conclusoes em texto (insights) so afirmam relacao quando o teste da
 * significancia (p < 0,05). Sem isso, o texto diz que nao ha evidencia, em
 * vez de transformar ruido em recomendacao.
 */
@Service
public class AnalisePreditivaService {

    /** Mesmo peso de gravidade usado pelo VigIA na triagem por regras. */
    static final Map<String, Double> GRAVIDADE = Map.of(
            "violencia", 5.0, "abuso", 5.0, "assedio", 3.0, "discriminacao", 3.0, "outros", 2.0);
    static final Map<String, Double> URGENCIA = Map.of(
            "CRITICA", 4.0, "ALTA", 3.0, "MEDIA", 2.0, "BAIXA", 1.0);

    private static final Locale BR = Locale.forLanguageTag("pt-BR");
    private static final int SEMANAS_PROJECAO = 4;
    /** Semanas seguidas sem registro que separam dois periodos de operacao. */
    private static final int LACUNA = 4;

    private final DenunciaRepository repo;
    private final MembroRepository membros;

    public AnalisePreditivaService(DenunciaRepository repo, MembroRepository membros) {
        this.repo = repo;
        this.membros = membros;
    }

    /** Variavel explicativa: chave, nome, descricao e como extrair do caso. */
    private record Def(String chave, String nome, String descricao, ToDoubleFunction<Denuncia> valor) {}

    private static final List<Def> EXPLICATIVAS = List.of(
            new Def("gravidade", "Gravidade do tipo",
                    "Peso do tipo de denúncia: violência e abuso 5, assédio e discriminação 3, outros 2",
                    d -> GRAVIDADE.getOrDefault(String.valueOf(d.getTipo()).toLowerCase(), 2.0)),
            new Def("urgencia", "Urgência da triagem",
                    "Urgência atribuída pelo VigIA: crítica 4, alta 3, média 2, baixa 1",
                    d -> URGENCIA.getOrDefault(String.valueOf(d.getUrgenciaIa()).toUpperCase(), Double.NaN)),
            new Def("score", "Score de confiabilidade",
                    "Pontuação de 0 a 100 calculada no registro (completude do relato)",
                    d -> d.getScore()),
            new Def("anonimo", "Denúncia anônima",
                    "1 se anônima, 0 se identificada",
                    d -> d.isAnonimo() ? 1 : 0),
            new Def("tamanhoRelato", "Tamanho do relato",
                    "Número de caracteres do relato",
                    d -> d.getDescricao() == null ? 0 : d.getDescricao().length()));

    public AnalisePreditivaResponse gerar() {
        List<Denuncia> todas = repo.findByExcluidaFalseOrderByCriadoEmDesc();

        // Casos concluidos com todas as variaveis disponiveis.
        List<Denuncia> base = todas.stream()
                .filter(d -> d.getCriadoEm() != null && d.getConcluidaEm() != null)
                .filter(d -> !d.getConcluidaEm().isBefore(d.getCriadoEm()))
                .filter(d -> EXPLICATIVAS.stream().noneMatch(v -> Double.isNaN(v.valor().applyAsDouble(d))))
                .toList();
        int n = base.size();

        double[] tempo = base.stream().mapToDouble(AnalisePreditivaService::dias).toArray();
        double[][] xs = new double[EXPLICATIVAS.size()][];
        for (int j = 0; j < EXPLICATIVAS.size(); j++) {
            ToDoubleFunction<Denuncia> f = EXPLICATIVAS.get(j).valor();
            xs[j] = base.stream().mapToDouble(f).toArray();
        }

        List<Variavel> variaveis = new ArrayList<>();
        variaveis.add(new Variavel("tempo", "Tempo até a conclusão", "Dias entre o registro e a conclusão do caso"));
        EXPLICATIVAS.forEach(v -> variaveis.add(new Variavel(v.chave(), v.nome(), v.descricao())));

        // Matriz de Pearson (tempo + explicativas)
        List<double[]> todasSeries = new ArrayList<>();
        todasSeries.add(tempo);
        for (double[] x : xs) todasSeries.add(x);
        List<List<Double>> matriz = new ArrayList<>();
        for (double[] a : todasSeries) {
            List<Double> linha = new ArrayList<>();
            for (double[] b : todasSeries) {
                linha.add(a == b ? Double.valueOf(1.0) : num(Inferencia.pearson(a, b).r(), 3));
            }
            matriz.add(linha);
        }

        // Correlacao de cada explicativa com o tempo
        List<CorrelacaoComTempo> corrs = new ArrayList<>();
        for (int j = 0; j < EXPLICATIVAS.size(); j++) {
            Def v = EXPLICATIVAS.get(j);
            Inferencia.Correlacao c = Inferencia.pearson(xs[j], tempo);
            Inferencia.Correlacao s = Inferencia.spearman(xs[j], tempo);
            corrs.add(new CorrelacaoComTempo(v.chave(), v.nome(), c.n(), num(c.r(), 3), num(c.pValor(), 4),
                    num(c.icInferior(), 3), num(c.icSuperior(), 3), num(s.r(), 3),
                    c.significativa(), leitura(c)));
        }

        // Regressao simples com a variavel mais associada ao tempo
        CorrelacaoComTempo melhor = corrs.stream()
                .filter(c -> c.pearson() != null)
                .max(Comparator.comparingDouble(c -> Math.abs(c.pearson())))
                .orElse(null);
        Regressao simples = null;
        Inferencia.Modelo modeloSimples = null;
        if (melhor != null) {
            int j = indice(melhor.chave());
            modeloSimples = Inferencia.regressaoSimples(melhor.chave(), xs[j], tempo);
            if (modeloSimples != null) {
                List<Ponto> pontos = new ArrayList<>();
                for (int i = 0; i < n; i++) pontos.add(new Ponto(xs[j][i], casasD(tempo[i], 2)));
                simples = regressao("Tempo até a conclusão explicado por " + melhor.nome().toLowerCase(BR),
                        modeloSimples, pontos);
            }
        }

        // Regressao multipla com todas as explicativas
        String[] nomes = EXPLICATIVAS.stream().map(Def::chave).toArray(String[]::new);
        Inferencia.Modelo modeloMultiplo = Inferencia.regressao(nomes, xs, tempo);
        Regressao multipla = modeloMultiplo == null ? null
                : regressao("Tempo até a conclusão explicado por todas as variáveis juntas", modeloMultiplo, List.of());

        Tendencia tendencia = tendencia(todas);

        return new AnalisePreditivaResponse(LocalDateTime.now(), n, variaveis, matriz, corrs,
                simples, multipla, tendencia,
                insights(corrs, modeloSimples, melhor, modeloMultiplo, tendencia, base, tempo),
                avisos(n, modeloMultiplo));
    }

    // ------------------------------------------------------------------
    //  Tendencia semanal e dimensionamento da equipe
    // ------------------------------------------------------------------

    Tendencia tendencia(List<Denuncia> todas) {
        TreeMap<LocalDate, Long> porSemana = new TreeMap<>();
        for (Denuncia d : todas) {
            if (d.getCriadoEm() == null) continue;
            porSemana.merge(semana(d.getCriadoEm()), 1L, Long::sum);
        }
        if (porSemana.size() < 3) return null;

        // Periodos de operacao separados por 4+ semanas sem registro: usa o
        // mais recente que tenha ao menos 8 semanas, senao o mais longo. Uma
        // denuncia de teste feita meses depois da carga de demonstracao nao
        // pode virar uma serie de zeros que derruba a tendencia.
        List<List<LocalDate>> periodos = new ArrayList<>();
        List<LocalDate> atual = new ArrayList<>();
        LocalDate anterior = null;
        for (LocalDate s : porSemana.keySet()) {
            if (anterior != null && ChronoUnit.WEEKS.between(anterior, s) > LACUNA) {
                periodos.add(atual);
                atual = new ArrayList<>();
            }
            atual.add(s);
            anterior = s;
        }
        periodos.add(atual);
        List<LocalDate> escolhido = null;
        for (int i = periodos.size() - 1; i >= 0; i--) {
            List<LocalDate> p = periodos.get(i);
            if (ChronoUnit.WEEKS.between(p.get(0), p.get(p.size() - 1)) + 1 >= 8) { escolhido = p; break; }
        }
        if (escolhido == null) {
            escolhido = periodos.stream().max(Comparator.comparingInt(List::size)).orElse(atual);
        }
        LocalDate de = escolhido.get(0), ate = escolhido.get(escolhido.size() - 1);
        int semanas = (int) ChronoUnit.WEEKS.between(de, ate) + 1;
        if (semanas < 3) return null;

        double[] x = new double[semanas], y = new double[semanas];
        List<LocalDate> inicios = new ArrayList<>();
        for (int i = 0; i < semanas; i++) {
            LocalDate s = de.plusWeeks(i);
            inicios.add(s);
            x[i] = i;
            y[i] = porSemana.getOrDefault(s, 0L);
        }
        Inferencia.Modelo m = Inferencia.regressaoSimples("semana", x, y);
        if (m == null) return null;

        // Com tendencia significativa, projeta pela reta. Sem ela, o modelo
        // que os dados sustentam e o da media constante: projetar uma
        // inclinacao que o teste nao confirmou seria apresentar ruido como
        // previsao. O intervalo de predicao segue o modelo usado.
        double pInclinacao = m.coeficientes().get(1).pValor();
        boolean usaReta = !Double.isNaN(pInclinacao) && pInclinacao < 0.05;
        double mediaY = sum(y) / semanas;
        double dpY = 0;
        for (double v : y) dpY += (v - mediaY) * (v - mediaY);
        dpY = Math.sqrt(dpY / (semanas - 1));
        double margemMedia = Inferencia.tCritico(semanas - 1) * dpY * Math.sqrt(1 + 1.0 / semanas);

        List<Semana> serie = new ArrayList<>();
        for (int i = 0; i < semanas; i++) {
            double ajuste = usaReta ? m.prever(i) : mediaY;
            serie.add(new Semana(inicios.get(i), (long) y[i], num(ajuste, 2), null, null, false));
        }
        double somaProjetada = 0;
        for (int h = 1; h <= SEMANAS_PROJECAO; h++) {
            double xi = semanas - 1 + h;
            double prev = Math.max(0, usaReta ? m.prever(xi) : mediaY);
            double margem = usaReta ? m.margemPredicao(xi) : margemMedia;
            somaProjetada += prev;
            serie.add(new Semana(ate.plusWeeks(h), 0, num(prev, 2),
                    num(Math.max(0, prev - margem), 2), num(prev + margem, 2), true));
        }
        double demanda = somaProjetada / SEMANAS_PROJECAO;

        // Capacidade observada: casos concluidos por semana no mesmo periodo,
        // divididos pela equipe cadastrada.
        LocalDate fim = ate.plusWeeks(1);
        long concluidas = todas.stream()
                .filter(d -> d.getConcluidaEm() != null)
                .filter(d -> {
                    LocalDate c = d.getConcluidaEm().toLocalDate();
                    return !c.isBefore(de) && c.isBefore(fim);
                }).count();
        double concluidasSemana = (double) concluidas / semanas;
        int equipe = (int) membros.count();
        Double capacidade = equipe > 0 && concluidasSemana > 0 ? concluidasSemana / equipe : null;
        Integer necessaria = capacidade == null ? null : (int) Math.ceil(demanda / capacidade);

        String obs = (periodos.size() > 1
                ? "Analisado o período contínuo de " + de + " a " + ate + "; registros fora dele "
                  + "ficaram de fora por estarem separados por mais de " + LACUNA + " semanas sem atividade. "
                : "Série contínua de " + semanas + " semanas. ")
                + (usaReta ? "Projeção pela reta de tendência (inclinação significativa)."
                           : "Sem tendência significativa: a projeção usa a média semanal, com intervalo de predição de 95%.");

        return new Tendencia(de, ate, semanas, num(m.coeficientes().get(1).valor(), 3),
                num(m.coeficientes().get(1).pValor(), 4), num(m.r2(), 3),
                num(Inferencia.casas(sum(y) / semanas, 2), 2), serie,
                num(concluidasSemana, 2), equipe, capacidade == null ? null : num(capacidade, 2),
                num(demanda, 2), necessaria, obs);
    }

    // ------------------------------------------------------------------
    //  Conclusoes em linguagem simples
    // ------------------------------------------------------------------

    private List<Insight> insights(List<CorrelacaoComTempo> corrs, Inferencia.Modelo simples,
                                   CorrelacaoComTempo melhor, Inferencia.Modelo multiplo,
                                   Tendencia t, List<Denuncia> base, double[] tempo) {
        List<Insight> out = new ArrayList<>();
        if (base.size() < 10) {
            out.add(new Insight("atencao", "Amostra pequena demais",
                    "Há " + base.size() + " casos concluídos. Com menos de 10, qualquer correlação é instável.",
                    "n = " + base.size(), "Aguardar mais casos concluídos antes de decidir com base nesta tela."));
            return out;
        }

        // 1. O que mais explica o tempo
        if (melhor != null && melhor.significativa() && simples != null) {
            double b = simples.coeficientes().get(1).valor();
            Inferencia.Coeficiente cb = simples.coeficientes().get(1);
            out.add(new Insight("destaque", melhor.nome() + " é o que mais explica o tempo de atendimento",
                    String.format(BR, "Sozinha, explica %.0f%% da variação do tempo. Cada ponto a mais "
                            + "%s o prazo em %.2f dia(s), em média.", simples.r2() * 100,
                            b < 0 ? "encurta" : "alonga", Math.abs(b)),
                    String.format(BR, "r = %.2f; p %s; IC95%% da inclinação de %.2f a %.2f dias; n = %d",
                            melhor.pearson(), p(melhor.pValor()), cb.icInferior(), cb.icSuperior(), melhor.n()),
                    b < 0 ? "Manter a priorização por gravidade na fila e usar este fator como base de um SLA por tipo de caso."
                          : "Investigar por que este fator atrasa o atendimento e revisar o fluxo desses casos."));
        }

        // 2. O score atual serve para triagem?
        CorrelacaoComTempo score = corrs.stream().filter(c -> c.chave().equals("score")).findFirst().orElse(null);
        if (score != null && score.pearson() != null && !score.significativa()) {
            out.add(new Insight("alerta", "O score atual não prevê a velocidade do atendimento",
                    "O score de confiabilidade mede se o formulário foi bem preenchido, não o risco da "
                    + "vítima. Na prática, casos com score alto e baixo são atendidos no mesmo ritmo.",
                    String.format(BR, "r = %.2f; p %s (sem evidência de relação)", score.pearson(), p(score.pValor())),
                    "Substituir o score por um score de risco baseado no Formulário Nacional de Avaliação "
                    + "de Risco (FONAR, Lei 14.149/2021), com confirmação humana registrada na auditoria."));
        }

        // 3. Anonimato
        CorrelacaoComTempo anon = corrs.stream().filter(c -> c.chave().equals("anonimo")).findFirst().orElse(null);
        if (anon != null && anon.pearson() != null) {
            if (!anon.significativa()) {
                out.add(new Insight("positivo", "Denunciar anonimamente não atrasa o atendimento",
                        "Casos anônimos e identificados são concluídos no mesmo ritmo. O anonimato não custa "
                        + "nada para quem denuncia, o que sustenta manter o anônimo como padrão do canal.",
                        String.format(BR, "r = %.2f; p %s", anon.pearson(), p(anon.pValor())),
                        "Manter o anonimato como opção padrão e divulgá-lo como garantia do canal."));
            } else {
                out.add(new Insight("alerta", "Denúncias anônimas têm tempo de atendimento diferente",
                        "Há diferença significativa entre casos anônimos e identificados.",
                        String.format(BR, "r = %.2f; p %s", anon.pearson(), p(anon.pValor())),
                        "Verificar se a falta de contato para retorno está travando os casos anônimos."));
            }
        }

        // 4. Modelo completo
        if (multiplo != null) {
            List<String> relevantes = new ArrayList<>();
            for (int i = 1; i < multiplo.coeficientes().size(); i++) {
                Inferencia.Coeficiente c = multiplo.coeficientes().get(i);
                if (c.significativo()) relevantes.add(nome(c.nome()));
            }
            out.add(new Insight("info", "Modelo com todas as variáveis",
                    String.format(BR, "Juntas, as %d variáveis explicam %.0f%% da variação do tempo (R² ajustado). "
                            + "%s O restante depende de fatores que o sistema ainda não registra, como a carga "
                            + "de trabalho do dia e o órgão para onde o caso foi encaminhado.",
                            multiplo.k() - 1, Math.max(0, multiplo.r2Ajustado()) * 100,
                            relevantes.isEmpty() ? "Nenhuma variável isolada é significativa quando as outras são controladas."
                                    : "Continuam significativas mesmo controlando as demais: " + String.join(", ", relevantes) + "."),
                    String.format(BR, "R² = %.2f; R² ajustado = %.2f; F = %.2f; p %s; n = %d",
                            multiplo.r2(), multiplo.r2Ajustado(), multiplo.f(), p(multiplo.pValorF()), multiplo.n()),
                    "Registrar o órgão de destino e a carga da equipe em cada caso, para a próxima versão do modelo "
                    + "explicar mais da variação."));
        }

        // 5. Demanda e equipe
        if (t != null && t.demandaProjetada() != null) {
            boolean cresce = t.pValor() != null && t.pValor() < 0.05 && t.inclinacao() != null && t.inclinacao() > 0;
            boolean cai = t.pValor() != null && t.pValor() < 0.05 && t.inclinacao() != null && t.inclinacao() < 0;
            String tendenciaTxt = cresce ? String.format(BR, "cresce %.1f denúncia(s) por semana", t.inclinacao())
                    : cai ? String.format(BR, "cai %.1f denúncia(s) por semana", Math.abs(t.inclinacao()))
                    : "está estável (sem tendência significativa)";
            String equipeTxt = t.equipeNecessaria() == null ? ""
                    : String.format(BR, " Com a produtividade observada (%.1f caso(s) concluído(s) por pessoa "
                            + "por semana), isso pede %d pessoa(s) na equipe; hoje são %d.",
                            t.capacidadePorPessoa(), t.equipeNecessaria(), t.equipe());
            out.add(new Insight(t.equipeNecessaria() != null && t.equipeNecessaria() > t.equipe() ? "alerta" : "info",
                    "Projeção de demanda para as próximas " + SEMANAS_PROJECAO + " semanas",
                    String.format(BR, "O volume semanal %s. A projeção é de cerca de %.0f denúncia(s) por semana.%s",
                            tendenciaTxt, t.demandaProjetada(), equipeTxt),
                    String.format(BR, "Inclinação %.2f/semana; p %s; R² = %.2f; %d semanas analisadas",
                            t.inclinacao(), p(t.pValor()), t.r2(), t.semanas()),
                    t.equipeNecessaria() != null && t.equipeNecessaria() > t.equipe()
                            ? "Reforçar a equipe ou redistribuir casos antes que a fila cresça."
                            : "Manter a equipe atual e reavaliar a projeção a cada semana."));
        }
        return out;
    }

    private List<String> avisos(int n, Inferencia.Modelo multiplo) {
        List<String> a = new ArrayList<>();
        a.add("Os dados desta instalação são de demonstração (massa sintética gerada com semente fixa): "
              + "os números mostram o método funcionando, não a realidade de um órgão.");
        a.add("Correlação não é causalidade: uma relação significativa indica onde olhar, não prova o motivo.");
        if (n < 30) a.add("Menos de 30 casos concluídos: os intervalos de confiança ficam largos.");
        if (multiplo == null && n > 0) {
            a.add("A regressão múltipla não pode ser estimada: alguma variável e constante ou e "
                  + "combinação exata das outras nesta amostra.");
        }
        a.add("Gravidade e urgência andam juntas (a urgência das regras parte do tipo). Na regressão "
              + "múltipla, uma pode 'roubar' o efeito da outra; os coeficientes padronizados ajudam a comparar.");
        return a;
    }

    // ------------------------------------------------------------------
    //  Apoio
    // ------------------------------------------------------------------

    private Regressao regressao(String descricao, Inferencia.Modelo m, List<Ponto> pontos) {
        List<AnalisePreditivaResponse.Coeficiente> cs = new ArrayList<>();
        StringBuilder eq = new StringBuilder("tempo = ").append(fmt(m.coeficientes().get(0).valor()));
        for (Inferencia.Coeficiente c : m.coeficientes()) {
            cs.add(new AnalisePreditivaResponse.Coeficiente(c.nome(), nome(c.nome()), num(c.valor(), 4),
                    num(c.erroPadrao(), 4), num(c.t(), 3), num(c.pValor(), 4), num(c.icInferior(), 4),
                    num(c.icSuperior(), 4), c.nome().equals("intercepto") ? null : num(c.padronizado(), 3),
                    c.significativo()));
            if (!c.nome().equals("intercepto")) {
                eq.append(c.valor() < 0 ? " - " : " + ").append(fmt(Math.abs(c.valor()))).append(" x ").append(c.nome());
            }
        }
        return new Regressao(descricao, eq.toString(), m.n(), num(m.r2(), 4), num(m.r2Ajustado(), 4),
                num(m.erroPadraoResidual(), 4), num(m.f(), 3), num(m.pValorF(), 4), cs, pontos);
    }

    private static String leitura(Inferencia.Correlacao c) {
        if (Double.isNaN(c.r())) return "sem dados suficientes";
        if (!c.significativa()) return "sem evidência de relação";
        double a = Math.abs(c.r());
        String forca = a < 0.3 ? "fraca" : a < 0.5 ? "moderada" : a < 0.7 ? "forte" : "muito forte";
        return "relação " + forca + (c.r() < 0 ? ": quanto maior, mais rápido o atendimento"
                                               : ": quanto maior, mais demorado o atendimento");
    }

    private static String nome(String chave) {
        for (Def d : EXPLICATIVAS) if (d.chave().equals(chave)) return d.nome();
        return "intercepto".equals(chave) ? "Intercepto" : chave;
    }

    private static int indice(String chave) {
        for (int j = 0; j < EXPLICATIVAS.size(); j++) if (EXPLICATIVAS.get(j).chave().equals(chave)) return j;
        throw new IllegalArgumentException(chave);
    }

    static double dias(Denuncia d) {
        return Duration.between(d.getCriadoEm(), d.getConcluidaEm()).toSeconds() / 86400.0;
    }

    static LocalDate semana(LocalDateTime t) {
        return t.toLocalDate().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    private static String p(Double v) {
        if (v == null) return "indisponivel";
        return v < 0.001 ? "< 0,001" : String.format(BR, "= %.3f", v);
    }

    private static String fmt(double v) {
        return String.format(BR, "%.3f", v);
    }

    private static double sum(double[] v) {
        double s = 0;
        for (double x : v) s += x;
        return s;
    }

    private static double casasD(double v, int c) {
        return Inferencia.casas(v, c);
    }

    /** NaN e infinito viram null: a tela mostra "indisponivel", nunca um zero falso. */
    static Double num(double v, int casas) {
        if (Double.isNaN(v) || Double.isInfinite(v)) return null;
        return Inferencia.casas(v, casas);
    }
}
