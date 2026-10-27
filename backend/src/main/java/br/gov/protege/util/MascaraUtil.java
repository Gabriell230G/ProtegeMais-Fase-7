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
     * Fase 7 | Marcador devolvido no lugar do endereco. Publico porque o PUT
     * precisa reconhece-lo: quando ele volta do formulario, o endereco real
     * gravado e mantido.
     */
    public static final String ENDERECO_PROTEGIDO = "[endereco protegido]";

    /**
     * Reduz o endereco a nada. Endereco exato so e exibido no detalhe
     * do caso, para perfis autorizados, e a leitura e auditada.
     */
    public static String endereco(String valor) {
        return vazio(valor) ? null : ENDERECO_PROTEGIDO;
    }

    // Padroes de dado pessoal que aparecem com frequencia no relato livre.
    // A ordem importa: CPF e CEP antes do telefone, para um numero com
    // pontuacao de CPF nao ser lido como celular. Sequencia de 11 digitos
    // sem pontuacao cai na regra de telefone: o rotulo pode errar, mas o
    // dado sai mascarado do mesmo jeito.
    //
    // Fase 7 | Os quantificadores sao limitados e possessivos ({1,64}+, ++).
    // A versao anterior do EMAIL repetia um grupo sem limite, e o motor de
    // regex do Java empilha uma chamada por repeticao: um texto como
    // "a@a.a.a.a..." com alguns milhares de caracteres derrubava a thread com
    // StackOverflowError. Possessivo nao devolve caracteres para tentar de
    // novo, entao o custo por posicao fica constante.
    private static final java.util.regex.Pattern EMAIL =
            java.util.regex.Pattern.compile("[\\w.+-]{1,64}+@[\\w-]{1,63}+(?:\\.[\\w-]{1,63}+){1,8}+");
    private static final java.util.regex.Pattern CPF =
            java.util.regex.Pattern.compile("\\b\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}\\b");
    private static final java.util.regex.Pattern CEP =
            java.util.regex.Pattern.compile("\\b\\d{5}-\\d{3}\\b");
    // Todos os quantificadores ja sao limitados (?, {2}, {4}): custo constante por posicao.
    private static final java.util.regex.Pattern TELEFONE =
            java.util.regex.Pattern.compile("(\\+?55\\s?)?(\\(?\\d{2}\\)?\\s?)?9?\\d{4}[-\\s]?\\d{4}\\b");
    // Fase 7 | "\\s++" e "\\d{1,6}" no lugar de "\\s+" e "\\d+": o espaco
    // depois do tipo de logradouro nao e mais devolvido para a classe
    // seguinte (que tambem aceita espaco), o que multiplicava as tentativas.
    private static final java.util.regex.Pattern LOGRADOURO =
            java.util.regex.Pattern.compile(
                "(?i)\\b(rua|r\\.|avenida|av\\.|travessa|alameda|estrada|rodovia|praca|pra\u00e7a)\\s++[^,.;\\n]{2,60}(,\\s*+(n[\u00bao\u00b0.]?\\s*+)?\\d{1,6})?");

    /**
     * Fase 7 | Teto do texto processado. O relato aceito pela API tem ate
     * 4000 caracteres; o teto protege qualquer chamador futuro que passe um
     * texto maior. O que passa do teto e descartado, e nao devolvido sem
     * mascara.
     */
    static final int MAXIMO_TEXTO_LIVRE = 5000;

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
        String t = valor.length() > MAXIMO_TEXTO_LIVRE ? valor.substring(0, MAXIMO_TEXTO_LIVRE) : valor;
        t = EMAIL.matcher(t).replaceAll("[email]");
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
