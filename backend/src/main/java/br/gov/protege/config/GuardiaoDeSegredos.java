package br.gov.protege.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Fase 7 | Guardiao de segredos.
 *
 * Ate a Fase 6, o application.properties trazia valores padrao CONHECIDOS
 * para o segredo do token (JWT), para a chave dos dispositivos IoT e para a
 * senha do administrador. Quem lesse o repositorio publico conseguia
 * fabricar um token de ADMIN valido sempre que a variavel de ambiente nao
 * fosse definida, e o sistema subia normalmente assim.
 *
 * Esta classe roda ANTES de qualquer bean ser criado e decide entre dois
 * modos, pela propriedade protege.demo (variavel PROTEGE_DEMO):
 *
 *  MODO DEMONSTRACAO (padrao, true): o projeto continua funcionando ao ser
 *  descompactado, como a comanda exige. Mas os segredos ausentes deixam de
 *  ser fixos: sao sorteados a cada execucao com SecureRandom. O segredo do
 *  JWT existe so na memoria (tokens antigos morrem ao reiniciar, o que e o
 *  comportamento desejado). A chave IoT sorteada e gravada em
 *  ./data/iot-chave.txt para o operador colar no simulador.
 *
 *  MODO PRODUCAO (false): falha rapido. Se o segredo do JWT, a senha do
 *  administrador ou a chave IoT nao forem informados, ou forem fracos, o
 *  sistema se recusa a subir e diz exatamente o que falta. O console do H2
 *  e desligado a forca.
 *
 * Registrada em META-INF/spring.factories.
 */
public class GuardiaoDeSegredos implements EnvironmentPostProcessor {

    static final String FONTE = "protege-guardiao-de-segredos";
    static final int MIN_JWT = 32;
    static final int MIN_SENHA = 12;
    static final int MIN_IOT = 16;

    private static final SecureRandom SORTEIO = new SecureRandom();

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment env, SpringApplication app) {
        boolean demo = Boolean.parseBoolean(env.getProperty("protege.demo", "true"));
        Map<String, Object> definidos = new HashMap<>();

        String jwt = env.getProperty("jwt.secret", "");
        String iot = env.getProperty("protege.iot.chave", "");
        String senha = env.getProperty("app.admin.senha", "");

        if (demo) {
            if (jwt.isBlank()) definidos.put("jwt.secret", sortear(48));
            if (iot.isBlank()) {
                String chave = "iot-" + sortear(18);
                definidos.put("protege.iot.chave", chave);
                gravarChaveIot(chave);
            }
            if (senha.isBlank()) definidos.put("app.admin.senha", "admin123");
        } else {
            List<String> problemas = validarProducao(jwt, senha, iot);
            if (!problemas.isEmpty()) {
                throw new IllegalStateException(
                        "[Protege+] Modo producao recusado. Corrija antes de subir:\n - "
                        + String.join("\n - ", problemas));
            }
            definidos.put("spring.h2.console.enabled", "false");
        }

        if (!definidos.isEmpty()) {
            env.getPropertySources().addFirst(new MapPropertySource(FONTE, definidos));
        }
    }

    /** Regras do modo producao. Publico e estatico para ser testado sem Spring. */
    public static List<String> validarProducao(String jwt, String senhaAdmin, String chaveIot) {
        List<String> problemas = new ArrayList<>();
        if (jwt == null || jwt.length() < MIN_JWT) {
            problemas.add("JWT_SECRET ausente ou com menos de " + MIN_JWT + " caracteres");
        }
        if (senhaAdmin == null || senhaAdmin.length() < MIN_SENHA || senhaAdmin.equals("admin123")) {
            problemas.add("ADMIN_SENHA ausente, fraca ou igual a de demonstracao (minimo "
                          + MIN_SENHA + " caracteres)");
        }
        if (chaveIot == null || chaveIot.length() < MIN_IOT) {
            problemas.add("PROTEGE_IOT_CHAVE ausente ou com menos de " + MIN_IOT + " caracteres");
        }
        return problemas;
    }

    static String sortear(int bytes) {
        byte[] b = new byte[bytes];
        SORTEIO.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    private static void gravarChaveIot(String chave) {
        try {
            Path pasta = Path.of("data");
            Files.createDirectories(pasta);
            Files.writeString(pasta.resolve("iot-chave.txt"), chave + System.lineSeparator(),
                    StandardCharsets.UTF_8);
            System.out.println("[Protege+] Modo demonstracao: chave IoT desta execucao gravada em "
                    + pasta.resolve("iot-chave.txt").toAbsolutePath());
        } catch (IOException e) {
            System.out.println("[Protege+] Modo demonstracao: chave IoT desta execucao = " + chave);
        }
    }
}
