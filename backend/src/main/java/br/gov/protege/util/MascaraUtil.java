package br.gov.protege.util;

/**
 * Mascaramento de dados pessoais.
 *
 * Aplicado nas respostas da API conforme o perfil que consulta, para que
 * um perfil operacional trabalhe o caso sem receber dado de identificacao
 * que sua funcao nao exige (minimizacao - LGPD, art. 6, III).
 */
public final class MascaraUtil {

    private MascaraUtil() { }

    /** joao.silva@email.com -> j***a@email.com */
    public static String email(String valor) {
        if (vazio(valor) || !valor.contains("@")) return null;
        String[] partes = valor.split("@", 2);
        String nome = partes[0];
        if (nome.length() <= 2) return "***@" + partes[1];
        return nome.charAt(0) + "***" + nome.charAt(nome.length() - 1) + "@" + partes[1];
    }

    /** (11) 98765-4321 -> *******4321 (mantem apenas os 4 ultimos digitos) */
    public static String telefone(String valor) {
        if (vazio(valor)) return null;
        String digitos = valor.replaceAll("\\D", "");
        if (digitos.length() < 4) return "****";
        String fim = digitos.substring(digitos.length() - 4);
        return "*".repeat(Math.max(0, digitos.length() - 4)) + fim;
    }

    /**
     * Reduz o endereco a nada. Endereco exato so e exibido no detalhe
     * do caso, para perfis autorizados, e a leitura e auditada.
     */
    public static String endereco(String valor) {
        return vazio(valor) ? null : "[endereco protegido]";
    }

    // Padroes de dado pessoal que aparecem com frequencia no relato livre.
    // A ordem importa: CPF e CEP antes do telefone, para um numero com
    // pontuacao de CPF nao ser lido como celular. Sequencia de 11 digitos
    // sem pontuacao cai na regra de telefone: o rotulo pode errar, mas o
    // dado sai mascarado do mesmo jeito.
    private static final java.util.regex.Pattern EMAIL =
            java.util.regex.Pattern.compile("[\\w.+-]+@[\\w-]+(\\.[\\w-]+)+");
    private static final java.util.regex.Pattern CPF =
            java.util.regex.Pattern.compile("\\b\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}\\b");
    private static final java.util.regex.Pattern CEP =
            java.util.regex.Pattern.compile("\\b\\d{5}-\\d{3}\\b");
    private static final java.util.regex.Pattern TELEFONE =
            java.util.regex.Pattern.compile("(\\+?55\\s?)?(\\(?\\d{2}\\)?\\s?)?9?\\d{4}[-\\s]?\\d{4}\\b");
    private static final java.util.regex.Pattern LOGRADOURO =
            java.util.regex.Pattern.compile(
                "(?i)\\b(rua|r\\.|avenida|av\\.|travessa|alameda|estrada|rodovia|praca|praça)\\s+[^,.;\\n]{2,60}(,\\s*(n[ºo°.]?\\s*)?\\d+)?");

    /**
     * Fase 7 | Remove dado pessoal de um texto livre antes que ele saia do
     * servidor (por exemplo, para um servico de IA externo).
     *
     * E uma barreira por padrao conhecido, e nao uma garantia: nome proprio
     * nao e detectado. Por isso o envio do relato a IA externa continua
     * DESLIGADO por padrao (protege.vigia.enviar-relato=false) e, quando
     * ligado, passa sempre por aqui primeiro.
     */
    public static String textoLivre(String valor) {
        if (vazio(valor)) return valor;
        String t = EMAIL.matcher(valor).replaceAll("[email]");
        t = CPF.matcher(t).replaceAll("[cpf]");
        t = CEP.matcher(t).replaceAll("[cep]");
        t = LOGRADOURO.matcher(t).replaceAll("[endereco]");
        t = TELEFONE.matcher(t).replaceAll("[telefone]");
        return t;
    }

    private static boolean vazio(String s) {
        return s == null || s.isBlank();
    }
}
