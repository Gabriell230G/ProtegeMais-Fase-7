package br.gov.protege.service;

import br.gov.protege.exception.ConflitoException;
import br.gov.protege.exception.RegraDeNegocioException;

import java.util.List;

/**
 * Fase 7 | Maquina de estados do caso.
 *
 * Ate aqui qualquer perfil podia levar o caso de qualquer etapa para
 * qualquer outra, inclusive tirar um caso de "concluida" sem registro de que
 * aquilo era uma reabertura. As regras agora sao:
 *
 *  - avancar no fluxo (inclusive pulando etapa) e livre para quem trabalha o
 *    caso, como o Kanban faz ao arrastar o card para a direita;
 *  - pedir a etapa em que o caso ja esta nao muda nada;
 *  - voltar uma etapa, ou reabrir um caso concluido, e decisao de
 *    coordenacao: so GESTOR e ADMIN. Para os demais a resposta e 409.
 *
 * Classe pura, sem Spring, para ser testada diretamente.
 */
public final class FluxoStatus {

    private FluxoStatus() { }

    /** Fluxo oficial, na ordem das etapas. A posicao define avanco e retorno. */
    public static final List<String> ETAPAS = List.of("recebida", "analise", "encaminhada", "concluida");

    /** Etapa final: sair dela e reabrir o caso. */
    public static final String FINAL = "concluida";

    /** Sentido de uma mudanca de status. */
    public enum Transicao { MESMA, AVANCO, RETORNO }

    /**
     * Classifica a mudanca pela posicao das etapas. Status atual desconhecido
     * (dado antigo ou nulo) conta como anterior a primeira etapa.
     *
     * @throws RegraDeNegocioException quando o status pedido nao existe
     */
    public static Transicao classificar(String atual, String novo) {
        if (novo == null || !ETAPAS.contains(novo)) {
            throw new RegraDeNegocioException("Status invalido: " + novo);
        }
        // List.of nao aceita indexOf(null): o nulo e tratado antes.
        int de = atual == null ? -1 : ETAPAS.indexOf(atual);
        int para = ETAPAS.indexOf(novo);
        if (de == para) return Transicao.MESMA;
        return para > de ? Transicao.AVANCO : Transicao.RETORNO;
    }

    /**
     * Decide se a mudanca e aplicada.
     *
     * @param podeRetroceder verdadeiro para GESTOR e ADMIN
     * @return verdadeiro quando a mudanca deve ser aplicada; falso quando o
     *         caso ja esta na etapa pedida (nada a fazer)
     * @throws ConflitoException (409) para retorno ou reabertura sem perfil
     */
    public static boolean validar(String atual, String novo, boolean podeRetroceder) {
        Transicao t = classificar(atual, novo);
        if (t == Transicao.MESMA) return false;
        if (t == Transicao.RETORNO && !podeRetroceder) {
            throw new ConflitoException(FINAL.equals(atual)
                    ? "Reabrir um caso concluido e atribuicao do GESTOR ou do ADMIN ("
                      + atual + " -> " + novo + ")"
                    : "Devolver o caso a uma etapa anterior e atribuicao do GESTOR ou do ADMIN ("
                      + atual + " -> " + novo + ")");
        }
        return true;
    }
}
