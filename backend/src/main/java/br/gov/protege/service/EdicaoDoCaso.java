package br.gov.protege.service;

import br.gov.protege.dto.DenunciaRequest;
import br.gov.protege.model.Denuncia;
import br.gov.protege.util.MascaraUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Fase 7 | Regras da edicao de um caso pelo orgao (PUT).
 *
 *  1. O relato (descricao) e a escolha de anonimato sao a palavra de quem
 *     denunciou. O orgao nao os reescreve: o valor recebido e ignorado e a
 *     trilha registra que houve a tentativa. Antes, um PUT trocava o relato e
 *     o texto original sumia sem rastro.
 *  2. Quem nao ve o endereco (ATENDENTE) recebe o marcador de protecao no
 *     lugar dele, e o formulario devolve o marcador ou vazio. Nenhum dos dois
 *     pode apagar o endereco real gravado. O marcador tambem nunca e gravado,
 *     venha de quem vier.
 *
 * O resultado lista os NOMES dos campos alterados e ignorados, nunca os
 * valores, para entrar no detalhe da trilha de auditoria.
 *
 * Classe pura, sem banco e sem Spring, para ser testada diretamente.
 */
public final class EdicaoDoCaso {

    private EdicaoDoCaso() { }

    /** Campos alterados e campos recebidos mas ignorados. */
    public record Edicao(List<String> alterados, List<String> ignorados) {

        /** Texto para a trilha de auditoria: so nomes de campo. */
        public String resumo() {
            String r = alterados.isEmpty() ? "Nenhum campo alterado"
                                           : "Campos alterados: " + String.join(", ", alterados);
            if (!ignorados.isEmpty()) {
                r += "; ignorados (registro original do denunciante preservado): "
                   + String.join(", ", ignorados);
            }
            return r;
        }
    }

    /**
     * Aplica a edicao sobre o caso e devolve o que mudou.
     *
     * @param podeVerIdentidade falso para o perfil que recebe o endereco
     *                          mascarado (ATENDENTE)
     */
    public static Edicao aplicar(Denuncia d, DenunciaRequest req, boolean podeVerIdentidade) {
        List<String> alterados = new ArrayList<>();
        List<String> ignorados = new ArrayList<>();

        if (!Objects.equals(d.getTipo(), req.getTipo())) {
            d.setTipo(req.getTipo());
            alterados.add("tipo");
        }
        String estado = req.getEstado() == null ? null : req.getEstado().toUpperCase();
        if (!Objects.equals(d.getEstado(), estado)) {
            d.setEstado(estado);
            alterados.add("estado");
        }
        if (!Objects.equals(d.getCidade(), req.getCidade())) {
            d.setCidade(req.getCidade());
            alterados.add("cidade");
        }

        String endereco = req.getEndereco();
        boolean marcador = endereco != null
                && endereco.trim().equalsIgnoreCase(MascaraUtil.ENDERECO_PROTEGIDO);
        boolean semValor = endereco == null || endereco.isBlank();
        boolean preservar = marcador || (!podeVerIdentidade && semValor);
        if (!preservar && !Objects.equals(d.getEndereco(), endereco)) {
            d.setEndereco(endereco);
            alterados.add("endereco");
        }

        if (req.getDescricao() != null && !Objects.equals(d.getDescricao(), req.getDescricao())) {
            ignorados.add("descricao");
        }
        if (req.isAnonimo() != d.isAnonimo()) {
            ignorados.add("anonimo");
        }

        d.setLocal(montarLocal(d.getCidade(), d.getEstado()));
        return new Edicao(alterados, ignorados);
    }

    /** "Cidade, UF", com as mesmas regras do registro. */
    static String montarLocal(String cidade, String estado) {
        if (cidade == null || cidade.isBlank()) return estado == null ? "" : estado;
        return estado == null || estado.isBlank() ? cidade : cidade + ", " + estado;
    }
}
