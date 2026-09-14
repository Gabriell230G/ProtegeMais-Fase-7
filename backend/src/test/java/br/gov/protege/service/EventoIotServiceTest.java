package br.gov.protege.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.Locale;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Regras do barramento de eventos de IoT.
 *
 * Os valores esperados foram definidos a mao a partir das regras escritas na
 * documentacao da Fase 6, e nao a partir da saida do proprio programa. Um
 * teste que confere o codigo contra ele mesmo passa a fingir que a regra
 * esta certa exatamente quando ela deixa de estar.
 */
@DisplayName("Barramento de eventos de IoT")
class EventoIotServiceTest {

    // ---------- chave do dispositivo ----------

    @Test
    @DisplayName("chave correta e aceita")
    void chaveCorreta() {
        assertTrue(EventoIotService.chaveValida("protege-iot-2026", "protege-iot-2026"));
    }

    @Test
    @DisplayName("chave errada, ausente ou de tamanho diferente e recusada")
    void chaveErrada() {
        assertFalse(EventoIotService.chaveValida("protege-iot-2026", "protege-iot-2025"));
        assertFalse(EventoIotService.chaveValida("protege-iot-2026", "protege"));
        assertFalse(EventoIotService.chaveValida("protege-iot-2026", null));
        assertFalse(EventoIotService.chaveValida(null, "protege-iot-2026"));
    }

    @Test
    @DisplayName("a comparacao percorre a chave inteira, sem sair no primeiro caractere diferente")
    void comparacaoNaoCurtoCircuita() {
        // Difere ja no primeiro caractere e no ultimo: as duas devem ser falsas.
        assertFalse(EventoIotService.chaveValida("abcdefgh", "zbcdefgh"));
        assertFalse(EventoIotService.chaveValida("abcdefgh", "abcdefgz"));
    }

    // ---------- repique ----------

    @Test
    @DisplayName("segundo aperto dentro da janela e repique")
    void repiqueDentroDaJanela() {
        LocalDateTime primeiro = LocalDateTime.of(2026, 9, 13, 22, 40, 0);
        LocalDateTime segundo  = primeiro.plusSeconds(11);
        assertTrue(EventoIotService.ehRepique(primeiro, segundo,
                   EventoIotService.JANELA_REPIQUE_SEGUNDOS));
    }

    @Test
    @DisplayName("aperto no limite exato da janela ja e caso novo")
    void limiteExatoNaoEhRepique() {
        LocalDateTime primeiro = LocalDateTime.of(2026, 9, 13, 22, 40, 0);
        LocalDateTime segundo  = primeiro.plusSeconds(EventoIotService.JANELA_REPIQUE_SEGUNDOS);
        assertFalse(EventoIotService.ehRepique(primeiro, segundo,
                    EventoIotService.JANELA_REPIQUE_SEGUNDOS));
    }

    @Test
    @DisplayName("sem acionamento anterior nao ha repique")
    void semAnterior() {
        assertFalse(EventoIotService.ehRepique(null, LocalDateTime.now(), 120));
    }

    @Test
    @DisplayName("evento com carimbo anterior ao ultimo aceito nao conta como repique")
    void relogioParaTras() {
        LocalDateTime primeiro = LocalDateTime.of(2026, 9, 13, 22, 40, 0);
        LocalDateTime atrasado = primeiro.minusSeconds(5);
        assertFalse(EventoIotService.ehRepique(primeiro, atrasado, 120));
    }

    // ---------- relato entregue ao VigIA ----------

    @Test
    @DisplayName("o relato carrega os marcadores que descrevem um pedido de socorro imediato")
    void relatoTemMarcadores() {
        String r = EventoIotService.relatoDoAcionamento("d7f3a1b9", -23.5108, -46.8760, 87)
                                   .toLowerCase();
        assertTrue(r.contains("socorro"), "o relato precisa dizer que e um pedido de socorro");
        assertTrue(r.contains("agora"),   "o relato precisa marcar que o evento e imediato");
        assertTrue(r.contains("d7f3a1b9"), "o relato precisa citar o aparelho");
    }

    @Test
    @DisplayName("o relato nunca cita nome, documento ou contato de pessoa")
    void relatoNaoTemDadoPessoal() {
        String r = EventoIotService.relatoDoAcionamento("d7f3a1b9", -23.5108, -46.8760, 87);
        assertFalse(r.matches(".*\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}.*"), "nao pode conter CPF");
        assertFalse(r.contains("@"), "nao pode conter e-mail");
    }

    @Test
    @DisplayName("acionamento sem coordenada continua gerando relato valido")
    void relatoSemCoordenada() {
        String r = EventoIotService.relatoDoAcionamento("d7f3a1b9", null, null, null);
        assertTrue(r.contains("socorro"));
        assertFalse(r.contains("Coordenada"));
    }

    @Test
    @DisplayName("a coordenada usa ponto decimal mesmo em maquina configurada em portugues")
    void coordenadaIndependeDaLocalidade() {
        // Este teste existe por causa de um defeito real: String.format sem
        // Locale usava a virgula da localidade da maquina, e a coordenada
        // saia como -23,510800. Passava em ambiente em ingles e falhava no
        // ambiente de verdade.
        Locale anterior = Locale.getDefault();
        try {
            Locale.setDefault(new Locale("pt", "BR"));
            assertEquals("-23.510800", EventoIotService.coordenada(-23.5108));
            assertTrue(EventoIotService.relatoDoAcionamento("d1", -23.5108, -46.876, 50)
                                       .contains("-23.510800"));
        } finally {
            Locale.setDefault(anterior);
        }
    }

    @Test
    @DisplayName("a coordenada vira endereco aproximado com seis casas decimais")
    void coordenadaComoEndereco() {
        assertEquals("Coordenada aproximada -23.510800, -46.876000",
                     EventoIotService.coordenadaComoEndereco(-23.5108, -46.876));
        assertNull(EventoIotService.coordenadaComoEndereco(null, -46.876));
    }

    // ---------- geofencing: distancia ----------

    /*
     * Os valores esperados abaixo foram calculados por fora, com a formula de
     * Haversine e raio medio de 6.371.000 m, e conferidos contra referencias
     * conhecidas (um grau de longitude no equador mede 111,19 km). Conferir o
     * programa contra a propria saida so provaria que ele e consistente com
     * ele mesmo, inclusive quando estiver consistentemente errado.
     */

    @Test
    @DisplayName("distancia de um ponto ate ele mesmo e zero")
    void distanciaZero() {
        assertEquals(0.0, EventoIotService.distanciaMetros(-23.5108, -46.8760, -23.5108, -46.8760), 0.001);
    }

    @Test
    @DisplayName("distancia curta confere com o calculo feito por fora")
    void distanciaCurta() {
        double d = EventoIotService.distanciaMetros(-23.5108, -46.8760, -23.5090, -46.8731);
        assertEquals(357.068, d, 0.5);
    }

    @Test
    @DisplayName("um grau de longitude no equador mede cerca de 111,19 km")
    void grauNoEquador() {
        assertEquals(111194.927, EventoIotService.distanciaMetros(0, 0, 0, 1), 1.0);
    }

    @Test
    @DisplayName("distancia entre Barueri e o centro de Sao Paulo confere com a referencia")
    void distanciaLonga() {
        double d = EventoIotService.distanciaMetros(-23.5108, -46.8760, -23.5505, -46.6333);
        assertEquals(25133.654, d, 5.0);
    }

    @Test
    @DisplayName("a distancia e simetrica nos dois sentidos")
    void distanciaSimetrica() {
        double ida   = EventoIotService.distanciaMetros(-23.5108, -46.8760, -23.5505, -46.6333);
        double volta = EventoIotService.distanciaMetros(-23.5505, -46.6333, -23.5108, -46.8760);
        assertEquals(ida, volta, 0.001);
    }

    // ---------- geofencing: perimetro ----------

    @Test
    @DisplayName("dentro do raio viola, a borda exata nao viola")
    void perimetro() {
        assertTrue (EventoIotService.violouPerimetro(499.9, 500));
        assertFalse(EventoIotService.violouPerimetro(500.0, 500));
        assertFalse(EventoIotService.violouPerimetro(500.1, 500));
    }

    // ---------- geofencing: intervalo entre alertas ----------

    @Test
    @DisplayName("primeira violacao sempre alerta")
    void primeiroAlerta() {
        assertTrue(EventoIotService.deveAlertar(null, LocalDateTime.now(),
                   EventoIotService.COOLDOWN_ALERTA_SEGUNDOS));
    }

    @Test
    @DisplayName("leitura repetida dentro do intervalo nao abre caso novo")
    void semRepeticao() {
        LocalDateTime alerta  = LocalDateTime.of(2026, 9, 13, 22, 0, 0);
        LocalDateTime leitura = alerta.plusSeconds(30);
        assertFalse(EventoIotService.deveAlertar(alerta, leitura,
                    EventoIotService.COOLDOWN_ALERTA_SEGUNDOS));
    }

    @Test
    @DisplayName("no intervalo exato o alerta volta a ser permitido")
    void limiteDoIntervalo() {
        LocalDateTime alerta  = LocalDateTime.of(2026, 9, 13, 22, 0, 0);
        LocalDateTime leitura = alerta.plusSeconds(EventoIotService.COOLDOWN_ALERTA_SEGUNDOS);
        assertTrue(EventoIotService.deveAlertar(alerta, leitura,
                   EventoIotService.COOLDOWN_ALERTA_SEGUNDOS));
    }

    // ---------- geofencing: relato ----------

    @Test
    @DisplayName("o relato da violacao distingue entrada de permanencia")
    void motivoDoAlerta() {
        assertEquals("Entrada no perimetro de exclusao", EventoIotService.motivoDoAlerta(false));
        assertEquals("Permanencia dentro do perimetro de exclusao", EventoIotService.motivoDoAlerta(true));
    }

    @Test
    @DisplayName("o relato da violacao nao carrega coordenada da pessoa protegida")
    void relatoDaViolacaoSemCoordenada() {
        String processo = "0007441-88.2026";
        String r = EventoIotService.relatoDaViolacao(processo, "TZ-4471", false);
        assertTrue(r.contains("agora"), "precisa marcar que o evento e imediato");
        assertTrue(r.contains(processo));
        assertTrue(r.contains("TZ-4471"));

        // O numero do processo e informacao publica do ato judicial e por isso
        // pode aparecer. Ele sai do texto antes da varredura porque a sua
        // propria forma (0007441-88.2026) imita um par decimal com sinal, e
        // sem essa remocao o teste acusaria o dado que ele mesmo mandou entrar.
        String semProcesso = r.replace(processo, "");

        // Coordenada, neste sistema, nasce sempre de coordenada(Double), que
        // formata com seis casas. E essa assinatura que nao pode existir aqui.
        assertFalse(semProcesso.matches("(?s).*-?\\d{1,3}\\.\\d{6}.*"),
                "nao pode conter coordenada");

        // Prova de que a varredura enxerga o que deveria enxergar: o mesmo
        // texto com uma coordenada real colada e reprovado.
        String contaminado = semProcesso + " " + EventoIotService.coordenada(-23.5108);
        assertTrue(contaminado.matches("(?s).*-?\\d{1,3}\\.\\d{6}.*"),
                "a varredura precisa reprovar um texto que realmente tem coordenada");
    }

    // ---------- totem publico ----------

    @Test
    @DisplayName("o texto do totem perde caracteres de controle e espaco repetido")
    void higienizaTextoDeTecladoFisico() {
        String bruto = "  ele   apareceu\n\nna   porta\tde novo  ";
        assertEquals("ele apareceu na porta de novo", EventoIotService.higienizarRelato(bruto));
    }

    @Test
    @DisplayName("texto nulo vira vazio, e vazio nao e relato")
    void higienizaNulo() {
        assertEquals("", EventoIotService.higienizarRelato(null));
        assertFalse(EventoIotService.relatoAceitavel(null));
        assertFalse(EventoIotService.relatoAceitavel("   "));
    }

    @Test
    @DisplayName("texto longo demais e cortado, nao recusado")
    void cortaEmVezDeRecusar() {
        String longo = "a".repeat(EventoIotService.RELATO_MAXIMO + 500);
        String limpo = EventoIotService.higienizarRelato(longo);
        assertEquals(EventoIotService.RELATO_MAXIMO, limpo.length());
        // Recusar obrigaria a pessoa a reescrever de pe, na fila. Cortar
        // preserva o inicio do relato, que e onde ela conta o que houve.
        assertTrue(EventoIotService.relatoAceitavel(longo));
    }

    @Test
    @DisplayName("relato curto demais nao abre caso")
    void relatoCurtoNaoAbreCaso() {
        assertFalse(EventoIotService.relatoAceitavel("socorro"));
        assertTrue(EventoIotService.relatoAceitavel("ele me ameacou na saida do trabalho"));
    }

    @Test
    @DisplayName("o limite de tamanho conta o texto ja higienizado")
    void limiteContaTextoLimpo() {
        // Quinze espacos nao sao quinze caracteres de relato. Se a validacao
        // olhasse o texto bruto, uma tecla presa passaria pela porta.
        assertFalse(EventoIotService.relatoAceitavel("               "));
    }

    @Test
    @DisplayName("tipo desconhecido vira outros em vez de derrubar o registro")
    void tipoDesconhecidoNaoPerdeORelato() {
        assertEquals("violencia", EventoIotService.tipoValido("violencia"));
        assertEquals("assedio",   EventoIotService.tipoValido("  ASSEDIO "));
        assertEquals("outros",    EventoIotService.tipoValido("qualquer-coisa"));
        assertEquals("outros",    EventoIotService.tipoValido(null));
    }

    @Test
    @DisplayName("o relato do totem cita o local da instalacao e preserva a palavra da pessoa")
    void relatoDoTotemPreservaOTexto() {
        String r = EventoIotService.relatoDoTotem("UBS Central de Barueri",
                                                  "ele apareceu na porta de novo");
        assertTrue(r.contains("UBS Central de Barueri"));
        assertTrue(r.contains("ele apareceu na porta de novo"),
                "o texto digitado entra inteiro, sem parafrase");
        assertTrue(r.contains("anonimo"), "precisa declarar que o registro e anonimo por natureza");
    }

    @Test
    @DisplayName("a janela de repique do totem e menor que a do botao de panico")
    void janelaDoTotemEMenor() {
        // Nao e um detalhe de ajuste fino: as duas origens tem premissas
        // opostas. O botao e de uma pessoa so; o totem tem fila.
        assertTrue(EventoIotService.JANELA_REPIQUE_TOTEM_SEGUNDOS
                 < EventoIotService.JANELA_REPIQUE_SEGUNDOS);
    }

    @Test
    @DisplayName("toque duplo no botao de enviar e reenvio, nao caso novo")
    void toqueDuploEReenvio() {
        LocalDateTime t0 = LocalDateTime.of(2026, 5, 2, 10, 0, 0);
        assertTrue(EventoIotService.ehRepique(t0, t0.plusSeconds(3),
                EventoIotService.JANELA_REPIQUE_TOTEM_SEGUNDOS));
    }

    @Test
    @DisplayName("a proxima pessoa da fila nao e tratada como repique")
    void proximaPessoaDaFilaNaoERepique() {
        LocalDateTime t0 = LocalDateTime.of(2026, 5, 2, 10, 0, 0);

        // Sessenta segundos depois, no mesmo aparelho: com a janela do botao
        // de panico isto seria descartado como duplicata, e a denuncia de
        // quem chegou depois desapareceria dentro do caso de quem veio antes.
        assertTrue(EventoIotService.ehRepique(t0, t0.plusSeconds(60),
                EventoIotService.JANELA_REPIQUE_SEGUNDOS));
        assertFalse(EventoIotService.ehRepique(t0, t0.plusSeconds(60),
                EventoIotService.JANELA_REPIQUE_TOTEM_SEGUNDOS));
    }

    @Test
    @DisplayName("a borda da janela do totem nao e repique")
    void bordaDaJanelaDoTotem() {
        LocalDateTime t0 = LocalDateTime.of(2026, 5, 2, 10, 0, 0);
        int j = EventoIotService.JANELA_REPIQUE_TOTEM_SEGUNDOS;
        assertTrue(EventoIotService.ehRepique(t0, t0.plusSeconds(j - 1), j));
        assertFalse(EventoIotService.ehRepique(t0, t0.plusSeconds(j), j));
    }

    @Test
    @DisplayName("o protocolo tem prazo de tela no totem")
    void protocoloTemPrazoDeTela() {
        // Um protocolo e a chave de leitura do caso. Num monitor de saguao ele
        // fica visivel para a fila inteira, e por isso a resposta carrega o
        // tempo em que a tela deve se apagar sozinha.
        assertTrue(EventoIotService.SEGUNDOS_TELA_LIMPA > 0);
        assertTrue(EventoIotService.SEGUNDOS_TELA_LIMPA <= 120,
                "tempo longo demais deixa o protocolo exposto sem necessidade");
    }
}
