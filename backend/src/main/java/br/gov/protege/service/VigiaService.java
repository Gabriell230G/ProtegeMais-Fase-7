package br.gov.protege.service;

import br.gov.protege.model.Denuncia;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * VigIA - copiloto de IA do gestor.
 *
 * Se houver uma GEMINI_API_KEY configurada, usa o modelo Gemini do Google
 * para classificar a urgencia da denuncia, gerar um resumo objetivo e
 * responder perguntas do gestor. Sem a chave, cai para uma analise por
 * regras (explicavel) - garantindo que a demo funcione sempre (plano B).
 */
@Service
public class VigiaService {

    private final String apiKey;
    private final String model;
    private final String baseUrl;
    private final boolean enviarRelato;
    private final RestClient http;
    private final ObjectMapper mapper = new ObjectMapper();

    /** Construtor curto, usado pelos testes: relato nunca sai, tempo limite padrao. */
    public VigiaService(String apiKey, String model, String baseUrl) {
        this(apiKey, model, baseUrl, false, 15000);
    }

    /**
     * Fase 7 | Duas protecoes novas.
     *
     * 1. enviarRelato (padrao false): o texto do relato NAO e enviado ao
     *    servico externo. A IA recebe so o tipo e o municipio; a leitura do
     *    relato fica com as regras locais. Ligando a opcao, o relato sai
     *    sempre mascarado por MascaraUtil.textoLivre. Isso torna verdadeira,
     *    no codigo, a promessa "nenhum relato sai do sistema".
     *
     * 2. tempoLimiteMs (padrao 15 s): a chamada ao Gemini tinha espera indefinida. Se o
     *    servico externo travasse, a tela do gestor travava junto. Agora,
     *    passado o limite, cai para a analise por regras.
     */
    @org.springframework.beans.factory.annotation.Autowired
    public VigiaService(
            @Value("${gemini.api.key:}") String apiKey,
            @Value("${gemini.api.model:gemini-2.5-flash}") String model,
            @Value("${gemini.api.url}") String baseUrl,
            @Value("${protege.vigia.enviar-relato:false}") boolean enviarRelato,
            @Value("${protege.vigia.tempo-limite-ms:15000}") int tempoLimiteMs) {
        this.apiKey = apiKey;
        this.model = model;
        this.baseUrl = baseUrl;
        this.enviarRelato = enviarRelato;
        org.springframework.http.client.SimpleClientHttpRequestFactory fabrica =
                new org.springframework.http.client.SimpleClientHttpRequestFactory();
        fabrica.setConnectTimeout(tempoLimiteMs);
        fabrica.setReadTimeout(tempoLimiteMs);
        this.http = RestClient.builder().requestFactory(fabrica).build();
    }

    /** Informa se o relato pode sair do servidor (mascarado). Exposto no status. */
    public boolean enviaRelato() {
        return enviarRelato;
    }

    public boolean iaAtiva() {
        return apiKey != null && !apiKey.isBlank();
    }

    public record Analise(String urgencia, String resumo, String origem) {}

    /**
     * Fase 7 | Conjunto fechado de urgencias, da mais grave para a mais leve.
     * A posicao na lista e a ordem de gravidade.
     */
    static final List<String> URGENCIAS = List.of("CRITICA", "ALTA", "MEDIA", "BAIXA");

    /** Tamanho da coluna resumo_ia: resposta maior nao pode derrubar a gravacao. */
    static final int RESUMO_MAXIMO = 2000;

    /**
     * Classifica urgencia e resume uma denuncia.
     *
     * Fase 7 | A saida do modelo deixou de ser confiada como veio:
     *  - a urgencia e normalizada (sem acento, maiuscula) e so vale se for
     *    uma das quatro conhecidas; fora disso, vale a analise por regras;
     *  - as regras sao o PISO: a urgencia final e a mais grave entre a das
     *    regras e a do modelo. Um texto que tente convencer o modelo a
     *    rebaixar o caso (injecao de prompt) nao o deixa abaixo do que as
     *    regras ja identificaram;
     *  - o resumo e cortado no tamanho da coluna.
     */
    public Analise analisar(Denuncia d) {
        Analise regras = analisePorRegras(d);
        if (iaAtiva()) {
            try {
                String prompt = """
                    Voce e um analista de um canal publico de denuncias.
                    Classifique a URGENCIA desta denuncia em uma unica palavra
                    (CRITICA, ALTA, MEDIA ou BAIXA) e escreva um RESUMO objetivo
                    de no maximo 2 frases para o gestor. Responda em JSON puro,
                    sem markdown, no formato:
                    {"urgencia":"...","resumo":"..."}

                    Tipo: %s
                    Local: %s
                    Relato: %s
                    """.formatted(nz(d.getTipo()), nz(d.getLocal()), relatoParaIa(d));

                Analise doModelo = combinar(regras, chamarGemini(prompt));
                if (doModelo != null) return doModelo;
            } catch (Exception e) {
                // cai para as regras
            }
        }
        return regras;
    }

    /**
     * Fase 7 | Interpreta a resposta do modelo e aplica o piso das regras.
     * Devolve null quando a resposta nao serve (JSON invalido ou urgencia
     * fora do conjunto), para quem chamou usar as regras.
     */
    Analise combinar(Analise regras, String textoDoModelo) {
        if (textoDoModelo == null) return null;
        try {
            String limpo = textoDoModelo.replaceAll("(?s)```json|```", "").trim();
            JsonNode json = mapper.readTree(limpo);
            if (json == null) return null;
            String urgenciaModelo = normalizarUrgencia(json.path("urgencia").asText(""));
            if (urgenciaModelo == null) return null;
            return new Analise(maisGrave(regras.urgencia(), urgenciaModelo),
                               truncar(json.path("resumo").asText(""), RESUMO_MAXIMO),
                               "gemini");
        } catch (Exception e) {
            return null;
        }
    }

    /** "Crítica " vira "CRITICA"; valor fora do conjunto fechado vira null. */
    static String normalizarUrgencia(String bruto) {
        if (bruto == null) return null;
        String u = Normalizer.normalize(bruto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .trim()
                .toUpperCase(Locale.ROOT);
        return URGENCIAS.contains(u) ? u : null;
    }

    /** A mais grave das duas; valor desconhecido nunca vence um conhecido. */
    static String maisGrave(String a, String b) {
        int ia = a == null ? -1 : URGENCIAS.indexOf(a);
        int ib = b == null ? -1 : URGENCIAS.indexOf(b);
        if (ia < 0) return ib < 0 ? "MEDIA" : b;
        if (ib < 0) return a;
        return ia <= ib ? a : b;
    }

    static String truncar(String texto, int maximo) {
        if (texto == null) return null;
        return texto.length() <= maximo ? texto : texto.substring(0, maximo);
    }

    /** Responde uma pergunta livre do gestor sobre o panorama das denuncias. */
    public String perguntar(String pergunta, String contexto) {
        if (iaAtiva()) {
            try {
                String prompt = """
                    Voce e o VigIA, assistente do gestor publico no sistema Protege+.
                    Seja direto, pratico e cite numeros quando houver.
                    Contexto (denuncias atuais):
                    %s

                    Pergunta do gestor: %s
                    """.formatted(nz(contexto), nz(pergunta));
                return chamarGemini(prompt).trim();
            } catch (Exception e) {
                return "Nao consegui consultar a IA agora. " + resumoRegras(contexto);
            }
        }
        return resumoRegras(contexto);
    }

    // ---------------------------------------------------------------
    //  Chamada HTTP ao Gemini
    // ---------------------------------------------------------------
    /**
     * O que a IA externa pode ler do relato. Por padrao, nada: so a
     * indicacao de que ele existe. Com a opcao ligada, a versao mascarada.
     */
    String relatoParaIa(Denuncia d) {
        if (!enviarRelato) {
            return "(nao enviado: o relato nao sai do servidor; classifique apenas pelo tipo e local)";
        }
        String mascarado = br.gov.protege.util.MascaraUtil.textoLivre(nz(d.getDescricao()));
        return mascarado.length() > 1500 ? mascarado.substring(0, 1500) : mascarado;
    }

    private String chamarGemini(String prompt) {
        // Fase 7 | A chave saiu da URL. Endereco com ?key= fica gravado em log
        // de proxy, de servidor e de ferramenta de monitoramento; cabecalho nao.
        String url = baseUrl + "/" + model + ":generateContent";

        Map<String, Object> conteudo = Map.of(
                "contents", List.of(Map.of(
                        "parts", List.of(Map.of("text", prompt)))));
        // Os modelos 2.5 "pensam" antes de responder por padrao, o que pode
        // passar do tempo limite. Para classificar e resumir nao e preciso.
        Map<String, Object> body = model != null && model.startsWith("gemini-2.5-flash")
                ? Map.of("contents", conteudo.get("contents"),
                         "generationConfig", Map.of("thinkingConfig", Map.of("thinkingBudget", 0)))
                : conteudo;

        JsonNode resp = http.post()
                .uri(url)
                .header("Content-Type", "application/json")
                .header("x-goog-api-key", apiKey)
                .body(body)
                .retrieve()
                .body(JsonNode.class);

        return resp.path("candidates").path(0)
                .path("content").path("parts").path(0)
                .path("text").asText("");
    }

    // ---------------------------------------------------------------
    //  Fallback por regras (explicavel, sempre funciona)
    // ---------------------------------------------------------------
    private static final Map<String, Integer> GRAVIDADE = Map.of(
            "violencia", 5, "abuso", 5, "assedio", 3, "discriminacao", 3, "outros", 2);

    private Analise analisePorRegras(Denuncia d) {
        int g = GRAVIDADE.getOrDefault(nz(d.getTipo()).toLowerCase(), 2);
        String desc = nz(d.getDescricao()).toLowerCase();
        boolean palavrasCriticas = desc.matches(".*(arma|faca|agora|socorro|ameaca|ameaç|sangue|espancad|refem|refém).*");

        String urgencia;
        if (g >= 5 && palavrasCriticas)      urgencia = "CRITICA";
        else if (g >= 5)                      urgencia = "ALTA";
        else if (g >= 3 || palavrasCriticas)  urgencia = "MEDIA";
        else                                  urgencia = "BAIXA";

        String resumo = "Denuncia de " + nz(d.getTipo()) + " em " + nz(d.getLocal())
                + ". Classificada como " + urgencia + " pela analise de regras do VigIA"
                + (palavrasCriticas ? " (termos de risco identificados no relato)." : ".");

        return new Analise(urgencia, resumo, "regras");
    }

    private String resumoRegras(String contexto) {
        return "Com base nos dados atuais, priorize denuncias de violencia e abuso, "
             + "e as que estao paradas ha mais tempo. Detalhe: " + nz(contexto);
    }

    private String nz(String s) { return s == null ? "" : s; }
}
