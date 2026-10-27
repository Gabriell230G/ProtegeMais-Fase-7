package br.gov.protege.util;

/**
 * Fase 7 | Neutraliza quebras de linha em valores que vieram do cliente
 * antes de irem para o log ou para a trilha de auditoria.
 *
 * Um User-Agent ou uma mensagem de erro com "\n" dentro escreveria uma
 * linha inteira forjada no log ("log injection"): quem le o arquivo depois
 * nao distingue a linha falsa de uma verdadeira. Os caracteres de controle
 * viram "_", e o resto do texto fica como veio.
 */
public final class LogSeguro {

    private LogSeguro() { }

    public static String limpar(Object valor) {
        if (valor == null) return null;
        String s = String.valueOf(valor);
        StringBuilder sb = null;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (Character.isISOControl(c) || c == '\u2028' || c == '\u2029') {
                if (sb == null) sb = new StringBuilder(s.length()).append(s, 0, i);
                sb.append('_');
            } else if (sb != null) {
                sb.append(c);
            }
        }
        return sb == null ? s : sb.toString();
    }
}
