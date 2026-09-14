package br.gov.protege.dto;

/**
 * Resposta devolvida ao totem.
 *
 * Devolve o protocolo, porque sem ele a pessoa perde o caso que acabou de
 * abrir, e devolve junto o numero de segundos que a tela pode exibi-lo. Um
 * protocolo e a chave de leitura da denuncia; num monitor de saguao ele fica
 * visivel para a fila inteira. Nao ha resposta boa para esse conflito, so a
 * menos ruim: mostrar, avisar que sera apagado, e apagar.
 */
public record RegistroTotemResponse(String protocolo,
                                    boolean duplicado,
                                    int segundosParaLimpar,
                                    String mensagem) {

    public static RegistroTotemResponse aceito(String protocolo, int segundos) {
        return new RegistroTotemResponse(protocolo, false, segundos,
                "Registro recebido. Anote o protocolo: ele sera apagado desta tela em "
                + segundos + " segundos.");
    }

    public static RegistroTotemResponse duplicado(String protocolo, int segundos) {
        return new RegistroTotemResponse(protocolo, true, segundos,
                "Este registro ja havia sido enviado. O protocolo e o mesmo.");
    }
}
