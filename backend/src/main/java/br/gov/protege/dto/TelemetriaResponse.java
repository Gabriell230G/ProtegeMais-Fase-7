package br.gov.protege.dto;

/**
 * Resposta devolvida ao equipamento de monitoracao.
 *
 * Devolve o minimo: se a leitura foi aceita e o que o servidor decidiu. Nao
 * devolve a distancia ate a pessoa protegida nem o raio configurado. Um
 * aparelho que soubesse a distancia poderia ser usado para localizar quem a
 * medida existe para proteger, bastando andar e observar o numero cair.
 *
 * Fase 7 | Pelo mesmo motivo sairam o "alertaAberto" e o protocolo gerado.
 * O booleano dizia, leitura a leitura, se a coordenada enviada estava DENTRO
 * do perimetro: bastava varrer coordenadas para desenhar a regiao protegida.
 * Tambem nao ha situacao "duplicada" aqui, porque ela so ocorre dentro do
 * perimetro (violacao ja alertada) e vazaria a mesma informacao. O alerta,
 * o caso aberto e o repique continuam acontecendo no servidor e aparecem no
 * painel do orgao; o aparelho so fica sabendo se a leitura foi recebida.
 */
public record TelemetriaResponse(String situacao) {

    /** Leitura recebida e avaliada (fora, dentro ou repetida: o aparelho nao sabe). */
    public static TelemetriaResponse aceita() {
        return new TelemetriaResponse("ACEITA");
    }

    /** Equipamento sem medida protetiva ativa vinculada. */
    public static TelemetriaResponse descartada() {
        return new TelemetriaResponse("DESCARTADA");
    }
}
