/**
 * acesso.js — Controle de acesso por perfil (US24).
 *
 * O seletor de perfil deixou de ser uma simulação de interface: trocar de
 * perfil aqui pede ao SERVIDOR um token do outro perfil, e o token emitido
 * carrega a role correspondente. A partir daí, quem decide o que cada um
 * pode fazer é o servidor — o front apenas reflete a decisão.
 *
 * Fase 7: este arquivo não guarda mais nenhuma senha. Na Fase 6 ele trazia
 * a senha dos quatro perfis em texto, num arquivo público. Agora a troca só
 * funciona para quem entrou como ADMIN na tela de login, só com o servidor
 * em modo demonstração, e cada troca fica registrada na trilha de auditoria.
 *
 * Isso importa porque esconder um botão não é controle de acesso. Se a
 * restrição vivesse só aqui, bastaria abrir o console do navegador para
 * contorná-la. Ao trocar para Atendente e abrir a Trilha de Auditoria, a API
 * responde 403 e a própria tentativa fica registrada na trilha.
 *
 * Quatro perfis demonstráveis:
 *   ADMIN     → acesso pleno, integralmente auditado.
 *   GESTOR    → coordena o atendimento e vê identificação. NÃO vê a auditoria.
 *   ATENDENTE → trabalha os casos sem acesso a dado identificável.
 *   AUDITOR   → fiscaliza o uso do sistema, sem ver o relato das denúncias.
 */
const Acesso = (() => {

  let papelAtual = 'master';

  // Fase 7 | Regras que o SERVIDOR aplica (SecurityConfig + FluxoStatus),
  // refletidas aqui para a tela nao oferecer o que vai ser recusado:
  //   retroceder  voltar etapa / reabrir caso concluido (senao 409)
  //   atribuir    PATCH /denuncias/{id}/responsavel   (senao 403)
  //   pilha       GET /fluxo/pilha e POST /fluxo/desfazer (senao 403)
  //   excluir     DELETE de denuncia e de anexo        (senao 403)
  // Esconder botao nao e controle de acesso: quem decide continua sendo a API.
  const PERMISSOES = {
    master: {
      label: 'Administrador',
      verIdentidade: true,
      retroceder: true, atribuir: true, pilha: true, excluir: true,
      abas: ['resumo','backlog','status-d','kanban','equipe','mapa','dispositivos','reincidencia','estatistica','auditoria'],
      role: 'ADMIN', email: 'admin@protege.gov.br',
      aviso: '🛡️ Perfil Administrador — acesso pleno, integralmente auditado.',
    },
    gestor: {
      label: 'Gestor',
      verIdentidade: true,
      retroceder: true, atribuir: true, pilha: true, excluir: true,
      abas: ['resumo','backlog','status-d','kanban','equipe','mapa','dispositivos','reincidencia','estatistica','auditoria'],
      role: 'GESTOR', email: 'gestor@protege.gov.br',
      aviso: '👔 Perfil Gestor — vê identificação, mas a trilha de auditoria é negada pela API.',
    },
    analista: {
      label: 'Atendente',
      verIdentidade: false,
      retroceder: false, atribuir: false, pilha: false, excluir: false,
      abas: ['resumo','backlog','status-d','kanban','mapa','dispositivos','reincidencia','estatistica','auditoria'],
      role: 'ATENDENTE', email: 'atendente@protege.gov.br',
      aviso: '👁️ Perfil Atendente — identidade e endereço protegidos pelo servidor.',
    },
    auditor: {
      label: 'Auditor',
      verIdentidade: false,
      retroceder: false, atribuir: false, pilha: false, excluir: false,
      abas: ['resumo','auditoria'],
      role: 'AUDITOR', email: 'auditor@protege.gov.br',
      aviso: '🔎 Perfil Auditor — fiscaliza o uso do sistema, sem ver o relato das denúncias.',
    },
  };

  function T(chave, padrao) {
    return (typeof I18n !== 'undefined' && I18n.t) ? I18n.t(chave) : padrao;
  }

  function papel() { return papelAtual; }

  /**
   * Estado vazio para uma recusa da API (401/403/erro). Nunca ha dado local
   * no lugar: a mensagem diz por que a tela esta vazia.
   * @param falha {status, message}
   */
  function avisoHtml(falha, contexto) {
    const st = falha && falha.status;
    let icone = '❌', titulo = (falha && falha.message) || T('acesso.erro', 'Não foi possível carregar os dados do servidor.');
    let nota = T('acesso.nota_erro', 'Os dados locais deste navegador não são exibidos no lugar dos do servidor.');
    if (st === 401) {
      icone = '🔑';
      titulo = T('acesso.relogin', 'Faça login novamente');
      nota = T('acesso.nota_401', 'Sua sessão terminou ou não há login ativo. Entre de novo pela Área do Servidor.');
    } else if (st === 403) {
      icone = '🚫';
      titulo = T('acesso.negado', 'Seu perfil não tem acesso a este conteúdo');
      nota = contexto === 'resumo'
        ? T('acesso.nota_resumo', 'Para o seu perfil o resumo mostra apenas os indicadores agregados do canal.')
        : T('acesso.nota_403', 'O servidor recusou esta consulta para o seu perfil.');
    }
    return `<div class="est-aviso erro acesso-aviso" data-acesso="${escAttr(st || 0)}" style="margin:0">`
         + `${icone} <b>${escHtml(titulo)}</b><br><span>${escHtml(nota)}</span></div>`;
  }
  function pode(acao) { return !!(PERMISSOES[papelAtual] && PERMISSOES[papelAtual][acao]); }
  function podeVerAba(aba) {
    return !!(PERMISSOES[papelAtual] && PERMISSOES[papelAtual].abas.indexOf(aba) >= 0);
  }


  async function definir(novoPapel, btn) {
    const cfg = PERMISSOES[novoPapel];
    if (!cfg) return;
    papelAtual = novoPapel;

    document.querySelectorAll('.papel-opt').forEach(b => b.classList.remove('active'));
    if (btn) btn.classList.add('active');

    // Troca pedida ao servidor. O perfil efetivo passa a ser o que o token
    // declara. Sem login de ADMIN, a troca vale só para a tela (modo local).
    let perfilReal = null;
    let semPermissao = false;
    if (typeof Backend !== 'undefined' && await Backend.estaOnline()) {
      if (Backend.podeTrocarPerfil()) {
        const dados = await Backend.trocarPerfil(cfg.role);
        perfilReal = dados ? dados.role : null;
        // Token novo, perfil novo: a lista carregada com o token anterior
        // (ex.: a do ADMIN) nao pode continuar na tela do AUDITOR.
        if (perfilReal) await recarregarDados();
      } else {
        semPermissao = true;
      }
    }

    const lbl = document.getElementById('user-role-label');
    if (lbl) {
      lbl.textContent = perfilReal ? (cfg.label + ' • ' + perfilReal)
                                   : (cfg.label + ' • modo local');
    }
    const nome = document.querySelector('.user-name');
    if (nome) nome.textContent = cfg.email;

    aplicar();

    if (typeof showToast === 'function') {
      const sufixo = perfilReal ? ''
        : semPermissao ? ' (entre como Administrador para trocar o perfil no servidor; por ora, restrição apenas local)'
        : ' (API fora do ar: restrição apenas local)';
      showToast(cfg.aviso + sufixo);
    }
  }

  /**
   * Esconde do menu as abas que o perfil não usa e volta ao resumo se a aba
   * aberta deixou de ser permitida.
   *
   * A aba de auditoria permanece VISÍVEL para os perfis operacionais de
   * propósito: é ao abri-la e receber 403 que a segregação de acesso fica
   * demonstrada. Esconder o botão pareceria segurança sem sê-la.
   */
  function aplicar() {
    document.querySelectorAll('.sidebar-item').forEach(item => {
      const onclick = item.getAttribute('onclick') || '';
      const m = onclick.match(/showDashTab\('([^']+)'/);
      if (m) item.style.display = podeVerAba(m[1]) ? '' : 'none';
    });

    const abaAtiva = document.querySelector('.sidebar-item.active');
    if (abaAtiva) {
      const m = (abaAtiva.getAttribute('onclick') || '').match(/showDashTab\('([^']+)'/);
      if (m && !podeVerAba(m[1]) && typeof showDashTab === 'function') {
        showDashTab('resumo', document.querySelector(".sidebar-item[onclick*=\"'resumo'\"]"));
      }
    }

    if (typeof renderStatusTable === 'function') renderStatusTable();
    if (typeof renderBacklog === 'function') renderBacklog();
    if (typeof Kanban !== 'undefined') Kanban.render();
    if (typeof Fluxo !== 'undefined' && Fluxo.aplicarPerfil) Fluxo.aplicarPerfil();
    if (typeof ajustarResumoAoAcesso === 'function') ajustarResumoAoAcesso();
  }

  /** Perfis que veem o Kanban ou a aba Equipe (os que leem /api/equipe). */
  function usaEquipe() { return podeVerAba('kanban') || podeVerAba('equipe'); }

  /** Recarrega casos e equipe com o token atual (depois de troca de perfil). */
  async function recarregarDados() {
    if (typeof limparPainelAnterior === 'function') limparPainelAnterior();
    if (typeof Sincronia !== 'undefined' && Sincronia.limpar) {
      Sincronia.limpar();
      try { await Sincronia.hidratar(true); } catch (_) { /* a recusa fica registrada */ }
    }
    if (typeof Equipe !== 'undefined' && Equipe.sincronizar && usaEquipe()) {
      try { await Equipe.sincronizar(); } catch (_) { /* cache vazio */ }
    }
    if (typeof Sincronia !== 'undefined' && Sincronia.redesenhar) Sincronia.redesenhar();
  }

  /**
   * Mascaramento no cliente, para os dados que vivem no modo local.
   *
   * Quando a API está no ar o mascaramento já vem pronto do servidor — que é
   * onde ele precisa acontecer. Este aqui cobre o plano B e mantém a tela
   * coerente nos dois modos.
   */
  function mascarar(denuncia) {
    if (!denuncia) return denuncia;
    if (pode('verIdentidade')) return denuncia;
    const copia = Object.assign({}, denuncia);
    if (copia.nome)     copia.nome = '🔒 [protegido]';
    if (copia.contato)  copia.contato = '🔒 [protegido]';
    if (copia.endereco) copia.endereco = '🔒 [endereço protegido]';
    return copia;
  }

  /** Traduz a role que o token declara para o papel usado nesta tela. */
  const POR_ROLE = {
    ADMIN: 'master', GESTOR: 'gestor', ATENDENTE: 'analista', AUDITOR: 'auditor',
  };

  /**
   * Aplica o perfil de quem acabou de se autenticar na tela de login.
   *
   * Diferente de definir(), nao faz login: o token ja existe. Quem manda e a
   * role que o SERVIDOR colocou no token, nao o que o usuario digitou nem o
   * que esta tela imagina. Um e-mail desconhecido cai no perfil mais restrito
   * em vez de no mais permissivo - errar para o lado de negar acesso.
   */
  function aplicarAutenticado(role, email) {
    papelAtual = POR_ROLE[String(role).toUpperCase()] || 'analista';
    // Quem entrou agora nao herda a lista de quem estava antes.
    if (typeof Sincronia !== 'undefined' && Sincronia.limpar) Sincronia.limpar();
    if (typeof limparPainelAnterior === 'function') limparPainelAnterior();
    const cfg = PERMISSOES[papelAtual];

    document.querySelectorAll('.papel-opt').forEach(b => b.classList.remove('active'));
    const btn = document.getElementById('papel-' + (papelAtual === 'analista' ? 'analista' : papelAtual));
    if (btn) btn.classList.add('active');

    const lbl = document.getElementById('user-role-label');
    if (lbl) lbl.textContent = cfg.label + ' • ' + role;
    const nome = document.querySelector('.user-name');
    if (nome && email) nome.textContent = email;

    aplicar();
    // A equipe (nomes dos responsaveis no Kanban) e lida com o token novo.
    // O AUDITOR nao usa a equipe: pedir seria so uma recusa (403) na trilha.
    if (typeof Equipe !== 'undefined' && Equipe.sincronizar && usaEquipe()) {
      Equipe.sincronizar().then(() => { if (typeof Kanban !== 'undefined') Kanban.render(); })
                          .catch(() => {});
    }
    return papelAtual;
  }

  function init() { aplicar(); }

  return { papel, pode, podeVerAba, definir, aplicarAutenticado,
           aplicar, mascarar, init, avisoHtml };
})();

window.Acesso = Acesso;

document.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => Acesso.init(), 100);
});
