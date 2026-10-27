package br.gov.protege.security;

import br.gov.protege.model.PerfilUsuario;
import br.gov.protege.model.Usuario;
import br.gov.protege.repository.UsuarioRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * Le o token JWT do cabecalho Authorization e autentica a requisicao.
 *
 * Correcao importante desta fase: a versao anterior concedia ROLE_GESTOR a
 * QUALQUER token valido, ignorando a claim de perfil que o proprio
 * JwtService gravava. Na pratica nao havia segregacao de acesso - um
 * atendente recebia as mesmas autorizacoes de um administrador. Agora o
 * perfil vem do token, e um token sem perfil declarado nao autentica.
 *
 * Fase 7 | O perfil passou a vir do BANCO, e nao da claim do token. A cada
 * requisicao o usuario e lido pelo e-mail: se a conta foi removida, o token
 * deixa de autenticar na hora; se o perfil mudou (ex.: GESTOR rebaixado a
 * ATENDENTE), vale o perfil novo, sem esperar as 8 h de validade do token.
 * A troca de perfil da demonstracao continua funcionando porque emite tokens
 * de contas demo reais, cujo perfil gravado e o pedido.
 */
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UsuarioRepository usuarios;

    public JwtAuthFilter(JwtService jwtService, UsuarioRepository usuarios) {
        this.jwtService = jwtService;
        this.usuarios = usuarios;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain chain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            if (jwtService.valido(token)) {
                String perfilNoToken = jwtService.extrairPerfil(token);
                String email = jwtService.extrairEmail(token);
                Optional<Usuario> conta = (perfilNoToken == null || email == null)
                        ? Optional.empty()
                        : usuarios.findByEmail(email);
                if (conta.isPresent()) {
                    PerfilUsuario perfil = PerfilUsuario.de(conta.get().getRole());

                    var auth = new UsernamePasswordAuthenticationToken(
                            email, null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + perfil.name())));
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        }
        chain.doFilter(request, response);
    }
}
