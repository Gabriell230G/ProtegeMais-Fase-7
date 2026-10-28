/**
 * backend.js — Ponte entre o frontend Protege+ e a API Java (Spring Boot).
 *
 * - Se o backend estiver no ar, usa a API real (PostgreSQL/Supabase ou H2).
 * - Se estiver fora, cai automaticamente para o localStorage (plano B da demo).
 * - Rotas do painel exigem login (JWT), obtido SOMENTE via Backend.login().
 *
 * Fase 7: o auto-login com a conta de administrador foi removido. Na Fase 6
 *   este arquivo guardava a senha do ADMIN e entrava com ela sempre que uma
 *   rota protegida era chamada sem token. Como o arquivo é público, qualquer
 *   visitante operava o painel como administrador sem perceber, anulando a
 *   separação de perfis. Agora, sem login, a rota protegida simplesmente
 *   recebe 401 e a tela continua no modo local.
 *
 * Contrato da API a partir da Fase 5:
 *   • POST   /api/denuncias                    → 201 + Location, corpo público
 *   • GET    /api/denuncias?…&pagina=&tamanho= → envelope de página
 *   • GET    /api/denuncias/{id}               → detalhe (consulta sensível)
 *   • PUT    /api/denuncias/{id}               → atualização completa
 *   • DELETE /api/denuncias/{id}?motivo=…      → 204, exclusão lógica
 */
const Backend = (() => {

  // Configurável por ambiente: window.PROTEGE_API_URL definido antes deste
  // script sobrescreve o padrão. Evita ter localhost fixo no código.
  const BASE = (typeof window !== 'undefined' && window.PROTEGE_API_URL)
    ? String(window.PROTEGE_API_URL).replace(/\/+$/, '')
    : 'http://localhost:8080/api';

  let online = null;
  let token = null;
  let perfil = null;
  // Token de quem entrou como ADMIN. Guardado só em memória (some ao fechar
  // a aba) e usado apenas para pedir ao servidor a troca de perfil da
  // demonstração. Nenhuma senha fica neste arquivo.
  let tokenAdmin = null;

  // ── Saúde do backend ─────────────────────────────────────────
  async function estaOnline() {
    if (online !== null) return online;
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), 1500);
      const res = await fetch(`${BASE}/vigia/status`, { signal: ctrl.signal });
      clearTimeout(t);
      online = res.ok;
      // Fase 7: as contas de teste só aparecem na tela de login quando o
      // próprio servidor declara que está em modo demonstração.
      if (online && typeof document !== 'undefined') {
        try {
          const st = await res.json();
          const caixa = document.getElementById('login-demo-contas');
          if (caixa) caixa.hidden = !st.demo;
        } catch (_) { /* status sem corpo: mantém escondido */ }
      }
    } catch (_) {
      online = false;
    }
    console.log(`[Backend] ${online ? 'API Java ONLINE' : 'API offline — usando localStorage'}`);
    if (typeof document !== 'undefined') {
      document.dispatchEvent(new CustomEvent('protege:conexao', { detail: { online } }));
    }
    return online;
  }

  /** Permite forçar nova checagem (usado pelo indicador de conexão da UI). */
  function reavaliarConexao() { online = null; return estaOnline(); }

  // ── Autenticação (JWT) ───────────────────────────────────────
  async function login(email, senha) {
    const res = await fetch(`${BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, senha }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    token = data.token;
    perfil = data.role;
    tokenAdmin = data.role === 'ADMIN' ? data.token : null;
    return data;
  }

  function logout() { token = null; perfil = null; tokenAdmin = null; }
  function perfilAtual() { return perfil; }
  function podeTrocarPerfil() { return !!tokenAdmin; }

  /**
   * Troca de perfil da demonstração (Fase 7). Só funciona para quem entrou
   * como ADMIN e só com o servidor em modo demonstração. O servidor emite o
   * token do outro perfil e registra a troca na trilha de auditoria.
   */
  async function trocarPerfil(role) {
    if (!tokenAdmin) return null;
    const res = await fetch(`${BASE}/auth/demo/perfil`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenAdmin}` },
      body: JSON.stringify({ perfil: role }),
    });
    if (!res.ok) return null;
    const data = await res.json();
    token = data.token;
    perfil = data.role;
    return data;
  }

  /** Sem auto-login: devolve o token de quem entrou, ou null. */
  async function garantirLogin() {
    return token;
  }

  function authHeaders(extra = {}) {
    return token ? { ...extra, Authorization: `Bearer ${token}` } : extra;
  }

  /**
   * Chama uma rota protegida com o token de quem entrou. Sem token, a API
   * responde 401 e quem chamou mantém os dados locais. Um 401 com token
   * significa crachá vencido: descarta e exige novo login.
   */
  async function protegido(fn) {
    const res = await fn();
    if (res.status === 401 && token) {
      token = null; perfil = null; tokenAdmin = null;
      if (typeof document !== 'undefined') {
        document.dispatchEvent(new CustomEvent('protege:sessao-expirada'));
      }
    }
    return res;
  }

  /** Extrai a mensagem padronizada de erro devolvida pela API. */
  async function erroDa(res) {
    try {
      const corpo = await res.json();
      return corpo.mensagem || corpo.erro || `Erro ${res.status}`;
    } catch (_) {
      return `Erro ${res.status}`;
    }
  }

  // ── Leitura protegida: quando o plano B local vale ───────────
  // Fase 7 | Antes, qualquer resposta diferente de 200 fazia a tela cair
  // para o localStorage e para os exemplos embutidos. Com a matriz de
  // perfis no servidor isso virou vazamento: o AUDITOR recebe 403 na lista
  // de casos e passava a ver os casos guardados neste navegador (inclusive
  // os que outro perfil carregou antes). Agora so a API FORA DO AR (falha
  // de rede) libera o plano B. Um 401/403 de uma API no ar vira erro com a
  // mensagem de acesso, e a tela mostra estado vazio em vez de dado local.

  function T(chave, padrao) {
    return (typeof I18n !== 'undefined' && I18n.t) ? I18n.t(chave) : padrao;
  }

  /** Erro de acesso (401/403) com a mensagem que a tela exibe. */
  function erroAcesso(status) {
    const e = new Error(status === 401
      ? T('acesso.relogin', 'Faça login novamente')
      : T('acesso.negado', 'Seu perfil não tem acesso a este conteúdo'));
    e.status = status;
    e.acessoNegado = true;
    return e;
  }

  /** True só quando a API foi consultada e não respondeu (modo local). */
  function modoLocal() { return online === false; }

  /** A rede falhou no meio da sessão: a partir daqui vale o modo local. */
  function marcarForaDoAr() {
    if (online === false) return;
    online = false;
    console.log('[Backend] API deixou de responder: usando localStorage');
    if (typeof document !== 'undefined') {
      document.dispatchEvent(new CustomEvent('protege:conexao', { detail: { online } }));
    }
  }

  const FORA_DO_AR = Object.freeze({ foraDoAr: true });

  /**
   * GET em rota protegida.
   *   - 2xx: corpo JSON;
   *   - falha de rede: FORA_DO_AR (quem chamou decide se há plano B local);
   *   - 401/403: lança erroAcesso (nunca há plano B local);
   *   - 404 com opcoes.nulo404: null;
   *   - outro status: lança a mensagem do servidor.
   */
  async function lerProtegido(caminho, opcoes = {}) {
    const init = { headers: authHeaders(opcoes.corpo !== undefined ? { 'Content-Type': 'application/json' } : {}) };
    if (opcoes.metodo) init.method = opcoes.metodo;
    if (opcoes.corpo !== undefined) init.body = JSON.stringify(opcoes.corpo);
    let res;
    try {
      res = await protegido(() => fetch(`${BASE}${caminho}`, init));
    } catch (_) {
      marcarForaDoAr();
      return FORA_DO_AR;
    }
    if (res.ok) return res.json();
    if (res.status === 401 || res.status === 403) throw erroAcesso(res.status);
    if (res.status === 404 && opcoes.nulo404) return null;
    throw Object.assign(new Error(await erroDa(res)), { status: res.status });
  }

  // ── localStorage (fallback) ──────────────────────────────────
  function lsGet() {
    try { return JSON.parse(localStorage.getItem('denuncias') || '[]'); }
    catch (_) { return []; }
  }
  function lsSet(lista) { localStorage.setItem('denuncias', JSON.stringify(lista)); }

  // ── Denúncias ────────────────────────────────────────────────
  async function criarDenuncia(dados) {
    if (await estaOnline()) {
      const res = await fetch(`${BASE}/denuncias`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dados),
      });
      if (res.ok) return res.json();                 // 201 Created
      if (res.status === 400) throw new Error(await erroDa(res));
    }
    const lista = lsGet();
    const nova = {
      id: '#' + new Date().getFullYear() + '-' + String(Math.floor(Math.random() * 99999)).padStart(5, '0'),
      ...dados,
      status: 'recebida',
      criadoEm: new Date().toLocaleDateString('pt-BR'),
      historico: [{ status: 'recebida', data: new Date().toLocaleDateString('pt-BR'), hora: new Date().toLocaleTimeString('pt-BR').slice(0, 5) }],
    };
    nova.protocolo = nova.id;
    lista.push(nova);
    lsSet(lista);
    return nova;
  }

  /**
   * Página de casos. Plano B local só com a API fora do ar; o envelope
   * local vem marcado com `local: true` para quem precisa distinguir.
   * 401/403 lançam erro de acesso (ver lerProtegido).
   */
  async function listarPagina(filtros = {}) {
    if (await estaOnline()) {
      const qs = new URLSearchParams(
        Object.fromEntries(Object.entries(filtros).filter(([, v]) => v !== '' && v != null))
      ).toString();
      const r = await lerProtegido(`/denuncias${qs ? '?' + qs : ''}`);
      if (r !== FORA_DO_AR) return r;
    }
    const lista = lsGet();
    return { conteudo: lista, pagina: 0, tamanho: lista.length, totalItens: lista.length, totalPaginas: 1, temProxima: false, local: true };
  }

  /** Detalhe do caso — traz o relato. Leitura registrada em auditoria. */
  async function detalharDenuncia(id) {
    if (await estaOnline()) {
      const r = await lerProtegido(`/denuncias/${id}`, { nulo404: true });
      if (r !== FORA_DO_AR) return r;
    }
    return lsGet().find(d => d.id === id) || null;
  }

  async function buscarProtocolo(protocolo) {
    if (await estaOnline()) {
      const res = await fetch(`${BASE}/denuncias/protocolo/${encodeURIComponent(protocolo)}`);
      if (res.ok) return res.json();
      return null;
    }
    return lsGet().find(d => d.protocolo === protocolo || d.id === protocolo) || null;
  }

  async function atualizarDenuncia(id, dados) {
    if (await estaOnline()) {
      const res = await protegido(() => fetch(`${BASE}/denuncias/${id}`, {
        method: 'PUT',
        headers: authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify(dados),
      }));
      if (res.ok) return res.json();
      throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    }
    const lista = lsGet();
    const d = lista.find(x => x.id === id);
    if (d) { Object.assign(d, dados); lsSet(lista); }
    return d;
  }

  /** Exclusão lógica com motivo obrigatório. */
  async function excluirDenuncia(id, motivo) {
    if (!motivo || !motivo.trim()) throw new Error('Informe o motivo da exclusão.');
    if (await estaOnline()) {
      const res = await protegido(() =>
        fetch(`${BASE}/denuncias/${id}?motivo=${encodeURIComponent(motivo)}`, {
          method: 'DELETE',
          headers: authHeaders(),
        }));
      if (res.status === 204) return true;
      throw new Error(await erroDa(res));
    }
    lsSet(lsGet().filter(d => d.id !== id));
    return true;
  }

  async function mudarStatus(id, status, observacao) {
    if (await estaOnline()) {
      const res = await protegido(() => fetch(`${BASE}/denuncias/${id}/status`, {
        method: 'PATCH',
        headers: authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ status, observacao: observacao || null }),
      }));
      if (res.ok) return res.json();
      throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    }
    const lista = lsGet();
    const d = lista.find(x => x.id === id || x.protocolo === id);
    if (d) { d.status = status; lsSet(lista); }
    return d;
  }

  async function atribuirResponsavel(id, responsavelId) {
    if (await estaOnline()) {
      const res = await protegido(() => fetch(`${BASE}/denuncias/${id}/responsavel`, {
        method: 'PATCH',
        headers: authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ responsavelId }),
      }));
      if (res.ok) return res.json();
      throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    }
    const lista = lsGet();
    const d = lista.find(x => x.id === id);
    if (d) { d.responsavelId = responsavelId; lsSet(lista); }
    return d;
  }

  // ── Equipe ───────────────────────────────────────────────────
  async function listarEquipe() {
    if (await estaOnline()) {
      const r = await lerProtegido('/equipe');
      if (r !== FORA_DO_AR) return r;
    }
    try { return JSON.parse(localStorage.getItem('protege_equipe') || '[]'); }
    catch (_) { return []; }
  }

  async function salvarMembro(membro) {
    if (await estaOnline()) {
      const editando = !!membro.id;
      const res = await protegido(() =>
        fetch(`${BASE}/equipe${editando ? '/' + membro.id : ''}`, {
          method: editando ? 'PUT' : 'POST',
          headers: authHeaders({ 'Content-Type': 'application/json' }),
          body: JSON.stringify({ nome: membro.nome, cargo: membro.cargo, email: membro.email }),
        }));
      if (res.ok) return res.json();
      throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    }
    return membro;
  }

  async function removerMembro(id) {
    if (await estaOnline()) {
      const res = await protegido(() =>
        fetch(`${BASE}/equipe/${id}`, { method: 'DELETE', headers: authHeaders() }));
      if (res.status === 204) return true;
      throw new Error(await erroDa(res));
    }
    return true;
  }

  // ── Estatísticas (dashboard) ─────────────────────────────────
  async function estatisticas() {
    if (await estaOnline()) {
      const r = await lerProtegido('/stats');
      if (r !== FORA_DO_AR) return r;
    }
    const lista = lsGet();
    return { total: lista.length, porStatus: {}, porTipo: {}, offline: true };
  }

  /**
   * Relatorio estatistico completo (Parte 4).
   *
   * Devolve null quando a API esta fora do ar, em vez de inventar um
   * substituto local. Media e desvio calculados sobre o punhado de
   * denuncias que por acaso estao neste navegador nao descreveriam o
   * canal - e a tela ficaria indistinguivel de uma que descreve.
   */
  async function relatorioAnalitico() {
    if (!(await estaOnline())) return null;
    const r = await lerProtegido('/stats/analitico');
    return r === FORA_DO_AR ? null : r;
  }

  /**
   * Fase 7 | Correlacao, regressao e projecao de demanda (Parte 3).
   *
   * Mesmo contrato do relatorio descritivo: null com a API fora do ar (nao
   * ha plano B local, uma regressao sobre as poucas denuncias guardadas
   * neste navegador nao teria valor estatistico) e erro de acesso em
   * 401/403, sem dado substituto.
   */
  async function analisePreditiva() {
    if (!(await estaOnline())) return null;
    const r = await lerProtegido('/stats/regressao');
    return r === FORA_DO_AR ? null : r;
  }

  // ── Evidencias (arquivos anexados) ───────────────────────────

  /**
   * Anexa um arquivo a uma denuncia recem-registrada.
   *
   * Publico, identificado pelo protocolo: quem denuncia anonimamente nao tem
   * conta para autenticar. Nao ha fallback local - guardar o arquivo em
   * Base64 no localStorage foi o que a Fase 4 fazia, e era o que esbarrava
   * no teto de ~5 MB por origem do navegador.
   */
  async function anexarEvidencia(protocolo, arquivo) {
    if (!(await estaOnline())) {
      throw new Error('Anexar arquivo exige a API no ar.');
    }
    const corpo = new FormData();
    corpo.append('arquivo', arquivo);
    // Sem Content-Type manual: o navegador precisa gerar o boundary do multipart.
    const res = await fetch(`${BASE}/denuncias/protocolo/${encodeURIComponent(protocolo)}/evidencias`,
                            { method: 'POST', body: corpo });
    if (res.ok) return res.json();
    throw Object.assign(new Error(await erroDa(res)), { status: res.status });
  }

  /** Lista de anexos. 401/403 e erro do servidor lançam (a tela mostra o motivo). */
  async function listarEvidencias(idDenuncia) {
    if (!(await estaOnline())) return [];
    const r = await lerProtegido(`/denuncias/${idDenuncia}/evidencias`);
    return r === FORA_DO_AR ? [] : r;
  }

  /** Baixa o arquivo. Cada leitura gera registro de auditoria no servidor. */
  async function baixarEvidencia(id, nomeSugerido) {
    const res = await protegido(() =>
      fetch(`${BASE}/evidencias/${id}/arquivo`, { headers: authHeaders() }));
    if (!res.ok) throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    salvarComoArquivo(await res.blob(), nomeSugerido || ('evidencia-' + id));
  }

  async function removerEvidencia(id, motivo) {
    if (!motivo || !motivo.trim()) throw new Error('Informe o motivo da remocao.');
    const res = await protegido(() =>
      fetch(`${BASE}/evidencias/${id}?motivo=${encodeURIComponent(motivo)}`,
            { method: 'DELETE', headers: authHeaders() }));
    if (res.status === 204) return true;
    throw Object.assign(new Error(await erroDa(res)), { status: res.status });
  }

  // ── Exportacao ───────────────────────────────────────────────

  /** Exporta em CSV. Restrito a GESTOR e ADMIN; a operacao e auditada. */
  async function exportarCsv() {
    if (!(await estaOnline())) throw new Error('A exportacao e gerada pelo servidor.');
    const res = await protegido(() =>
      fetch(`${BASE}/exportacao/denuncias`, { headers: authHeaders() }));
    if (!res.ok) throw Object.assign(new Error(await erroDa(res)), { status: res.status });
    const hoje = new Date().toISOString().split('T')[0];
    salvarComoArquivo(await res.blob(), `protege_denuncias_${hoje}.csv`);
  }

  /** Dispara o download no navegador e devolve a URL temporaria ao sistema. */
  function salvarComoArquivo(blob, nome) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = nome;
    document.body.appendChild(a);
    a.click();
    a.remove();
    // Sem o revoke, cada download deixa o blob preso na memoria da aba.
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  // ── VigIA (IA) ───────────────────────────────────────────────
  // Fase 7: recusa do servidor (401/403 ou erro) agora chega a quem chamou.
  // Antes, um AUDITOR recebia a resposta local inventada como se fosse da IA.
  async function perguntarVigia(pergunta) {
    if (await estaOnline()) {
      const r = await lerProtegido('/vigia/perguntar', { metodo: 'POST', corpo: { pergunta } });
      if (r !== FORA_DO_AR) return r.resposta;
    }
    return 'VigIA em modo local: priorize denúncias de violência e abuso e as paradas há mais tempo.';
  }

  async function reanalisar(id) {
    if (await estaOnline()) {
      const r = await lerProtegido(`/vigia/analisar/${id}`, { metodo: 'POST' });
      if (r !== FORA_DO_AR) return r;
    }
    return null;
  }

  async function statusIa() {
    if (await estaOnline()) {
      const res = await fetch(`${BASE}/vigia/status`);
      if (res.ok) return res.json();
    }
    return { iaAtiva: false, modo: 'Local' };
  }

  // ── Fluxo de atendimento: fila de prioridade e pilha de ações ──
  async function consultarFila(limite = 10) {
    if (await estaOnline()) {
      const r = await lerProtegido(`/fluxo/fila?limite=${encodeURIComponent(limite)}`);
      if (r !== FORA_DO_AR) return r;
    }
    return null;
  }

  async function atenderProximo() {
    const res = await protegido(() =>
      fetch(`${BASE}/fluxo/fila/atender`, { method: 'POST', headers: authHeaders() }));
    if (res.ok) return res.json();
    throw new Error(await erroDa(res));
  }

  async function consultarPilha() {
    if (await estaOnline()) {
      const r = await lerProtegido('/fluxo/pilha');
      if (r !== FORA_DO_AR) return r;
    }
    return null;
  }

  async function desfazerUltima() {
    const res = await protegido(() =>
      fetch(`${BASE}/fluxo/desfazer`, { method: 'POST', headers: authHeaders() }));
    if (res.ok) return res.json();
    throw new Error(await erroDa(res));
  }

  // ── Trilha de auditoria (perfis AUDITOR e ADMIN) ──
  async function consultarAuditoria(filtros = {}) {
    const qs = new URLSearchParams(
      Object.fromEntries(Object.entries(filtros).filter(([, v]) => v !== '' && v != null))
    ).toString();
    const res = await protegido(() =>
      fetch(`${BASE}/auditoria${qs ? '?' + qs : ''}`, { headers: authHeaders() }));
    if (res.status === 403) {
      const e = new Error('Seu perfil não tem permissão para consultar a trilha de auditoria.');
      e.status = 403;
      e.acessoNegado = true;
      throw e;
    }
    if (res.status === 401) throw erroAcesso(401);
    if (res.ok) return res.json();
    throw new Error(await erroDa(res));
  }

  async function verificarIntegridade() {
    const res = await protegido(() => fetch(`${BASE}/auditoria/integridade`, { headers: authHeaders() }));
    if (res.ok) return res.json();
    throw new Error(await erroDa(res));
  }

  async function acoesAuditadas() {
    const res = await protegido(() => fetch(`${BASE}/auditoria/acoes`, { headers: authHeaders() }));
    if (res.ok) return res.json();
    return {};
  }

  // ── Dispositivos de campo (Fase 6) ───────────────────────────
  // O painel le o barramento de eventos; ele nunca escreve nele. Quem
  // escreve sao os aparelhos, por rota propria e com chave de dispositivo.

  // Fase 7: null continua significando "sem API"; recusa (401/403) e erro do
  // servidor lançam, para a tela não dizer "sem conexão" quando houve recusa.
  async function listarEventosIot(origem, limite = 50) {
    if (!(await estaOnline())) return null;
    const q = new URLSearchParams({ limite: String(limite) });
    if (origem) q.set('origem', origem);
    const r = await lerProtegido(`/iot/eventos?${q}`);
    return r === FORA_DO_AR ? null : r;
  }

  async function resumoIot() {
    if (!(await estaOnline())) return null;
    const r = await lerProtegido('/iot/resumo');
    return r === FORA_DO_AR ? null : r;
  }

  // .. Focos de reincidencia (Fase 6, Parte 4) ..................
  // Leitura sensivel: saber que varios relatos anonimos descrevem a mesma
  // situacao e informacao sobre um lugar e sobre quem vive nele. A rota e
  // auditada no servidor, e aqui nao ha plano B em localStorage: sem API,
  // a tela diz que nao ha analise, em vez de inventar agrupamento.

  async function listarFocos(dias = 90) {
    if (!(await estaOnline())) return null;
    const r = await lerProtegido(`/reincidencia/focos?dias=${encodeURIComponent(dias)}`);
    return r === FORA_DO_AR ? null : r;
  }

  /** Parâmetros de exibição: na falha a tela usa os padrões, sem erro. */
  async function parametrosReincidencia() {
    if (!(await estaOnline())) return null;
    try {
      const r = await lerProtegido('/reincidencia/parametros');
      return r === FORA_DO_AR ? null : r;
    } catch (_) {
      return null;
    }
  }

  return {
    BASE, estaOnline, reavaliarConexao, modoLocal,
    login, logout, perfilAtual, trocarPerfil, podeTrocarPerfil,
    criarDenuncia, listarPagina, detalharDenuncia, buscarProtocolo,
    atualizarDenuncia, excluirDenuncia, mudarStatus, atribuirResponsavel,
    listarEquipe, salvarMembro, removerMembro,
    consultarFila, atenderProximo, consultarPilha, desfazerUltima,
    consultarAuditoria, verificarIntegridade, acoesAuditadas,
    estatisticas, relatorioAnalitico, analisePreditiva, perguntarVigia, reanalisar, statusIa,
    anexarEvidencia, listarEvidencias, baixarEvidencia, removerEvidencia, exportarCsv,
    listarEventosIot, resumoIot,
    listarFocos, parametrosReincidencia,
  };
})();

window.Backend = Backend;
