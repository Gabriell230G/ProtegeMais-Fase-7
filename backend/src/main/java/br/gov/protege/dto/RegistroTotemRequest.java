package br.gov.protege.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * O que um totem publico envia.
 *
 * Repare no que NAO esta aqui: nao ha latitude, nao ha longitude, nao ha nome
 * e nao ha contato. O lugar vem do cadastro da instalacao, e a identificacao
 * nao e pedida porque quem usa um totem esta de pe num saguao, com a fila
 * atras. Pedir nome ali seria pedir que a pessoa se identifique em voz alta
 * diante de quem estiver esperando a vez.
 */
public class RegistroTotemRequest {

    @NotBlank(message = "O identificador do totem e obrigatorio")
    @Size(max = 40)
    private String dispositivo;

    @Size(max = 30)
    private String tipo;

    /**
     * Teto largo de proposito. O corte util do relato acontece no servico,
     * que reduz o texto ao limite de gravacao em vez de recusar a pessoa.
     * Este limite aqui existe so para barrar um corpo absurdo antes que ele
     * consuma memoria, e nao para dizer a alguem que escreveu demais.
     */
    @Size(max = 8000)
    private String relato;

    public String getDispositivo() { return dispositivo; }
    public void setDispositivo(String dispositivo) { this.dispositivo = dispositivo; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getRelato() { return relato; }
    public void setRelato(String relato) { this.relato = relato; }
}
