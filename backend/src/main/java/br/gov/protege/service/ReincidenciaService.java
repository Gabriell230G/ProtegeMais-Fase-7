package br.gov.protege.service;

import br.gov.protege.model.Denuncia;
import br.gov.protege.repository.DenunciaRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Deque;
import java.util.List;
import java.util.Locale;
import java.util.NavigableMap;
import java.util.TreeMap;

/**
 * Focos de reincidencia (Fase 6, Parte 4).
 *
 * O PROBLEMA
 *
 * A central recebe denuncias majoritariamente anonimas. Anonimo significa
 * que nao existe nome para agrupar, e sem nome o gestor ve uma lista plana
 * onde seis relatos podem ser seis ocorrencias distintas ou seis relatos da
 * MESMA situacao em curso. A diferenca muda a resposta inteira: seis
 * ocorrencias distintas sao seis visitas; um foco unico com seis relatos em
 * tres semanas e uma operacao coordenada, e provavelmente urgente.
 *
 * POR QUE NAO UM GROUP BY
 *
 * Esta e a pergunta que a solucao precisa responder, porque a alternativa
 * obvia e agrupar por cidade e tipo no proprio SQL.
 *
 * Um GROUP BY junta TUDO que compartilha a chave, desde o primeiro registro
 * ate o ultimo. Duas denuncias do mesmo bairro separadas por oito meses
 * cairiam no mesmo balde, e o resultado seria um numero que so cresce e
 * nunca informa nada.
 *
 * Um foco nao e um balde: e uma CADEIA no tempo. A pertence ao mesmo foco
 * que B se os dois estao proximos; B pertence ao mesmo de C pela mesma
 * razao; e entao A e C sao o mesmo foco AINDA QUE estejam distantes entre
 * si, porque ha continuidade entre eles. Quando a cadeia se interrompe, o
 * foco terminou, e um relato posterior comeca outro.
 *
 * Essa relacao, "ligado diretamente ou por intermediarios", e exatamente a
 * definicao de componente conexo de um grafo. Nao existe clausula de SQL
 * que a expresse, e e por isso que o problema desce para o codigo.
 *
 * AS QUATRO ESTRUTURAS, E O QUE CADA UMA RESOLVE
 *
 *   ARVORE (TreeMap)  . indice temporal das denuncias. subMap recorta a
 *                       janela de analise em O(log n + k), em vez de
 *                       varrer as n denuncias para descartar quase todas.
 *   ORDENACAO         . dentro da janela, ordena por (grupo, data). E o
 *                       que torna a montagem do grafo linear, porque
 *                       vizinhos no tempo ficam vizinhos no vetor.
 *   BUSCA BINARIA     . localiza em O(log k) o bloco de um grupo dentro do
 *                       vetor ordenado. Serve a pergunta pontual "este
 *                       caso novo entra em algum foco existente?", que a
 *                       tela faz a cada denuncia aberta.
 *   GRAFO + BFS       . componentes conexos. E a unica das quatro que
 *                       responde a pergunta central.
 */
@Service
public class ReincidenciaService {

    /**
     * Distancia maxima, em dias, entre duas denuncias ligadas diretamente.
     *
     * Quatorze dias e uma escolha, e uma escolha discutivel: encurtar
     * fragmenta focos reais em pedacos; alargar cola situacoes que nada tem
     * a ver. O numero esta aqui, isolado e nomeado, justamente para poder
     * ser calibrado quando houver operacao real para medir.
     */
    public static final int JANELA_ELO_DIAS = 14;

    /**
     * Tamanho minimo para um agrupamento ser chamado de foco.
     *
     * Duas denuncias ligadas sao uma coincidencia plausivel. A partir de
     * tres, a coincidencia fica cara de sustentar. O limite existe para a
     * tela nao encher de pares e afogar o que importa.
     */
    public static final int MINIMO_PARA_FOCO = 3;

    /**
     * Fracao do grupo a partir da qual o agrupamento deixa de ser um foco.
     *
     * Um foco e algo que SE DESTACA do volume normal. Quando um unico
     * componente reune quase tudo o que aquele municipio e aquele tipo
     * produziram na janela, ele nao destaca coisa alguma: ele E o volume
     * normal daquele lugar. Chamar isso de foco levaria a equipe a montar
     * uma operacao contra a operacao inteira do municipio.
     *
     * A tela passa a separar as duas coisas e a nomea-las: FOCO, um surto
     * que comeca e termina dentro da janela, e FLUXO CONTINUO, uma cadeia
     * que nunca se interrompe porque a demanda dali e constante. As duas
     * informacoes sao uteis, e as duas acoes sao diferentes: a primeira
     * pede operacao pontual, a segunda pede equipe permanente.
     */
    public static final double COBERTURA_DE_SATURACAO = 0.70;

    /**
     * Abaixo deste tamanho nao se fala em saturacao.
     *
     * Um grupo com 4 denuncias no periodo tem, quase por definicao, um
     * componente cobrindo boa parte dele. Aplicar o corte ali marcaria
     * como "fluxo continuo" aquilo que e apenas um grupo pequeno.
     */
    public static final int MINIMO_PARA_SATURACAO = 10;

    private final DenunciaRepository denuncias;

    public ReincidenciaService(DenunciaRepository denuncias) {
        this.denuncias = denuncias;
    }

    // ==================================================================
    //  No do grafo
    // ==================================================================

    /** Uma denuncia reduzida ao que a analise precisa. */
    public record No(String protocolo, String chave, LocalDateTime data,
                     String cidade, String tipo, int score) {}

    /**
     * Chave de compatibilidade entre duas denuncias.
     *
     * Duas denuncias so podem pertencer ao mesmo foco se falam do mesmo
     * tipo de violacao no mesmo municipio. Sem esse corte, a cadeia
     * temporal ligaria um assedio em Santos a uma discriminacao em Manaus
     * por mera proximidade de data.
     */
    public static String chaveDoGrupo(String cidade, String tipo) {
        String c = cidade == null ? "?" : cidade.trim().toLowerCase(Locale.ROOT);
        String t = tipo   == null ? "?" : tipo.trim().toLowerCase(Locale.ROOT);
        return c + "|" + t;
    }

    // ==================================================================
    //  1. ARVORE: indice temporal
    // ==================================================================

    /**
     * Indexa as denuncias por instante de criacao numa arvore balanceada.
     *
     * A lista chega ordenada do banco, mas uma lista ordenada nao responde
     * "o que aconteceu entre estas duas datas" sem percorrer. O TreeMap
     * responde: e uma arvore rubro-negra, com insercao e busca em O(log n).
     *
     * O valor e uma lista porque duas denuncias podem ter o mesmo instante,
     * e perder uma delas por colisao de chave seria perder um caso.
     */
    public static TreeMap<LocalDateTime, List<No>> indexarPorData(List<Denuncia> lista) {
        TreeMap<LocalDateTime, List<No>> arvore = new TreeMap<>();
        for (Denuncia d : lista) {
            if (d == null || d.getCriadoEm() == null) continue;
            No no = new No(d.getProtocolo(),
                           chaveDoGrupo(d.getCidade(), d.getTipo()),
                           d.getCriadoEm(),
                           d.getCidade(), d.getTipo(),
                           d.getScore());
            arvore.computeIfAbsent(d.getCriadoEm(), k -> new ArrayList<>()).add(no);
        }
        return arvore;
    }

    /**
     * Recorta a janela de analise.
     *
     * subMap devolve uma VISAO da arvore, sem copiar o que ficou de fora.
     * Em O(log n) a arvore localiza a borda da janela e a partir dali
     * percorre apenas os k elementos que interessam. A alternativa, filtrar
     * a lista inteira, custaria O(n) toda vez que alguem mudasse o periodo
     * na tela, e o periodo muda o tempo todo.
     */
    public static List<No> recortarJanela(TreeMap<LocalDateTime, List<No>> arvore,
                                          LocalDateTime inicio, LocalDateTime fim) {
        NavigableMap<LocalDateTime, List<No>> faixa = arvore.subMap(inicio, true, fim, true);
        List<No> recorte = new ArrayList<>();
        for (List<No> nos : faixa.values()) recorte.addAll(nos);
        return recorte;
    }

    // ==================================================================
    //  2. ORDENACAO E BUSCA BINARIA
    // ==================================================================

    /**
     * Ordena por (grupo, data).
     *
     * Esta ordenacao nao e cosmetica: e ela que transforma a montagem do
     * grafo de quadratica em linear. Depois de ordenar, todas as denuncias
     * de um mesmo grupo ficam contiguas e em ordem cronologica, e basta
     * comparar cada uma com a SEGUINTE.
     */
    public static void ordenar(List<No> nos) {
        nos.sort(Comparator.comparing(No::chave).thenComparing(No::data));
    }

    /**
     * Primeira posicao do grupo no vetor ordenado, ou -1 se nao houver.
     *
     * Busca binaria classica, com uma diferenca: ao encontrar a chave ela
     * NAO para. Continua para a esquerda procurando se ha outra igual
     * antes, porque a pergunta e "onde o bloco COMECA" e nao "onde ha uma
     * ocorrencia". Parar no primeiro acerto devolveria um ponto qualquer do
     * meio do bloco, e o chamador perderia os anteriores sem perceber.
     */
    public static int primeiroDoGrupo(List<No> ordenados, String chave) {
        int lo = 0, hi = ordenados.size() - 1, achado = -1;
        while (lo <= hi) {
            int meio = (lo + hi) >>> 1;          // >>> evita estouro em vetor grande
            int cmp = ordenados.get(meio).chave().compareTo(chave);
            if (cmp == 0)      { achado = meio; hi = meio - 1; }
            else if (cmp < 0)  { lo = meio + 1; }
            else               { hi = meio - 1; }
        }
        return achado;
    }

    // ==================================================================
    //  3. GRAFO E COMPONENTES CONEXOS
    // ==================================================================

    /**
     * Monta a lista de adjacencia do grafo.
     *
     * A ligacao so existe entre denuncias CONSECUTIVAS do mesmo grupo, e
     * isso e o ponto fino do algoritmo. A tentacao e ligar todos os pares
     * proximos, o que custaria O(k2) arestas e, num grupo de 200 relatos,
     * significaria quase vinte mil comparacoes para descrever um unico
     * foco.
     *
     * Ligar apenas consecutivas basta: se A liga em B e B liga em C, os
     * tres caem no mesmo componente, mesmo sem aresta entre A e C. A
     * conectividade se encarrega da transitividade, que e precisamente a
     * propriedade que define "foco" aqui. O grafo fica com no maximo k-1
     * arestas.
     */
    public static List<List<Integer>> montarGrafo(List<No> ordenados, int janelaDias) {
        int n = ordenados.size();
        List<List<Integer>> adj = new ArrayList<>(n);
        for (int i = 0; i < n; i++) adj.add(new ArrayList<>());

        for (int i = 0; i + 1 < n; i++) {
            No a = ordenados.get(i), b = ordenados.get(i + 1);
            if (!a.chave().equals(b.chave())) continue;           // grupo diferente
            long dias = ChronoUnit.DAYS.between(a.data(), b.data());
            if (dias <= janelaDias) {
                adj.get(i).add(i + 1);
                adj.get(i + 1).add(i);                            // grafo nao dirigido
            }
        }
        return adj;
    }

    /**
     * Componentes conexos por busca em largura.
     *
     * Largura e nao profundidade por um motivo pratico: um foco longo e uma
     * corrente de centenas de nos, e a recursao da busca em profundidade
     * cresce junto com ela. Uma cadeia de dez mil relatos estouraria a
     * pilha. A busca em largura usa uma fila no heap e nao tem esse teto.
     *
     * Custo O(V + E). Como E e no maximo V-1 pela construcao acima, o
     * percurso e linear no numero de denuncias da janela.
     */
    public static List<List<Integer>> componentesConexos(List<List<Integer>> adj) {
        int n = adj.size();
        boolean[] visto = new boolean[n];
        List<List<Integer>> componentes = new ArrayList<>();

        for (int i = 0; i < n; i++) {
            if (visto[i]) continue;
            List<Integer> componente = new ArrayList<>();
            Deque<Integer> fila = new ArrayDeque<>();
            fila.add(i);
            visto[i] = true;
            while (!fila.isEmpty()) {
                int atual = fila.poll();
                componente.add(atual);
                for (int viz : adj.get(atual)) {
                    if (!visto[viz]) { visto[viz] = true; fila.add(viz); }
                }
            }
            componentes.add(componente);
        }
        return componentes;
    }

    // ==================================================================
    //  Resultado
    // ==================================================================

    public record Foco(String cidade, String tipo, int quantidade,
                       LocalDateTime primeiro, LocalDateTime ultimo,
                       long duracaoDias, int scoreMedio, int scoreMaximo,
                       int totalNoGrupo, double cobertura, boolean continuo,
                       List<String> protocolos) {}

    /**
     * O agrupamento se destaca do volume do proprio grupo, ou e o volume?
     *
     * Metodo puro, separado do resto, porque esta e a regra que decide o
     * nome que a tela vai dar ao achado, e uma regra que batiza precisa
     * poder ser testada sozinha.
     */
    public static boolean ehFluxoContinuo(int tamanhoDoComponente, int totalNoGrupo) {
        if (totalNoGrupo < MINIMO_PARA_SATURACAO) return false;
        return (double) tamanhoDoComponente / totalNoGrupo >= COBERTURA_DE_SATURACAO;
    }

    /**
     * Executa a analise completa sobre a janela pedida.
     *
     * A ordem das etapas e a ordem das estruturas: arvore recorta, sort
     * organiza, grafo liga, BFS agrupa.
     */
    public List<Foco> focos(int dias) {
        int periodo = Math.max(1, Math.min(dias, 3650));
        List<Denuncia> base = denuncias.findByExcluidaFalseOrderByCriadoEmDesc();
        if (base.isEmpty()) return List.of();

        TreeMap<LocalDateTime, List<No>> arvore = indexarPorData(base);
        if (arvore.isEmpty()) return List.of();

        // A janela termina na denuncia mais recente da base, e nao em
        // LocalDateTime.now(). Numa base de demonstracao com datas fixas,
        // ancorar no relogio devolveria lista vazia e pareceria defeito.
        LocalDateTime fim = arvore.lastKey();
        LocalDateTime inicio = fim.minusDays(periodo);

        List<No> janela = recortarJanela(arvore, inicio, fim);
        ordenar(janela);

        List<List<Integer>> adj = montarGrafo(janela, JANELA_ELO_DIAS);
        List<List<Integer>> componentes = componentesConexos(adj);

        // Quanto cada grupo produziu na janela inteira. E o denominador que
        // diz se um componente se destaca ou se ele e o proprio volume.
        java.util.Map<String, Integer> totalPorGrupo = new java.util.HashMap<>();
        for (No no : janela) totalPorGrupo.merge(no.chave(), 1, Integer::sum);

        List<Foco> achados = new ArrayList<>();
        for (List<Integer> comp : componentes) {
            if (comp.size() < MINIMO_PARA_FOCO) continue;
            comp.sort(Comparator.comparing(i -> janela.get(i).data()));

            No primeiro = janela.get(comp.get(0));
            No ultimo   = janela.get(comp.get(comp.size() - 1));
            int soma = 0, maximo = 0;
            List<String> protocolos = new ArrayList<>();
            for (int i : comp) {
                No no = janela.get(i);
                soma += no.score();
                maximo = Math.max(maximo, no.score());
                protocolos.add(no.protocolo());
            }
            int totalGrupo = totalPorGrupo.getOrDefault(primeiro.chave(), comp.size());
            double cobertura = (double) comp.size() / Math.max(1, totalGrupo);

            achados.add(new Foco(primeiro.cidade(), primeiro.tipo(), comp.size(),
                                 primeiro.data(), ultimo.data(),
                                 ChronoUnit.DAYS.between(primeiro.data(), ultimo.data()),
                                 soma / comp.size(), maximo,
                                 totalGrupo, Math.round(cobertura * 1000) / 1000.0,
                                 ehFluxoContinuo(comp.size(), totalGrupo),
                                 protocolos));
        }

        // Focos verdadeiros primeiro, fluxo continuo depois. Nao e uma
        // questao de importancia: e que os dois pedem acoes diferentes, e
        // quem abre a tela esta procurando o que da para atacar hoje. O
        // fluxo continuo nao some da lista, so para de disputar o topo com
        // aquilo que cabe numa operacao.
        achados.sort(Comparator.comparing(Foco::continuo)
                     .thenComparing(Comparator.comparingInt(Foco::quantidade).reversed())
                     .thenComparing(Comparator.comparingInt(Foco::scoreMaximo).reversed()));
        return achados;
    }

    /**
     * A qual foco um protocolo pertence, se pertencer a algum.
     *
     * E aqui que a busca binaria ganha o lugar dela: a tela de detalhe faz
     * esta pergunta para UMA denuncia, e percorrer a janela inteira para
     * responder seria O(k) por consulta aberta.
     */
    public Foco focoDe(String protocolo, int dias) {
        for (Foco f : focos(dias)) {
            if (f.protocolos().contains(protocolo)) return f;
        }
        return null;
    }
}
