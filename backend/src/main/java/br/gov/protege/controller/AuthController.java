package br.gov.protege.controller;

import br.gov.protege.dto.LoginRequest;
import br.gov.protege.model.Usuario;
import br.gov.protege.repository.UsuarioRepository;
import br.gov.protege.security.JwtService;
import br.gov.protege.service.AuditoriaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import br.gov.protege.model.PerfilUsuario;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@Tag(name = "Autenticacao", description = "Login do servidor publico e emissao de token JWT")
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UsuarioRepository repo;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final AuditoriaService auditoria;
    private final boolean demo;
    private final String emailAdmin;

    /**
     * Fase 7 | Hash BCrypt de uma senha sorteada, gerado uma vez na subida
     * com o mesmo codificador (e o mesmo custo) das contas reais. Serve so
     * para gastar, no login com e-mail inexistente, o mesmo tempo de uma
     * conferencia de senha de verdade.
     */
    private final String hashFalso;

    /** Acao gravada na trilha quando o ADMIN troca de perfil na demonstracao. */
    public static final String TROCA_PERFIL_DEMO = "TROCA_PERFIL_DEMO";

    /** Contas de demonstracao por perfil (criadas so em modo demonstracao). */
    static final Map<String, String> CONTA_DEMO = Map.of(
            PerfilUsuario.GESTOR.name(),    "gestor@protege.gov.br",
            PerfilUsuario.ATENDENTE.name(), "atendente@protege.gov.br",
            PerfilUsuario.AUDITOR.name(),   "auditor@protege.gov.br");

    public AuthController(UsuarioRepository repo, PasswordEncoder encoder,
                          JwtService jwt, AuditoriaService auditoria,
                          @Value("${protege.demo:true}") boolean demo,
                          @Value("${app.admin.email}") String emailAdmin) {
        this.repo = repo;
        this.encoder = encoder;
        this.jwt = jwt;
        this.auditoria = auditoria;
        this.demo = demo;
        this.emailAdmin = emailAdmin;
        this.hashFalso = encoder.encode(java.util.UUID.randomUUID().toString());
    }

    @Operation(summary = "Troca de perfil na demonstracao (somente ADMIN, somente modo demo)",
               description = "Fase 7. Substitui as senhas que ficavam no JavaScript publico. "
                           + "Quem ja entrou como ADMIN pede um token de outro perfil para "
                           + "demonstrar a segregacao de acesso. A troca fica registrada na "
                           + "trilha de auditoria. Em modo producao a rota responde 404.")
    @PostMapping("/demo/perfil")
    public ResponseEntity<?> trocarPerfil(@RequestBody Map<String, String> corpo) {
        if (!demo) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("erro", "Recurso inexistente"));
        }
        String perfil = String.valueOf(corpo.getOrDefault("perfil", "")).toUpperCase();
        String email = PerfilUsuario.ADMIN.name().equals(perfil) ? emailAdmin : CONTA_DEMO.get(perfil);
        if (email == null) {
            return ResponseEntity.badRequest().body(Map.of("erro", "Perfil desconhecido"));
        }
        Optional<Usuario> alvo = repo.findByEmail(email);
        if (alvo.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("erro", "Conta de demonstracao ausente"));
        }
        Usuario u = alvo.get();
        auditoria.registrar(TROCA_PERFIL_DEMO, "Usuario", u.getEmail(),
                AuditoriaService.PERMITIDO, "Administrador assumiu o perfil " + u.getRole() + " na demonstracao");
        String token = jwt.gerarToken(u.getEmail(), u.getNome(), u.getRole());
        return ResponseEntity.ok(Map.of("token", token, "nome", u.getNome(), "role", u.getRole(),
                                        "email", u.getEmail()));
    }

    @Operation(summary = "Autentica o servidor e devolve o token",
               description = "A resposta de credencial invalida e deliberadamente igual para "
                           + "e-mail inexistente e senha errada: diferenciar as duas permitiria "
                           + "descobrir quais contas existem no orgao. Tanto o sucesso quanto a "
                           + "recusa geram registro na trilha de auditoria. A rota tem limite de "
                           + "20 tentativas por minuto por origem.")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Token, nome e perfil do usuario"),
        @ApiResponse(responseCode = "400", description = "Corpo invalido",
                     content = @io.swagger.v3.oas.annotations.media.Content),
        @ApiResponse(responseCode = "401", description = "Credenciais invalidas",
                     content = @io.swagger.v3.oas.annotations.media.Content),
        @ApiResponse(responseCode = "429", description = "Tentativas em excesso desta origem",
                     content = @io.swagger.v3.oas.annotations.media.Content)
    })
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {

        // Fase 7 | Tempo igual para e-mail inexistente e senha errada. Antes o
        // BCrypt (dezenas de milissegundos) so rodava quando a conta existia,
        // e a diferenca de tempo de resposta revelava quais e-mails tinham
        // conta no orgao, mesmo com a mensagem identica.
        Optional<Usuario> conta = repo.findByEmail(req.getEmail());
        boolean senhaConfere;
        if (conta.isPresent()) {
            senhaConfere = encoder.matches(req.getSenha(), conta.get().getSenhaHash());
        } else {
            encoder.matches(req.getSenha(), hashFalso);   // resultado descartado de proposito
            senhaConfere = false;
        }
        Optional<Usuario> encontrado = senhaConfere ? conta : Optional.empty();

        if (encontrado.isEmpty()) {
            auditoria.registrarLogin(req.getEmail(), null, false);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("erro", "Credenciais invalidas"));
        }

        Usuario u = encontrado.get();
        auditoria.registrarLogin(u.getEmail(), u.getRole(), true);

        String token = jwt.gerarToken(u.getEmail(), u.getNome(), u.getRole());
        return ResponseEntity.ok(Map.of(
                "token", token,
                "nome", u.getNome(),
                "role", u.getRole()));
    }
}
