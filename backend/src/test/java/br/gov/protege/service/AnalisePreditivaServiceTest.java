package br.gov.protege.service;

import br.gov.protege.dto.AnalisePreditivaResponse;
import br.gov.protege.model.Denuncia;
import br.gov.protege.repository.DenunciaRepository;
import br.gov.protege.repository.MembroRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Analise preditiva: correlacao, regressao e insights")
class AnalisePreditivaServiceTest {

    private static final String[] TIPOS = {"violencia", "assedio", "outros", "abuso", "discriminacao"};

    /**
     * Base sintetica com relacao conhecida: o tempo cai 1,5 dia por ponto de
     * gravidade, e o score e o anonimato nao tem efeito nenhum.
     */
    private List<Denuncia> base() {
        List<Denuncia> lista = new ArrayList<>();
        LocalDateTime inicio = LocalDateTime.of(2026, 3, 2, 9, 0);
        for (int i = 0; i < 60; i++) {
            String tipo = TIPOS[i % TIPOS.length];
            double gravidade = AnalisePreditivaService.GRAVIDADE.get(tipo);
            double ruido = ((i * 37) % 11) / 10.0;          // deterministico, entre 0 e 1
            double dias = 12 - 1.5 * gravidade + ruido;
            Denuncia d = new Denuncia();
            d.setTipo(tipo);
            d.setDescricao("Relato de teste numero " + i);
            d.setScore(40 + (i * 13) % 50);
            d.setAnonimo(i % 2 == 0);
            d.setUrgenciaIa(i % 3 == 0 ? "ALTA" : "MEDIA");
            d.setCriadoEm(inicio.plusDays(i));
            d.setConcluidaEm(inicio.plusDays(i).plusMinutes(Math.round(dias * 1440)));
            lista.add(d);
        }
        return lista;
    }

    private AnalisePreditivaService servico(List<Denuncia> dados, long equipe) {
        DenunciaRepository repo = Mockito.mock(DenunciaRepository.class);
        MembroRepository membros = Mockito.mock(MembroRepository.class);
        Mockito.when(repo.findByExcluidaFalseOrderByCriadoEmDesc()).thenReturn(dados);
        Mockito.when(membros.count()).thenReturn(equipe);
        return new AnalisePreditivaService(repo, membros);
    }

    @Test
    @DisplayName("encontra a gravidade como fator principal e a inclinacao certa")
    void fatorPrincipal() {
        AnalisePreditivaResponse r = servico(base(), 2).gerar();
        assertEquals(60, r.casosConcluidos());
        AnalisePreditivaResponse.CorrelacaoComTempo g = r.correlacoesComTempo().stream()
                .filter(c -> c.chave().equals("gravidade")).findFirst().orElseThrow();
        assertTrue(g.significativa());
        assertTrue(g.pearson() < -0.9);
        assertEquals(-1.5, r.regressaoSimples().coeficientes().get(1).valor(), 0.1);
        assertTrue(r.insights().get(0).titulo().startsWith("Gravidade do tipo"));
    }

    @Test
    @DisplayName("score sem efeito gera o alerta de troca do score")
    void scoreSemEfeito() {
        AnalisePreditivaResponse r = servico(base(), 2).gerar();
        assertTrue(r.insights().stream().anyMatch(i -> i.titulo().startsWith("O score atual")));
    }

    @Test
    @DisplayName("matriz de Pearson e quadrada com diagonal 1")
    void matriz() {
        AnalisePreditivaResponse r = servico(base(), 2).gerar();
        int k = r.variaveis().size();
        assertEquals(k, r.matrizPearson().size());
        for (int i = 0; i < k; i++) assertEquals(1.0, r.matrizPearson().get(i).get(i));
    }

    @Test
    @DisplayName("tendencia ignora registro isolado meses depois e projeta 4 semanas")
    void tendencia() {
        List<Denuncia> dados = new ArrayList<>(base());
        Denuncia tardia = new Denuncia();
        tardia.setTipo("outros");
        tardia.setDescricao("Registro de teste feito muito depois da carga");
        tardia.setUrgenciaIa("BAIXA");
        tardia.setCriadoEm(LocalDateTime.of(2026, 10, 27, 20, 0));
        dados.add(tardia);
        AnalisePreditivaResponse.Tendencia t = servico(dados, 2).gerar().tendenciaSemanal();
        assertNotNull(t);
        assertTrue(t.ate().isBefore(java.time.LocalDate.of(2026, 6, 1)));
        assertEquals(4, t.serie().stream().filter(AnalisePreditivaResponse.Semana::projecao).count());
        assertNotNull(t.equipeNecessaria());
    }

    @Test
    @DisplayName("amostra pequena nao gera conclusao")
    void amostraPequena() {
        AnalisePreditivaResponse r = servico(base().subList(0, 5), 1).gerar();
        assertEquals(1, r.insights().size());
        assertEquals("Amostra pequena demais", r.insights().get(0).titulo());
    }
}
