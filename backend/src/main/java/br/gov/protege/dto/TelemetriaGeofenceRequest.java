package br.gov.protege.dto;

import jakarta.validation.constraints.*;

/**
 * Posicao informada por um equipamento de monitoracao eletronica.
 *
 * O corpo nao tem raio, nem coordenada da pessoa protegida, nem campo para
 * o aparelho declarar que houve violacao. Ele informa onde esta, e so. A
 * avaliacao do perimetro acontece no servidor, com o dado que o servidor ja
 * tem, porque um aparelho que avalia a propria conformidade nao serve para
 * fiscalizar ninguem.
 */
public class TelemetriaGeofenceRequest {

    @NotBlank(message = "O identificador do equipamento e obrigatorio")
    @Size(max = 40)
    private String tornozeleira;

    @NotNull(message = "A latitude e obrigatoria")
    @DecimalMin(value = "-90.0")  @DecimalMax(value = "90.0")
    private Double lat;

    @NotNull(message = "A longitude e obrigatoria")
    @DecimalMin(value = "-180.0") @DecimalMax(value = "180.0")
    private Double lng;

    @Min(0) @Max(100)
    private Integer bateria;

    public String getTornozeleira() { return tornozeleira; }
    public void setTornozeleira(String tornozeleira) { this.tornozeleira = tornozeleira; }

    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }

    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }

    public Integer getBateria() { return bateria; }
    public void setBateria(Integer bateria) { this.bateria = bateria; }
}
