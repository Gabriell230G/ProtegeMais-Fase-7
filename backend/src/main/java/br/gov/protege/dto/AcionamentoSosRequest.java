package br.gov.protege.dto;

import jakarta.validation.constraints.*;

/**
 * Corpo enviado por um botao de panico fisico.
 *
 * O aparelho nao sabe quem e a pessoa e nao precisa saber. Ele informa o
 * proprio identificador, onde estava e quanta bateria tinha. Qualquer
 * campo alem disso seria dado que o dispositivo nao tem motivo para portar.
 */
public class AcionamentoSosRequest {

    @NotBlank(message = "O identificador do dispositivo e obrigatorio")
    @Size(max = 40)
    private String dispositivo;

    @NotNull(message = "A latitude e obrigatoria")
    @DecimalMin(value = "-90.0")  @DecimalMax(value = "90.0")
    private Double lat;

    @NotNull(message = "A longitude e obrigatoria")
    @DecimalMin(value = "-180.0") @DecimalMax(value = "180.0")
    private Double lng;

    @Min(0) @Max(100)
    private Integer bateria;

    /** Cidade e UF resolvidas pelo gateway do dispositivo, quando houver. */
    @Size(max = 60)  private String cidade;
    @Size(max = 2)   private String estado;

    public String getDispositivo() { return dispositivo; }
    public void setDispositivo(String dispositivo) { this.dispositivo = dispositivo; }

    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }

    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }

    public Integer getBateria() { return bateria; }
    public void setBateria(Integer bateria) { this.bateria = bateria; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
}
