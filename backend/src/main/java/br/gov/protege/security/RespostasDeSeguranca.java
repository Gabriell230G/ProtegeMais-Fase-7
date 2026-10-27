package br.gov.protege.security;

import br.gov.protege.service.AuditoriaService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Respostas padronizadas das falhas de seguranca.
 *
 * Sem esta configuracao, o Spring Security devolve 403 tanto para quem nao
 * se autenticou quanto para quem se autenticou e nao tem permissao. Os dois
 * casos sao diferentes e o cliente precisa distingui-los:
 *
 *   401 Unauthorized -> "nao sei quem voce e"  -> o front leva ao login
 *   403 Forbidden    -> "sei quem voce e, mas seu perfil nao permite"
 *                       -> o front mostra mensagem, nao adianta relogar
 *
 * As duas respostas usam o mesmo formato do GlobalExceptionHandler, para
 * que o cliente tenha um unico contrato de erro em toda a API. Nenhuma
 * delas informa se o recurso existe - isso permitiria mapear a base por
 * tentativa e erro.
 *
 * O 403 GRAVA AUDITORIA, e essa e a parte menos obvia desta classe.
 * O interceptador @Auditavel roda em torno do METODO do controlador; quando
 * a recusa acontece na regra de ROTA do SecurityConfig, o metodo nunca e
 * chamado e o aspecto nunca dispara. Sem o registro aqui, exatamente as
 * rotas mais protegidas - auditoria e exportacao - seriam as unicas cujas
 * tentativas recusadas nao deixariam rastro. Um sistema que so registra o
 * que deu certo nao serve para investigar abuso.
 */
@Component
public class RespostasDeSeguranca implements AuthenticationEntryPoint, AccessDeniedHandler {

    private final ObjectMapper mapper = new ObjectMapper();
    private final AuditoriaService auditoria;

    public RespostasDeSeguranca(AuditoriaService auditoria) {
        this.auditoria = auditoria;
    }

    /** Requisicao sem token, com token invalido ou expirado. */
    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res,
                         org.springframework.security.core.AuthenticationException ex)
            throws IOException {
        escrever(res, HttpStatus.UNAUTHORIZED,
                "Autenticacao necessaria. Obtenha um token em POST /api/auth/login.");
    }

    /** Autenticado, porem sem o perfil exigido pela rota. */
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res,
                       org.springframework.security.access.AccessDeniedException ex)
            throws IOException {
        registrarRecusa(req);
        escrever(res, HttpStatus.FORBIDDEN, "Acesso negado para o seu perfil.");
    }

    /**
     * Deduz do caminho qual acao foi tentada e grava a recusa.
     *
     * A falha ao auditar NUNCA pode virar erro para o cliente: a resposta
     * 403 e a decisao de seguranca, e ela precisa sair mesmo que o registro
     * falhe. Por isso a excecao e engolida aqui - e a unica vez no sistema
     * em que isso e aceitavel.
     */
    private void registrarRecusa(HttpServletRequest req) {
        try {
            String uri = req.getRequestURI();
            String[] rotulo = classificarRecusa(req.getMethod(), uri);
            auditoria.registrar(rotulo[0], rotulo[1], null, AuditoriaService.NEGADO,
                    "Recusado pela regra de rota: " + req.getMethod() + " " + uri);
        } catch (RuntimeException e) {
            // Auditar e importante; negar o acesso e mais.
        }
    }

    /**
     * Fase 7 | Rotulo (acao, recurso) de uma recusa, pelo METODO e pela rota.
     *
     * A versao anterior olhava so o caminho e gravava EXCLUSAO para qualquer
     * rota de denuncia: um PUT ou PATCH negado aparecia na trilha como
     * tentativa de exclusao, o que atrapalha justamente a investigacao que a
     * trilha existe para apoiar.
     */
    static String[] classificarRecusa(String metodo, String uri) {
        String m = metodo == null ? "" : metodo.toUpperCase(java.util.Locale.ROOT);
        String u = uri == null ? "" : uri;
        boolean leitura = "GET".equals(m) || "HEAD".equals(m);

        if (u.startsWith("/api/auditoria")) {
            return new String[]{AuditoriaService.ACESSO_AUDITORIA, "AuditoriaLog"};
        }
        if (u.startsWith("/api/exportacao")) {
            return new String[]{AuditoriaService.EXPORTACAO, "Denuncia"};
        }
        if (u.startsWith("/api/backup")) {
            return new String[]{leitura ? AuditoriaService.CONSULTA_SENSIVEL : br.gov.protege.service.BackupService.BACKUP, "Banco"};
        }
        if (u.startsWith("/api/equipe")) {
            return new String[]{leitura ? AuditoriaService.CONSULTA_SENSIVEL
                                        : AuditoriaService.ALTERACAO_EQUIPE, "Membro"};
        }
        if (u.startsWith("/api/evidencias") || (u.startsWith("/api/denuncias") && u.endsWith("/evidencias"))) {
            return new String[]{"DELETE".equals(m) ? AuditoriaService.EXCLUSAO
                                                   : AuditoriaService.CONSULTA_SENSIVEL, "Evidencia"};
        }
        if (u.startsWith("/api/denuncias")) {
            if ("DELETE".equals(m)) return new String[]{AuditoriaService.EXCLUSAO, "Denuncia"};
            if ("PATCH".equals(m) && u.endsWith("/status")) {
                return new String[]{AuditoriaService.ALTERACAO_STATUS, "Denuncia"};
            }
            if ("PATCH".equals(m) && u.endsWith("/responsavel")) {
                return new String[]{AuditoriaService.ATRIBUICAO, "Denuncia"};
            }
            if (leitura) return new String[]{AuditoriaService.CONSULTA_SENSIVEL, "Denuncia"};
            return new String[]{AuditoriaService.ALTERACAO_DADOS, "Denuncia"};
        }
        if (u.startsWith("/api/fluxo")) {
            return new String[]{leitura ? AuditoriaService.CONSULTA_SENSIVEL
                                        : AuditoriaService.ALTERACAO_STATUS, "Denuncia"};
        }
        if (u.startsWith("/api/vigia")) {
            return new String[]{AuditoriaService.REANALISE_IA, "Denuncia"};
        }
        if (u.startsWith("/api/iot")) {
            return new String[]{AuditoriaService.CONSULTA_SENSIVEL, "EventoIot"};
        }
        if (u.startsWith("/api/reincidencia")) {
            return new String[]{AuditoriaService.CONSULTA_SENSIVEL, "Reincidencia"};
        }
        if (u.startsWith("/api/auth/demo")) {
            return new String[]{br.gov.protege.controller.AuthController.TROCA_PERFIL_DEMO, "Usuario"};
        }
        return new String[]{leitura ? AuditoriaService.CONSULTA_SENSIVEL
                                    : AuditoriaService.ALTERACAO_DADOS, "Rota"};
    }

    private void escrever(HttpServletResponse res, HttpStatus status, String mensagem)
            throws IOException {
        Map<String, Object> corpo = new LinkedHashMap<>();
        corpo.put("timestamp", LocalDateTime.now().toString());
        corpo.put("status", status.value());
        corpo.put("erro", status.getReasonPhrase());
        corpo.put("mensagem", mensagem);

        res.setStatus(status.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        res.setCharacterEncoding("UTF-8");
        mapper.writeValue(res.getOutputStream(), corpo);
    }
}
