package br.gov.protege.service;

import br.gov.protege.service.ReincidenciaService.No;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Testes das estruturas de dados dos focos de reincidencia.
 *
 * Cada teste cobre uma afirmacao feita no documento. Uma estrutura de dados
 * escolhida por escrito e uma promessa; estes testes sao a cobranca dela.
 */
class ReincidenciaServiceTest {

    private static final LocalDateTime T0 = LocalDateTime.of(2026, 4, 1, 9, 0);

    private static No no(String proto, String cidade, String tipo, int diasDepois, int score) {
        return new No(proto, ReincidenciaService.chaveDoGrupo(cidade, tipo),
                      T0.plusDays(diasDepois), cidade, tipo, score);
    }

    private static TreeMap<LocalDateTime, List<No>> arvoreDe(No... nos) {
        TreeMap<LocalDateTime, List<No>> a = new TreeMap<>();
        for (No n : nos) a.computeIfAbsent(n.data(), k -> new ArrayList<>()).add(n);
        return a;
    }

    // ---------- chave de grupo ----------

    @Test
    @DisplayName("a chave ignora caixa e espaco, mas separa cidade de tipo")
    void chaveNormaliza() {
        assertEquals(ReincidenciaService.chaveDoGrupo("Barueri", "violencia"),
                     ReincidenciaService.chaveDoGrupo("  BARUERI ", "Violencia"));
        assertNotEquals(ReincidenciaService.chaveDoGrupo("Barueri", "violencia"),
                        ReincidenciaService.chaveDoGrupo("Barueri", "assedio"));
        assertNotEquals(ReincidenciaService.chaveDoGrupo("Barueri", "violencia"),
                        ReincidenciaService.chaveDoGrupo("Santos", "violencia"));
    }

    @Test
    @DisplayName("cidade e tipo nulos nao derrubam a analise")
    void chaveAceitaNulo() {
        assertEquals("?|?", ReincidenciaService.chaveDoGrupo(null, null));
    }

    // ---------- arvore: recorte da janela ----------

    @Test
    @DisplayName("o subMap devolve apenas a janela pedida, com as duas bordas")
    void janelaInclusiva() {
        var arvore = arvoreDe(no("A", "Barueri", "violencia", 0, 50),
                              no("B", "Barueri", "violencia", 5, 50),
                              no("C", "Barueri", "violencia", 30, 50));
        List<No> recorte = ReincidenciaService.recortarJanela(arvore, T0, T0.plusDays(5));
        assertEquals(2, recorte.size());
        assertTrue(recorte.stream().anyMatch(n -> n.protocolo().equals("A")));
        assertTrue(recorte.stream().anyMatch(n -> n.protocolo().equals("B")));
    }

    @Test
    @DisplayName("duas denuncias no mesmo instante nao se sobrescrevem")
    void colisaoDeInstante() {
        // O valor do TreeMap e uma lista justamente por isto. Guardar um No
        // por chave faria a segunda denuncia do mesmo segundo desaparecer.
        var arvore = arvoreDe(no("A", "Barueri", "violencia", 0, 50),
                              no("B", "Barueri", "violencia", 0, 60));
        assertEquals(2, ReincidenciaService.recortarJanela(arvore, T0, T0).size());
    }

    // ---------- busca binaria ----------

    @Test
    @DisplayName("a busca binaria devolve o PRIMEIRO elemento do bloco, nao um do meio")
    void buscaBinariaAchaOInicioDoBloco() {
        List<No> nos = new ArrayList<>(List.of(
            no("A", "Barueri", "violencia", 0, 50),
            no("B", "Barueri", "violencia", 1, 50),
            no("C", "Barueri", "violencia", 2, 50),
            no("D", "Santos",  "violencia", 3, 50)));
        ReincidenciaService.ordenar(nos);
        int i = ReincidenciaService.primeiroDoGrupo(nos,
                    ReincidenciaService.chaveDoGrupo("Barueri", "violencia"));
        assertEquals(0, i, "parar no primeiro acerto devolveria o meio do bloco");
        assertEquals("A", nos.get(i).protocolo());
    }

    @Test
    @DisplayName("grupo inexistente devolve -1 em vez de uma posicao qualquer")
    void buscaBinariaSemResultado() {
        List<No> nos = new ArrayList<>(List.of(no("A", "Barueri", "violencia", 0, 50)));
        ReincidenciaService.ordenar(nos);
        assertEquals(-1, ReincidenciaService.primeiroDoGrupo(nos,
                        ReincidenciaService.chaveDoGrupo("Recife", "abuso")));
    }

    @Test
    @DisplayName("a busca binaria concorda com a varredura linear em todo grupo")
    void buscaBinariaConcordaComVarredura() {
        // Prova de equivalencia: o ganho da busca binaria e de tempo, nunca
        // de resultado. Se divergir da varredura, o ganho nao vale nada.
        List<No> nos = new ArrayList<>();
        String[] cidades = {"Barueri", "Osasco", "Santos", "Recife"};
        String[] tipos   = {"violencia", "assedio", "abuso"};
        int dia = 0;
        for (String c : cidades)
            for (String t : tipos)
                for (int k = 0; k < 3; k++) nos.add(no("P" + (dia), c, t, dia++, 50));
        ReincidenciaService.ordenar(nos);

        for (String c : cidades) {
            for (String t : tipos) {
                String chave = ReincidenciaService.chaveDoGrupo(c, t);
                int linear = -1;
                for (int i = 0; i < nos.size(); i++) {
                    if (nos.get(i).chave().equals(chave)) { linear = i; break; }
                }
                assertEquals(linear, ReincidenciaService.primeiroDoGrupo(nos, chave),
                             "divergencia no grupo " + chave);
            }
        }
    }

    // ---------- grafo e componentes conexos ----------

    @Test
    @DisplayName("tres denuncias encadeadas viram UM foco, mesmo com as pontas distantes")
    void cadeiaTransitiva() {
        // A e C estao a 20 dias, acima da janela de 14. Ainda assim sao o
        // mesmo foco, porque B liga as duas. E exatamente isto que um
        // GROUP BY por cidade e tipo nao consegue expressar.
        List<No> nos = new ArrayList<>(List.of(
            no("A", "Barueri", "violencia", 0,  50),
            no("B", "Barueri", "violencia", 10, 50),
            no("C", "Barueri", "violencia", 20, 50)));
        ReincidenciaService.ordenar(nos);
        var comp = ReincidenciaService.componentesConexos(
                       ReincidenciaService.montarGrafo(nos, 14));
        assertEquals(1, comp.size());
        assertEquals(3, comp.get(0).size());
    }

    @Test
    @DisplayName("quando a cadeia se interrompe, o foco termina e outro comeca")
    void cadeiaInterrompida() {
        List<No> nos = new ArrayList<>(List.of(
            no("A", "Barueri", "violencia", 0,  50),
            no("B", "Barueri", "violencia", 5,  50),
            no("C", "Barueri", "violencia", 60, 50),
            no("D", "Barueri", "violencia", 64, 50)));
        ReincidenciaService.ordenar(nos);
        var comp = ReincidenciaService.componentesConexos(
                       ReincidenciaService.montarGrafo(nos, 14));
        assertEquals(2, comp.size(), "55 dias de silencio separam dois focos");
    }

    @Test
    @DisplayName("grupos diferentes nunca se ligam, por mais proximos que estejam no tempo")
    void gruposNaoSeMisturam() {
        List<No> nos = new ArrayList<>(List.of(
            no("A", "Barueri", "violencia", 0, 50),
            no("B", "Santos",  "violencia", 0, 50),
            no("C", "Barueri", "assedio",   0, 50)));
        ReincidenciaService.ordenar(nos);
        var comp = ReincidenciaService.componentesConexos(
                       ReincidenciaService.montarGrafo(nos, 14));
        assertEquals(3, comp.size());
    }

    @Test
    @DisplayName("a borda da janela de elo nao liga")
    void bordaDaJanelaDeElo() {
        List<No> dentro = List.of(no("A", "Barueri", "violencia", 0, 50),
                                  no("B", "Barueri", "violencia", 14, 50));
        List<No> fora   = List.of(no("A", "Barueri", "violencia", 0, 50),
                                  no("B", "Barueri", "violencia", 15, 50));
        assertEquals(1, ReincidenciaService.componentesConexos(
                            ReincidenciaService.montarGrafo(new ArrayList<>(dentro), 14)).size());
        assertEquals(2, ReincidenciaService.componentesConexos(
                            ReincidenciaService.montarGrafo(new ArrayList<>(fora), 14)).size());
    }

    @Test
    @DisplayName("o grafo tem no maximo k-1 arestas: liga consecutivas, nao todos os pares")
    void grafoEsparso() {
        // A promessa de custo esta aqui. Ligar todos os pares proximos daria
        // O(k2); em 200 relatos seriam quase vinte mil arestas para
        // descrever um unico foco.
        List<No> nos = new ArrayList<>();
        for (int i = 0; i < 200; i++) nos.add(no("P" + i, "Barueri", "violencia", i, 50));
        ReincidenciaService.ordenar(nos);
        var adj = ReincidenciaService.montarGrafo(nos, 14);
        int arestas = adj.stream().mapToInt(List::size).sum() / 2;
        assertEquals(199, arestas);
        assertTrue(arestas <= nos.size() - 1);
        // E mesmo esparso, o componente continua sendo um so.
        assertEquals(1, ReincidenciaService.componentesConexos(adj).size());
    }

    @Test
    @DisplayName("uma corrente muito longa nao estoura a pilha")
    void correnteLonga() {
        // Motivo de a busca ser em largura e nao em profundidade: a versao
        // recursiva abriria dez mil quadros de pilha nesta cadeia.
        List<No> nos = new ArrayList<>();
        for (int i = 0; i < 10_000; i++) nos.add(no("P" + i, "Barueri", "violencia", i, 50));
        ReincidenciaService.ordenar(nos);
        var comp = ReincidenciaService.componentesConexos(
                       ReincidenciaService.montarGrafo(nos, 14));
        assertEquals(1, comp.size());
        assertEquals(10_000, comp.get(0).size());
    }

    @Test
    @DisplayName("lista vazia devolve nenhum componente, sem excecao")
    void listaVazia() {
        assertTrue(ReincidenciaService.componentesConexos(
                       ReincidenciaService.montarGrafo(new ArrayList<>(), 14)).isEmpty());
    }

    @Test
    @DisplayName("a ordenacao poe o mesmo grupo em bloco e em ordem cronologica")
    void ordenacaoAgrupaEOrdena() {
        List<No> nos = new ArrayList<>(List.of(
            no("C", "Barueri", "violencia", 9, 50),
            no("X", "Santos",  "violencia", 1, 50),
            no("A", "Barueri", "violencia", 2, 50)));
        ReincidenciaService.ordenar(nos);
        assertEquals("A", nos.get(0).protocolo());
        assertEquals("C", nos.get(1).protocolo());
        assertEquals("X", nos.get(2).protocolo());
    }

    // ---------- foco que se destaca x volume normal do lugar ----------

    @Test
    @DisplayName("um componente que reune quase todo o grupo e fluxo continuo, nao foco")
    void componenteQueEOProprioGrupo() {
        // O caso que apareceu na demonstracao: 44 denuncias de violencia em
        // Barueri num grupo de 44. Tratar isso como foco mandaria a equipe
        // montar uma operacao contra a operacao inteira do municipio.
        assertTrue(ReincidenciaService.ehFluxoContinuo(44, 44));
        assertTrue(ReincidenciaService.ehFluxoContinuo(14, 20));   // 70%, no limite
    }

    @Test
    @DisplayName("um componente que e parte do grupo continua sendo foco")
    void componenteQueSeDestaca() {
        assertFalse(ReincidenciaService.ehFluxoContinuo(11, 20));  // 55%
        assertFalse(ReincidenciaService.ehFluxoContinuo(13, 20));  // 65%
    }

    @Test
    @DisplayName("grupo pequeno nunca e marcado como fluxo continuo")
    void grupoPequenoNaoSatura() {
        // Num grupo de 4, o componente quase sempre cobre quase tudo. O
        // corte ali marcaria como "volume normal" o que e so grupo pequeno.
        assertFalse(ReincidenciaService.ehFluxoContinuo(4, 4));
        assertFalse(ReincidenciaService.ehFluxoContinuo(9, 9));
        assertTrue(ReincidenciaService.ehFluxoContinuo(10, 10));
    }

    @Test
    @DisplayName("o limiar de saturacao e uma fracao, e nao um numero absoluto")
    void limiarERelativo() {
        // 30 denuncias num grupo de 100 nao saturam; 30 num grupo de 40 sim.
        // Um limite absoluto ("acima de 25 e fluxo") erraria os dois.
        assertFalse(ReincidenciaService.ehFluxoContinuo(30, 100));
        assertTrue(ReincidenciaService.ehFluxoContinuo(30, 40));
    }
}
