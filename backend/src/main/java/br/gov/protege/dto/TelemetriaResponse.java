package br.gov.protege.dto;

/**
 * Resposta devolvida ao equipamento de monitoracao.
 *
 * Devolve o minimo: se a leitura foi aceita e o que o servidor decidiu. Nao
 * devolve a distancia ate a pessoa protegida nem o raio configurado. Um
 * aparelho que soubesse a distancia poderia ser usado para localizar quem a
 * medida existe para proteger, bastando andar e observar o numero cair.
 */
public record TelemetriaResponse(
        String situacao,
        boolean alertaAberto,
        String protocoloGerado) {

    public static TelemetriaResponse aceita(boolean alerta, String protocolo) {
        return new TelemetriaResponse("ACEITA", alerta, protocolo);
    }

    public static TelemetriaResponse semZona() {
        return new TelemetriaResponse("SEM_MEDIDA_ATIVA", false, null);
    }
}
