package br.gov.protege.service;

import br.gov.protege.dto.DenunciaRequest;
import br.gov.protege.exception.RecursoNaoEncontradoException;
import br.gov.protege.exception.RegraDeNegocioException;
import br.gov.protege.model.AcaoReversivel;
import br.gov.protege.model.Denuncia;
import br.gov.protege.model.HistoricoItem;
import br.gov.protege.repository.DenunciaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.Year;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class DenunciaService {

    private final DenunciaRepository repo;
    private final ScoreService scoreService;
    private final VigiaService vigia;
    private final PilhaAcoesService pilha;

    private static final DateTimeFormatter DATA = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm");

    /** Fluxo oficial: nenhuma transicao pode pular etapas para tras sem registro. */
    private static final List<String> STATUS_VALIDOS =
            List.of("recebida", "analise", "encaminhada", "concluida");

    public DenunciaService(DenunciaRepository repo, ScoreService scoreService,
                           VigiaService vigia, PilhaAcoesService pilha) {
        this.repo = repo;
        this.scoreService = scoreService;
        this.vigia = vigia;
        this.pilha = pilha;
    }

    /** Registra uma nova denuncia: gera protocolo, score, analise de IA e historico. */
    @Transactional
    public Denuncia registrar(DenunciaRequest req) {
        Denuncia d = new Denuncia();
        aplicar(d, req);
        d.setStatus("recebida");
        d.setProtocolo(gerarProtocolo());
        d.setCriadoEm(LocalDateTime.now());

        calcularScoreEIa(d, req);
        d.getHistorico().add(novoPasso("recebida"));

        return repo.save(d);
    }

    /** Atualizacao completa do caso (PUT). Nao mexe em status nem protocolo. */
    @Transactional
    public Denuncia atualizar(Long id, DenunciaRequest req) {
        Denuncia d = buscarObrigatoria(id);
        aplicar(d, req);
        calcularScoreEIa(d, req);
        return repo.save(d);
    }

    public Page<Denuncia> listar(String status, String tipo, String estado, Pageable pageable) {
        return repo.buscarComFiltros(normalizar(status), normalizar(tipo), normalizar(estado), pageable);
    }

    public Denuncia buscarPorProtocolo(String protocolo) {
        String limpo = protocolo.trim().toUpperCase();
        String p = limpo.startsWith("#") ? limpo : "#" + limpo;
        return repo.findByProtocoloAndExcluidaFalse(p)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Denuncia", p));
    }

    public Denuncia buscarObrigatoria(Long id) {
        return repo.findByIdAndExcluidaFalse(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Denuncia", id));
    }

    /** Muda o status e registra o passo no historico. */
    @Transactional
    public Denuncia atualizarStatus(Long id, String novoStatus) {
        return atualizarStatus(id, novoStatus, null);
    }

    /**
     * Muda o status, registra o passo no historico e empilha a acao para
     * que o servidor possa desfazer um engano operacional (US21).
     */
    @Transactional
    public Denuncia atualizarStatus(Long id, String novoStatus, String usuario) {
        if (!STATUS_VALIDOS.contains(novoStatus)) {
            throw new RegraDeNegocioException("Status invalido: " + novoStatus);
        }
        Denuncia d = buscarObrigatoria(id);
        String anterior = d.getStatus();
        if (novoStatus.equals(anterior)) {
            throw new RegraDeNegocioException("A denuncia ja esta no status " + novoStatus);
        }

        aplicarStatus(d, novoStatus);
        Denuncia salva = repo.save(d);

        pilha.empilhar(usuario, new AcaoReversivel(
                salva.getId(), salva.getProtocolo(), anterior, novoStatus, LocalDateTime.now()));

        return salva;
    }

    /**
     * Desfaz a ultima mudanca de status feita por este servidor (PILHA, LIFO).
     *
     * Decisao de projeto: o historico NAO e reescrito. Desfazer nao apaga o
     * passo errado - acrescenta um passo novo restaurando o status anterior.
     * Num sistema publico, poder apagar a propria pegada anularia a
     * rastreabilidade exigida da administracao (US12).
     */
    @Transactional
    public Denuncia desfazerUltima(String usuario) {
        AcaoReversivel acao = pilha.desempilhar(usuario);
        if (acao == null) {
            throw new RegraDeNegocioException("Nao ha acao recente para desfazer");
        }
        Denuncia d = buscarObrigatoria(acao.denunciaId());
        aplicarStatus(d, acao.statusAnterior());
        return repo.save(d);
    }

    /** Atende o proximo caso da fila de prioridade, movendo-o para analise. */
    @Transactional
    public Denuncia atenderProximo(Denuncia proximo, String usuario) {
        if (proximo == null) {
            throw new RegraDeNegocioException("Nenhum caso aguardando atendimento");
        }
        if ("analise".equals(proximo.getStatus())) {
            return proximo;
        }
        return atualizarStatus(proximo.getId(), "analise", usuario);
    }

    private void aplicarStatus(Denuncia d, String status) {
        d.setStatus(status);
        d.getHistorico().add(novoPasso(status));
        d.setConcluidaEm("concluida".equals(status) ? LocalDateTime.now() : null);
    }

    /** Atribui um responsavel (usado no Kanban do gestor). */
    @Transactional
    public Denuncia atribuirResponsavel(Long id, Long responsavelId) {
        Denuncia d = buscarObrigatoria(id);
        d.setResponsavelId(responsavelId);
        return repo.save(d);
    }

    /**
     * Exclusao logica com anonimizacao do conteudo sensivel.
     *
     * O registro permanece para fins de estatistica e prestacao de contas,
     * mas o relato e o endereco - que sao o que expoe a vitima - sao
     * eliminados de fato. E o equilibrio entre o direito a eliminacao
     * (LGPD, art. 18, VI) e o dever de rastreabilidade do orgao publico.
     */
    @Transactional
    public void excluir(Long id, String motivo) {
        if (motivo == null || motivo.isBlank()) {
            throw new RegraDeNegocioException("A exclusao exige um motivo registrado");
        }
        Denuncia d = buscarObrigatoria(id);
        d.setExcluida(true);
        d.setMotivoExclusao(motivo);
        d.setExcluidaEm(LocalDateTime.now());
        d.setDescricao(null);
        d.setEndereco(null);
        d.setResumoIa(null);
        repo.save(d);
    }

    // ---------------------------------------------------------------
    private void aplicar(Denuncia d, DenunciaRequest req) {
        d.setTipo(req.getTipo());
        d.setDescricao(req.getDescricao());
        d.setEstado(req.getEstado() == null ? null : req.getEstado().toUpperCase());
        d.setCidade(req.getCidade());
        d.setEndereco(req.getEndereco());
        d.setAnonimo(req.isAnonimo());
        d.setLocal(montarLocal(req.getCidade(), d.getEstado()));
    }

    private void calcularScoreEIa(Denuncia d, DenunciaRequest req) {
        ScoreService.Resultado sc = scoreService.calcular(req);
        d.setScore(sc.score());
        d.setScoreLabel(sc.label());
        d.setScoreTxt(sc.txt());

        VigiaService.Analise ia = vigia.analisar(d);
        d.setUrgenciaIa(ia.urgencia());
        d.setResumoIa(ia.resumo());
        d.setOrigemAnalise(ia.origem() == null ? null : ia.origem().toUpperCase());
    }

    private HistoricoItem novoPasso(String status) {
        LocalDateTime agora = LocalDateTime.now();
        return new HistoricoItem(status, agora.format(DATA), agora.format(HORA));
    }

    private String montarLocal(String cidade, String estado) {
        if (cidade == null || cidade.isBlank()) return estado == null ? "" : estado;
        return estado == null || estado.isBlank() ? cidade : cidade + ", " + estado;
    }

    private String normalizar(String valor) {
        return (valor == null || valor.isBlank()) ? null : valor.trim();
    }

    /**
     * Protocolo publico, no formato #ANO-XXXX-XXXX-XXXX (Fase 7).
     *
     * Ate a Fase 6 o protocolo era #ANO-NNNNN: no maximo 99.999 valores por
     * ano, sorteados com um gerador previsivel. Como o protocolo e a unica
     * "senha" de quem denunciou anonimamente (consulta o caso e envia
     * evidencias com ele), adivinha-lo por tentativa era viavel.
     *
     * Agora sao 12 simbolos sorteados com SecureRandom num alfabeto de 31
     * caracteres sem os que se confundem (0/O, 1/I/L): cerca de 59 bits,
     * mais de 7 x 10^17 combinacoes. Com o limite de 30 consultas por minuto
     * por origem, varrer 1% do espaco levaria milhares de anos. Cabe nos
     * mesmos 20 caracteres da coluna, sem migracao de banco. Os protocolos
     * antigos da carga de demonstracao continuam validos.
     */
    static final String ALFABETO_PROTOCOLO = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
    private static final java.security.SecureRandom SORTEIO = new java.security.SecureRandom();

    static String novoProtocolo(int ano) {
        StringBuilder sb = new StringBuilder("#").append(ano);
        for (int i = 0; i < 12; i++) {
            if (i % 4 == 0) sb.append('-');
            sb.append(ALFABETO_PROTOCOLO.charAt(SORTEIO.nextInt(ALFABETO_PROTOCOLO.length())));
        }
        return sb.toString();
    }

    private String gerarProtocolo() {
        String proto;
        do {
            proto = novoProtocolo(Year.now().getValue());
        } while (repo.existsByProtocolo(proto));
        return proto;
    }
}
