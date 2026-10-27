package br.gov.protege.service;

import br.gov.protege.dto.AcionamentoSosRequest;
import br.gov.protege.model.Denuncia;
import br.gov.protege.model.EventoIot;
import br.gov.protege.dto.DenunciaRequest;
import br.gov.protege.dto.RegistroTotemRequest;
import br.gov.protege.dto.TelemetriaGeofenceRequest;
import br.gov.protege.model.PontoTotem;
import br.gov.protege.model.ZonaExclusao;
import br.gov.protege.repository.EventoIotRepository;
import br.gov.protege.repository.PontoTotemRepository;
import br.gov.protege.repository.ZonaExclusaoRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.List;
import java.util.Optional;

/**
 * Barramento de eventos de dispositivos fisicos (Fase 6).
 *
 * Tres decisoes estruturam este servico.
 *
 * 1. O dispositivo NAO cria denuncia. Ele relata um evento, e quem decide o
 *    que fazer com ele e o servidor. Deixar o aparelho criar o caso seria
 *    confiar numa peca de hardware que pode ser clonada ou apertada sem
 *    querer dentro do bolso.
 *
 * 2. O evento NAO carrega classificacao de urgencia. Ele monta um relato
 *    descrevendo o que aconteceu e entrega ao VigIA, que classifica com o
 *    mesmo criterio de qualquer outra denuncia. Se o dispositivo pudesse
 *    declarar "isto e CRITICO", a fila de prioridade passaria a ser definida
 *    por quem tem o aparelho, e nao pela gravidade do caso.
 *
 * 3. Repique e tratado como duplicata, nao como caso novo. Um botao apertado
 *    tres vezes em dez segundos e uma pessoa com medo, nao tres ocorrencias.
 */
@Service
public class EventoIotService {

    /** Janela em que um novo acionamento do MESMO aparelho e repique. */
    public static final int JANELA_REPIQUE_SEGUNDOS = 120;

    /** Intervalo minimo entre dois alertas da MESMA medida protetiva. */
    public static final int COOLDOWN_ALERTA_SEGUNDOS = 600;

    /** Raio medio da Terra, em metros, usado na formula de Haversine. */
    public static final double RAIO_TERRA_METROS = 6_371_000.0;

    /**
     * Janela de repique do totem, deliberadamente curta.
     *
     * No botao de panico a janela e de 120 segundos porque o mesmo aparelho
     * apertado tres vezes em dois minutos e uma pessoa com medo. No totem a
     * premissa se inverte: e um equipamento publico com fila, e duas pessoas
     * diferentes usando o mesmo aparelho em dois minutos e o comportamento
     * esperado, nao a anomalia. Uma janela longa aqui apagaria a denuncia de
     * quem chegou depois. Vinte segundos cobrem o toque duplo no botao de
     * enviar e nada alem disso.
     */
    public static final int JANELA_REPIQUE_TOTEM_SEGUNDOS = 20;

    /** Tempo que o protocolo pode permanecer na tela de um totem publico. */
    public static final int SEGUNDOS_TELA_LIMPA = 45;

    /** Abaixo disto o texto nao descreve fato nenhum e nao da o que apurar. */
    public static final int RELATO_MINIMO = 15;

    /** Acima disto o texto e truncado antes de chegar ao banco. */
    public static final int RELATO_MAXIMO = 1200;

    /** Tipos que o totem oferece na tela. Qualquer outro vira 'outros'. */
    private static final List<String> TIPOS = List.of(
            "violencia", "abuso", "assedio", "discriminacao", "outros");

    private final EventoIotRepository repo;
    private final ZonaExclusaoRepository zonas;
    private final PontoTotemRepository totens;
    private final DenunciaService denuncias;
    private final AuditoriaService auditoria;
    private final String chaveEsperada;

    public EventoIotService(EventoIotRepository repo,
                            ZonaExclusaoRepository zonas,
                            PontoTotemRepository totens,
                            DenunciaService denuncias,
                            AuditoriaService auditoria,
                            @Value("${protege.iot.chave}") String chaveEsperada) {
        this.repo = repo;
        this.zonas = zonas;
        this.totens = totens;
        this.denuncias = denuncias;
        this.auditoria = auditoria;
        this.chaveEsperada = chaveEsperada;
    }

    // ------------------------------------------------------------------
    //  Regras puras, testaveis sem banco e sem Spring
    // ------------------------------------------------------------------

    /**
     * Compara a chave do dispositivo em tempo constante.
     *
     * Comparar com equals vazaria, pelo tempo de resposta, quantos caracteres
     * iniciais o atacante acertou. O custo de evitar isso e uma linha.
     */
    public static boolean chaveValida(String esperada, String recebida) {
        if (esperada == null || recebida == null) return false;
        if (esperada.length() != recebida.length()) return false;
        int diferenca = 0;
        for (int i = 0; i < esperada.length(); i++) {
            diferenca |= esperada.charAt(i) ^ recebida.charAt(i);
        }
        return diferenca == 0;
    }

    /** Verdadeiro quando o acionamento cai na janela de repique do anterior. */
    public static boolean ehRepique(LocalDateTime anterior, LocalDateTime agora, int janelaSegundos) {
        if (anterior == null || agora == null) return false;
        long segundos = ChronoUnit.SECONDS.between(anterior, agora);
        return segundos >= 0 && segundos < janelaSegundos;
    }

    /**
     * Monta o relato que vai para o VigIA.
     *
     * As palavras "socorro" e "agora" nao estao aqui por acaso nem para
     * enganar o classificador: elas descrevem o que um botao de panico e,
     * um pedido de socorro imediato. O VigIA le esse texto com o mesmo
     * criterio que aplica a qualquer relato digitado por uma pessoa.
     */
    public static String relatoDoAcionamento(String dispositivo, Double lat, Double lng, Integer bateria) {
        StringBuilder sb = new StringBuilder();
        sb.append("Pedido de socorro enviado agora por botao de panico fisico. ");
        sb.append("Dispositivo ").append(dispositivo).append(". ");
        if (lat != null && lng != null) {
            sb.append("Coordenada informada pelo aparelho: ")
              .append(coordenada(lat)).append(", ")
              .append(coordenada(lng)).append(". ");
        }
        if (bateria != null) sb.append("Bateria do aparelho em ").append(bateria).append("%. ");
        sb.append("Acionamento sem texto: a pessoa nao teve condicao de escrever.");
        return sb.toString();
    }

    // ------------------------------------------------------------------
    //  Origem A: botao de panico
    // ------------------------------------------------------------------

    @Transactional
    public EventoIot registrarAcionamento(AcionamentoSosRequest req) {
        LocalDateTime agora = LocalDateTime.now().truncatedTo(ChronoUnit.MILLIS);

        EventoIot evento = new EventoIot(EventoIot.SOS, req.getDispositivo());
        evento.setLatitude(req.getLat());
        evento.setLongitude(req.getLng());
        evento.setBateria(req.getBateria());
        evento.setRecebidoEm(agora);

        Optional<EventoIot> ultimo = repo
                .findFirstByDispositivoAndSituacaoOrderByRecebidoEmDesc(
                        req.getDispositivo(), EventoIot.ACEITO);

        if (ultimo.isPresent() && ehRepique(ultimo.get().getRecebidoEm(), agora, JANELA_REPIQUE_SEGUNDOS)) {
            evento.setSituacao(EventoIot.DUPLICADO);
            evento.setProtocoloGerado(ultimo.get().getProtocoloGerado());
            evento.setDetalhe("Repique dentro de " + JANELA_REPIQUE_SEGUNDOS
                            + "s do acionamento anterior; vinculado ao mesmo caso");
            return repo.save(evento);
        }

        DenunciaRequest pedido = new DenunciaRequest();
        pedido.setTipo("violencia");
        pedido.setDescricao(relatoDoAcionamento(req.getDispositivo(), req.getLat(),
                                                req.getLng(), req.getBateria()));
        pedido.setEstado(req.getEstado() == null || req.getEstado().isBlank() ? "SP" : req.getEstado());
        pedido.setCidade(req.getCidade() == null || req.getCidade().isBlank() ? "Barueri" : req.getCidade());
        pedido.setEndereco(coordenadaComoEndereco(req.getLat(), req.getLng()));
        pedido.setAnonimo(true);

        Denuncia criada = denuncias.registrar(pedido);

        evento.setSituacao(EventoIot.ACEITO);
        evento.setProtocoloGerado(criada.getProtocolo());
        evento.setDetalhe("Acionamento de botao de panico; caso aberto com urgencia "
                        + criada.getUrgenciaIa());
        EventoIot salvo = repo.save(evento);

        auditoria.registrar(AuditoriaService.ALTERACAO_DADOS, "EventoIot",
                            String.valueOf(salvo.getId()));
        return salvo;
    }

    /**
     * Formata uma coordenada com ponto decimal, sempre.
     *
     * String.format usa a localidade padrao da JVM. Numa maquina em portugues
     * isso produz "-23,510800", com virgula, e uma coordenada com virgula
     * quebra qualquer consumidor que espere o formato WGS 84. O defeito nao
     * aparece em maquina configurada em ingles, o que o torna do tipo que so
     * se manifesta no ambiente real. Locale.ROOT elimina a variavel.
     */
    public static String coordenada(Double valor) {
        return valor == null ? "" : String.format(Locale.ROOT, "%.6f", valor);
    }

    /** Coordenada exibida como endereco aproximado, sem geocodificacao reversa. */
    public static String coordenadaComoEndereco(Double lat, Double lng) {
        if (lat == null || lng == null) return null;
        return "Coordenada aproximada " + coordenada(lat) + ", " + coordenada(lng);
    }

    // ------------------------------------------------------------------
    //  Origem B: geofencing de medida protetiva
    // ------------------------------------------------------------------

    /**
     * Distancia entre dois pontos da superficie pela formula de Haversine.
     *
     * Em vez do teorema de Pitagoras sobre as coordenadas, que trataria a
     * Terra como um plano e erraria mais quanto maior a distancia e quanto
     * mais longe do equador. Nas centenas de metros de um perimetro de
     * medida protetiva a diferenca e pequena, mas a formula errada seria
     * uma escolha errada de qualquer forma, e o custo de acertar e o mesmo.
     */
    public static double distanciaMetros(double lat1, double lng1, double lat2, double lng2) {
        double f1 = Math.toRadians(lat1);
        double f2 = Math.toRadians(lat2);
        double df = Math.toRadians(lat2 - lat1);
        double dl = Math.toRadians(lng2 - lng1);
        double a = Math.sin(df / 2) * Math.sin(df / 2)
                 + Math.cos(f1) * Math.cos(f2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        return 2 * RAIO_TERRA_METROS * Math.asin(Math.sqrt(a));
    }

    /** Verdadeiro quando o ponto esta DENTRO do raio. A borda exata nao viola. */
    public static boolean violouPerimetro(double distanciaMetros, int raioMetros) {
        return distanciaMetros < raioMetros;
    }

    /**
     * Decide se esta leitura deve gerar alerta.
     *
     * A telemetria chega de trinta em trinta segundos. Sem esta regra, uma
     * hora de permanencia dentro do perimetro viraria 120 denuncias do mesmo
     * fato, e a fila de prioridade seria tomada por repeticao em vez de por
     * gravidade. O intervalo minimo tambem resolve o caso de quem fica indo
     * e voltando na linha da borda.
     */
    public static boolean deveAlertar(LocalDateTime ultimoAlerta, LocalDateTime agora,
                                      int cooldownSegundos) {
        if (ultimoAlerta == null) return true;
        return ChronoUnit.SECONDS.between(ultimoAlerta, agora) >= cooldownSegundos;
    }

    /** Texto do evento, conforme seja entrada nova ou permanencia. */
    public static String motivoDoAlerta(boolean estavaDentro) {
        return estavaDentro ? "Permanencia dentro do perimetro de exclusao"
                            : "Entrada no perimetro de exclusao";
    }

    /**
     * Relato entregue ao VigIA quando um perimetro e violado.
     *
     * Nao cita nome, endereco nem a coordenada da pessoa protegida. Cita o
     * processo, que e informacao publica do ato judicial, e o equipamento.
     */
    public static String relatoDaViolacao(String processo, String tornozeleira, boolean estavaDentro) {
        return "Descumprimento de medida protetiva detectado agora por monitoracao eletronica. "
             + motivoDoAlerta(estavaDentro) + ". "
             + "Processo " + processo + ", equipamento " + tornozeleira + ". "
             + "Evento gerado pelo servidor a partir da telemetria, sem intervencao humana.";
    }

    @Transactional
    public TelemetriaResultado registrarTelemetria(TelemetriaGeofenceRequest req) {
        LocalDateTime agora = LocalDateTime.now().truncatedTo(ChronoUnit.MILLIS);

        Optional<ZonaExclusao> achada = zonas.findByTornozeleiraAndAtivaTrue(req.getTornozeleira());
        if (achada.isEmpty()) {
            // Equipamento sem medida ativa: o evento e guardado para auditoria
            // do proprio parque de aparelhos, mas nao gera caso.
            EventoIot ignorado = new EventoIot(EventoIot.GEOFENCE, req.getTornozeleira());
            ignorado.setLatitude(req.getLat());
            ignorado.setLongitude(req.getLng());
            ignorado.setBateria(req.getBateria());
            ignorado.setRecebidoEm(agora);
            ignorado.setSituacao(EventoIot.DESCARTADO);
            ignorado.setDetalhe("Equipamento sem medida protetiva ativa vinculada");
            repo.save(ignorado);
            return new TelemetriaResultado(false, null);
        }

        ZonaExclusao zona = achada.get();
        double distancia = distanciaMetros(req.getLat(), req.getLng(),
                                           zona.getLatProtegida(), zona.getLngProtegida());
        boolean dentro = violouPerimetro(distancia, zona.getRaioMetros());

        EventoIot evento = new EventoIot(EventoIot.GEOFENCE, req.getTornozeleira());
        evento.setLatitude(req.getLat());
        evento.setLongitude(req.getLng());
        evento.setBateria(req.getBateria());
        evento.setRecebidoEm(agora);

        if (!dentro) {
            evento.setSituacao(EventoIot.ACEITO);
            evento.setDetalhe("Fora do perimetro");
            repo.save(evento);
            zona.setDentroDoPerimetro(false);
            zonas.save(zona);
            return new TelemetriaResultado(false, null);
        }

        boolean alertar = deveAlertar(zona.getUltimoAlertaEm(), agora, COOLDOWN_ALERTA_SEGUNDOS);
        boolean estavaDentro = zona.isDentroDoPerimetro();

        if (!alertar) {
            evento.setSituacao(EventoIot.DUPLICADO);
            evento.setDetalhe("Violacao ja alertada ha menos de "
                            + COOLDOWN_ALERTA_SEGUNDOS + "s");
            repo.save(evento);
            zona.setDentroDoPerimetro(true);
            zonas.save(zona);
            return new TelemetriaResultado(false, null);
        }

        DenunciaRequest pedido = new DenunciaRequest();
        pedido.setTipo("violencia");
        pedido.setDescricao(relatoDaViolacao(zona.getProcesso(), zona.getTornozeleira(), estavaDentro));
        pedido.setEstado("SP");
        pedido.setCidade("Barueri");
        pedido.setEndereco(null);       // o endereco da pessoa protegida nao entra no caso
        pedido.setAnonimo(true);

        Denuncia criada = denuncias.registrar(pedido);

        evento.setSituacao(EventoIot.ACEITO);
        evento.setProtocoloGerado(criada.getProtocolo());
        evento.setDetalhe(motivoDoAlerta(estavaDentro) + "; caso aberto com urgencia "
                        + criada.getUrgenciaIa());
        EventoIot salvo = repo.save(evento);

        zona.setDentroDoPerimetro(true);
        zona.setUltimoAlertaEm(agora);
        zonas.save(zona);

        auditoria.registrar(AuditoriaService.ALTERACAO_DADOS, "ZonaExclusao",
                            String.valueOf(zona.getId()));
        return new TelemetriaResultado(true, salvo.getProtocoloGerado());
    }

    /** Resultado interno do processamento de uma leitura de telemetria. */
    public record TelemetriaResultado(boolean alertaAberto, String protocolo) {}

    // ------------------------------------------------------------------
    //  Origem C: totem publico
    // ------------------------------------------------------------------

    /**
     * Normaliza o texto digitado no totem.
     *
     * Um teclado de saguao produz coisas que um formulario web nao produz:
     * teclas presas, quebras de linha do leitor de tela, caracteres de
     * controle de teclados fisicos. Nada disso muda o sentido do relato e
     * tudo isso atrapalha quem vai ler. O texto e reduzido a espacos simples
     * e cortado no limite, em vez de recusado por tamanho, porque recusar um
     * relato longo demais seria pedir que a pessoa reescreva de pe, na fila.
     */
    public static String higienizarRelato(String bruto) {
        if (bruto == null) return "";
        String limpo = bruto.replaceAll("[\\p{Cntrl}]", " ")
                            .replaceAll("\\s+", " ")
                            .trim();
        return limpo.length() > RELATO_MAXIMO ? limpo.substring(0, RELATO_MAXIMO).trim() : limpo;
    }

    /** Um relato so e aproveitavel quando descreve alguma coisa. */
    public static boolean relatoAceitavel(String bruto) {
        return higienizarRelato(bruto).length() >= RELATO_MINIMO;
    }

    /**
     * Tipo declarado na tela, reduzido ao vocabulario do dominio.
     *
     * O totem nao e uma fonte confiavel de categoria: o valor chega de um
     * cliente que pode ser alterado. Em vez de recusar o registro por causa
     * de um campo de classificacao, o que perderia o relato de uma pessoa por
     * um detalhe de metadado, um tipo desconhecido vira 'outros' e o VigIA
     * classifica a urgencia pelo texto, como faz com qualquer denuncia.
     */
    public static String tipoValido(String tipo) {
        if (tipo == null) return "outros";
        String t = tipo.trim().toLowerCase(Locale.ROOT);
        return TIPOS.contains(t) ? t : "outros";
    }

    /**
     * Monta a descricao do caso aberto por um totem.
     *
     * O local da instalacao entra no texto, e o relato da pessoa entra
     * inteiro e sem parafrase. Reescrever o que a pessoa digitou seria
     * substituir a palavra dela pela palavra do sistema, e e a palavra dela
     * que o atendimento precisa ler.
     */
    public static String relatoDoTotem(String local, String texto) {
        return "Registro feito em totem de atendimento publico, em " + local + ". "
             + "Relato da pessoa: " + higienizarRelato(texto) + " "
             + "Registro anonimo por natureza do equipamento: o totem nao pede identificacao.";
    }

    @Transactional
    public TotemResultado registrarTotem(RegistroTotemRequest req) {
        LocalDateTime agora = LocalDateTime.now().truncatedTo(ChronoUnit.MILLIS);

        Optional<PontoTotem> achado = totens.findByDispositivoAndAtivoTrue(req.getDispositivo());
        if (achado.isEmpty()) {
            EventoIot recusado = new EventoIot(EventoIot.TOTEM, req.getDispositivo());
            recusado.setRecebidoEm(agora);
            recusado.setSituacao(EventoIot.DESCARTADO);
            recusado.setDetalhe("Totem desconhecido ou desativado");
            repo.save(recusado);
            return TotemResultado.recusado("Este totem nao esta habilitado. Procure o atendimento.");
        }

        PontoTotem ponto = achado.get();

        if (!relatoAceitavel(req.getRelato())) {
            // O evento recusado e gravado sem o texto: um relato curto demais
            // nao abre caso, e guardar o fragmento seria guardar um dado
            // sensivel que nao serve para nada.
            EventoIot curto = new EventoIot(EventoIot.TOTEM, req.getDispositivo());
            curto.setLatitude(ponto.getLatitude());
            curto.setLongitude(ponto.getLongitude());
            curto.setRecebidoEm(agora);
            curto.setSituacao(EventoIot.DESCARTADO);
            curto.setDetalhe("Relato com menos de " + RELATO_MINIMO + " caracteres");
            repo.save(curto);
            return TotemResultado.recusado("Escreva um pouco mais sobre o que aconteceu.");
        }

        EventoIot evento = new EventoIot(EventoIot.TOTEM, req.getDispositivo());
        evento.setLatitude(ponto.getLatitude());
        evento.setLongitude(ponto.getLongitude());
        evento.setRecebidoEm(agora);

        Optional<EventoIot> ultimo = repo
                .findFirstByDispositivoAndSituacaoOrderByRecebidoEmDesc(
                        req.getDispositivo(), EventoIot.ACEITO);

        if (ultimo.isPresent()
                && ehRepique(ultimo.get().getRecebidoEm(), agora, JANELA_REPIQUE_TOTEM_SEGUNDOS)) {
            evento.setSituacao(EventoIot.DUPLICADO);
            evento.setProtocoloGerado(ultimo.get().getProtocoloGerado());
            evento.setDetalhe("Reenvio dentro de " + JANELA_REPIQUE_TOTEM_SEGUNDOS
                            + "s; vinculado ao mesmo caso");
            repo.save(evento);
            return TotemResultado.duplicado(ultimo.get().getProtocoloGerado());
        }

        DenunciaRequest pedido = new DenunciaRequest();
        pedido.setTipo(tipoValido(req.getTipo()));
        pedido.setDescricao(relatoDoTotem(ponto.getLocal(), req.getRelato()));
        pedido.setEstado(ponto.getEstado());
        pedido.setCidade(ponto.getCidade());
        pedido.setEndereco(ponto.getLocal());
        pedido.setAnonimo(true);

        Denuncia criada = denuncias.registrar(pedido);

        evento.setSituacao(EventoIot.ACEITO);
        evento.setProtocoloGerado(criada.getProtocolo());
        evento.setDetalhe("Registro em totem " + ponto.getLocal()
                        + "; caso aberto com urgencia " + criada.getUrgenciaIa());
        EventoIot salvo = repo.save(evento);

        auditoria.registrar(AuditoriaService.ALTERACAO_DADOS, "EventoIot",
                            String.valueOf(salvo.getId()));
        return TotemResultado.aceito(criada.getProtocolo());
    }

    /** Resultado interno do processamento de um registro de totem. */
    public record TotemResultado(String protocolo, boolean duplicado, String recusa) {

        public static TotemResultado aceito(String protocolo) {
            return new TotemResultado(protocolo, false, null);
        }

        public static TotemResultado duplicado(String protocolo) {
            return new TotemResultado(protocolo, true, null);
        }

        public static TotemResultado recusado(String motivo) {
            return new TotemResultado(null, false, motivo);
        }

        public boolean foiRecusado() { return recusa != null; }
    }

    // ------------------------------------------------------------------
    //  Consulta para o painel
    // ------------------------------------------------------------------

    public List<EventoIot> ultimos(String origem, int quantidade) {
        int limite = Math.max(1, Math.min(quantidade, 200));
        String filtro = (origem == null || origem.isBlank()) ? null : origem.toUpperCase();
        return repo.listarPorOrigem(filtro, PageRequest.of(0, limite));
    }

    public long totalPorOrigem(String origem) {
        return repo.countByOrigem(origem);
    }

    public boolean autorizado(String chaveRecebida) {
        return chaveValida(chaveEsperada, chaveRecebida);
    }
}
