package br.gov.protege.security;

import br.gov.protege.model.PerfilUsuario;
import br.gov.protege.model.Usuario;
import br.gov.protege.repository.UsuarioRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    private final JwtService jwtService;
    private final RespostasDeSeguranca respostas;
    private final boolean consoleH2;
    private final boolean confiarEmProxy;

    public SecurityConfig(JwtService jwtService, RespostasDeSeguranca respostas,
                          @Value("${spring.h2.console.enabled:false}") boolean consoleH2,
                          @Value("${protege.proxy-confiavel:false}") boolean confiarEmProxy) {
        this.jwtService = jwtService;
        this.respostas = respostas;
        this.consoleH2 = consoleH2;
        this.confiarEmProxy = confiarEmProxy;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        JwtAuthFilter jwtAuthFilter = new JwtAuthFilter(jwtService);

        http
            .csrf(AbstractHttpConfigurer::disable)
            // Usa o bean corsConfigurationSource declarado abaixo.
            .cors(Customizer.withDefaults())
            .authorizeHttpRequests(auth -> auth
                // Preflight CORS
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                // ---- CANAL DO CIDADAO (publico por definicao) ----
                // Exigir identificacao para denunciar anularia o anonimato,
                // que e a razao de existir do canal.
                .requestMatchers(HttpMethod.POST, "/api/denuncias").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/denuncias/protocolo/**").permitAll()

                // Fase 7 | Troca de perfil da demonstracao. Antes, o navegador
                // guardava a senha de cada perfil no JavaScript publico. Agora
                // so quem ja entrou como ADMIN pede ao servidor um token de
                // outro perfil, e so em modo demonstracao. Precisa vir ANTES
                // da liberacao geral de /api/auth/**.
                .requestMatchers("/api/auth/demo/**").hasRole(PerfilUsuario.ADMIN.name())
                .requestMatchers("/api/auth/**", "/api/vigia/status").permitAll()

                // Anexar evidencia e publico pelo protocolo: quem denuncia
                // anonimamente nao tem conta para autenticar. No lugar da
                // autenticacao entram limites - tamanho, quantidade, formato
                // verificado pela assinatura e limite por origem.
                .requestMatchers(HttpMethod.POST, "/api/denuncias/protocolo/*/evidencias").permitAll()

                // Dispositivos fisicos (Fase 6) nao tem usuario para autenticar.
                // Eles entram por chave compartilhada no cabecalho X-Device-Key,
                // conferida no EventoIotService. A rota fica fora do JWT, mas so
                // permite CRIAR evento: ler, alterar e apagar continuam exigindo
                // token e perfil, como todo o resto da API.
                .requestMatchers(HttpMethod.POST, "/api/iot/**").permitAll()

                // ---- Documentacao ----
                .requestMatchers("/swagger-ui/**", "/swagger-ui.html",
                                 "/v3/api-docs/**").permitAll()

                // ---- Console do banco (Fase 7) ----
                // Antes ficava aberto para qualquer um que alcancasse a porta.
                // Agora so existe se H2_CONSOLE=true, e o proprio H2 recusa
                // conexao que nao venha da maquina local (web-allow-others).
                // Desligado, a rota cai na regra geral e exige autenticacao.
                .requestMatchers(consoleH2 ? "/h2-console/**" : "/__console-desligado__/**").permitAll()

                // ---- TRILHA DE AUDITORIA ----
                // Quem opera o sistema nao fiscaliza o proprio uso dele.
                .requestMatchers("/api/auditoria/**")
                    .hasAnyRole(PerfilUsuario.AUDITOR.name(), PerfilUsuario.ADMIN.name())

                // ---- BACKUP (Fase 7) ----
                // Gerar backup e operacao de administrador. Conferir a
                // integridade dos backups e tarefa de fiscalizacao, entao o
                // AUDITOR tambem le a lista (mas nao gera).
                .requestMatchers(HttpMethod.POST, "/api/backup/**")
                    .hasRole(PerfilUsuario.ADMIN.name())
                .requestMatchers(HttpMethod.GET, "/api/backup/**")
                    .hasAnyRole(PerfilUsuario.AUDITOR.name(), PerfilUsuario.ADMIN.name())

                // ---- EXPORTACAO DE DADOS ----
                // A operacao de maior exposicao do sistema: entrega centenas de
                // registros de uma vez, num arquivo que passa a circular fora
                // de qualquer controle de acesso. Sempre auditada.
                //
                // O ATENDENTE exporta, e isso e deliberado: o arquivo carrega
                // exatamente os campos que ele JA VE na tela do backlog, com o
                // mesmo mascaramento de endereco. Liberar a tela e negar o CSV
                // seria teatro - bastaria copiar a tabela a mao. O que protege
                // aqui nao e a proibicao, e o mascaramento no servidor mais o
                // registro de quem exportou e quando.
                //
                // O AUDITOR fica de fora: ele fiscaliza o uso do sistema, e nao
                // trabalha os casos. Dar-lhe a base inteira seria criar o unico
                // perfil com visao total, que e o que a segregacao evita.
                .requestMatchers("/api/exportacao/**")
                    .hasAnyRole(PerfilUsuario.ATENDENTE.name(),
                                PerfilUsuario.GESTOR.name(),
                                PerfilUsuario.ADMIN.name())

                // ---- EXCLUSAO DE DENUNCIA E DE ANEXO ----
                .requestMatchers(HttpMethod.DELETE, "/api/denuncias/**")
                    .hasAnyRole(PerfilUsuario.GESTOR.name(), PerfilUsuario.ADMIN.name())
                .requestMatchers(HttpMethod.DELETE, "/api/evidencias/**")
                    .hasAnyRole(PerfilUsuario.GESTOR.name(), PerfilUsuario.ADMIN.name())

                // ---- GESTAO DA EQUIPE ----
                .requestMatchers(HttpMethod.POST,   "/api/equipe/**")
                    .hasAnyRole(PerfilUsuario.GESTOR.name(), PerfilUsuario.ADMIN.name())
                .requestMatchers(HttpMethod.PUT,    "/api/equipe/**")
                    .hasAnyRole(PerfilUsuario.GESTOR.name(), PerfilUsuario.ADMIN.name())
                .requestMatchers(HttpMethod.DELETE, "/api/equipe/**")
                    .hasAnyRole(PerfilUsuario.GESTOR.name(), PerfilUsuario.ADMIN.name())

                // ---- Demais rotas do painel ----
                .anyRequest().authenticated())

            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // Sem isto, requisicao sem token devolve 403 em vez de 401.
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(respostas)
                .accessDeniedHandler(respostas))

            // O limite por origem vem antes da autenticacao: forca bruta de
            // senha precisa ser barrada ANTES de chegar na verificacao dela.
            .addFilterBefore(new RateLimitFilter(confiarEmProxy), UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        // Fase 7 | Antes a protecao contra a pagina ser embutida em outro
        // site (frameOptions) estava DESLIGADA para o sistema inteiro, so
        // para o console do H2 funcionar. sameOrigin atende o console (que
        // usa frames do proprio servidor) e volta a impedir que um site
        // terceiro carregue o painel dentro de um frame invisivel.
        http.headers(h -> h
            .frameOptions(f -> f.sameOrigin())
            .contentTypeOptions(Customizer.withDefaults())
            .referrerPolicy(r -> r.policy(
                org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter
                    .ReferrerPolicy.NO_REFERRER)));
        return http.build();
    }

    /**
     * CORS restrito por lista de origens.
     *
     * A configuracao anterior usava allowedOriginPatterns("*") junto com
     * allowCredentials(true): qualquer site na internet podia disparar
     * requisicoes autenticadas contra esta API a partir do navegador de um
     * servidor logado. Para um sistema de dados sensiveis isso e
     * inaceitavel, e por isso as origens agora sao declaradas.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.origens}") String origens) {

        CorsConfiguration c = new CorsConfiguration();
        c.setAllowedOrigins(Arrays.stream(origens.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList());
        c.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        // X-Device-Key precisa estar declarado aqui, e nao apenas aceito pelo
        // controller. Um cabecalho personalizado torna a requisicao do
        // navegador nao simples, e o preflight OPTIONS e recusado antes de o
        // POST existir. O resultado, sem esta linha, e um erro de CORS que
        // parece falha de rede e nao aponta para o cabecalho.
        c.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept", "X-Device-Key"));
        // Sem expor Content-Disposition, o JavaScript nao consegue ler o nome
        // que o servidor sugeriu para o arquivo baixado - o navegador recebe
        // o cabecalho, mas a origem cruzada o esconde do script.
        c.setExposedHeaders(List.of("Location", "Content-Disposition"));
        c.setAllowCredentials(true);
        c.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", c);
        return src;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Cria os usuarios de demonstracao, um por perfil, para que a segregacao
     * de acesso possa ser verificada de verdade - e nao apenas descrita.
     */
    @Bean
    public CommandLineRunner seedUsuarios(UsuarioRepository repo, PasswordEncoder encoder,
                                          @Value("${app.admin.email}") String emailAdmin,
                                          @Value("${app.admin.senha}") String senhaAdmin,
                                          @Value("${app.admin.nome}") String nomeAdmin,
                                          @Value("${protege.demo:true}") boolean demo) {
        return args -> {
            criar(repo, encoder, emailAdmin, senhaAdmin, nomeAdmin, PerfilUsuario.ADMIN);
            // Fase 7 | Contas de demonstracao (senhas conhecidas, documentadas
            // no README) so existem em modo demonstracao. Em producao, os
            // demais usuarios sao cadastrados pelo administrador.
            if (!demo) {
                log.info("[Protege+] Modo producao: usuarios de demonstracao NAO criados.");
                return;
            }
            criar(repo, encoder, "gestor@protege.gov.br",    "gestor123",    "Carlos Lima - Coordenador", PerfilUsuario.GESTOR);
            criar(repo, encoder, "atendente@protege.gov.br", "atendente123", "Ana Souza - Atendente",     PerfilUsuario.ATENDENTE);
            criar(repo, encoder, "auditor@protege.gov.br",   "auditor123",   "Controladoria Interna",     PerfilUsuario.AUDITOR);
        };
    }

    private void criar(UsuarioRepository repo, PasswordEncoder encoder,
                       String email, String senha, String nome, PerfilUsuario perfil) {
        repo.findByEmail(email).ifPresentOrElse(
            u -> {
                if (!perfil.name().equals(u.getRole())) {
                    u.setRole(perfil.name());
                    repo.save(u);
                    log.info("[Protege+] Perfil atualizado: {} -> {}", email, perfil);
                }
            },
            () -> {
                repo.save(new Usuario(email, encoder.encode(senha), nome, perfil.name()));
                log.info("[Protege+] Usuario criado: {} ({})", email, perfil);
            });
    }
}
