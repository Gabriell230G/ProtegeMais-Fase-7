/**
 * auditoria.js — Consulta da trilha de auditoria (US19 e US25).
 *
 * Só os perfis AUDITOR e ADMIN acessam. Se o perfil atual não tiver
 * permissão, a API responde 403 e esta tela mostra a recusa explicitamente,
 * em vez de esconder a aba — a recusa é a demonstração de que a segregação
 * de acesso está funcionando, e ela própria fica registrada na trilha.
 *
 * A verificação de integridade recalcula toda a cadeia de hashes e aponta
 * o primeiro elo rompido, distinguindo conteúdo alterado de registro
 * removido ou inserido. Não impede adulteração: impede que ela passe
 * despercebida.
 *
 * A tabela é montada por JavaScript, então data-i18n não a alcança: o módulo
 * escuta 'protege:idioma' e recarrega a página corrente (US14).
 *
 * Fase 7 | A mesma aba mostra os backups do banco (GET/POST /api/backup):
 * o AUDITOR confere a lista, só o ADMIN vê o botão de gerar. Cada arquivo é
 * comparado com o SHA-256 registrado na hora da cópia (trilha ou manifesto).
 */
const Auditoria = (() => {

  function T(chave, padrao) {
    return (typeof I18n !== 'undefined' && I18n.t) ? I18n.t(chave) : padrao;
  }

  const COR_ACAO = {
    LOGIN: '#16A34A', LOGIN_NEGADO: '#DC2626',
    CONSULTA_SENSIVEL: '#7C3AED', ALTERACAO_STATUS: '#2563EB',
    ALTERACAO_DADOS: '#2563EB', ATRIBUICAO: '#0891B2',
    EXCLUSAO: '#DC2626', EXPORTACAO: '#EA580C',
    REANALISE_IA: '#D97706', ALTERACAO_EQUIPE: '#0891B2',
    ACESSO_AUDITORIA: '#64748B',
  };

  let pagina = 0;
  const TAMANHO = 25;

  // Delegado ao helper global (storage-guard.js). A versão anterior, via
  // textContent/innerHTML, não escapava aspas e deixava atributos vulneráveis.
  function esc(t) { return escHtml(t); }

  function filtros() {
    const v = id => (document.getElementById(id) || {}).value || '';
    return {
      usuario: v('aud-f-usuario'),
      acao: v('aud-f-acao'),
      inicio: v('aud-f-inicio') ? v('aud-f-inicio') + 'T00:00:00' : '',
      fim: v('aud-f-fim') ? v('aud-f-fim') + 'T23:59:59' : '',
      pagina,
      tamanho: TAMANHO,
    };
  }

  async function carregar(novaPagina) {
    if (typeof novaPagina === 'number') pagina = Math.max(0, novaPagina);
    const corpo = document.getElementById('aud-tbody');
    const info = document.getElementById('aud-info');
    if (!corpo) return;

    corpo.innerHTML = `<tr><td colspan="7" class="aud-vazio">${esc(T('aud.carregando', 'Carregando…'))}</td></tr>`;

    let page;
    try {
      page = await Backend.consultarAuditoria(filtros());
    } catch (e) {
      const negado = e.status === 403;
      corpo.innerHTML = `<tr><td colspan="7" class="aud-vazio ${negado ? 'negado' : 'erro'}">
        ${negado ? '🚫 <b>' + esc(T('aud.negado', 'Acesso negado.')) + '</b> ' : '❌ '}${esc(e.message)}
        ${negado ? '<br><span class="aud-nota">' + esc(T('aud.negado_nota',
            'Esta tentativa foi registrada na própria trilha de auditoria.')) + '</span>' : ''}
      </td></tr>`;
      if (info) info.textContent = '';
      return;
    }

    if (info) {
      info.textContent = `${page.totalItens} ${T('aud.registros', 'registro(s)')} · `
        + `${T('aud.pagina', 'página')} ${page.pagina + 1} ${T('aud.de', 'de')} ${Math.max(page.totalPaginas, 1)}`;
    }
    const ant = document.getElementById('aud-ant');
    const prox = document.getElementById('aud-prox');
    if (ant) ant.disabled = page.pagina === 0;
    if (prox) prox.disabled = !page.temProxima;

    if (!page.conteudo.length) {
      corpo.innerHTML = `<tr><td colspan="7" class="aud-vazio">${esc(T('aud.vazio',
        'Nenhum registro de auditoria para os filtros selecionados.'))}</td></tr>`;
      return;
    }

    const rotuloAnterior = T('aud.hash_ant', 'hash anterior');
    const rotuloHash = T('aud.hash', 'hash');

    corpo.innerHTML = page.conteudo.map(a => {
      const cor = COR_ACAO[a.acao] || '#64748B';
      const negado = a.resultado !== 'PERMITIDO';
      return `<tr class="${negado ? 'aud-negado' : ''}">
        <td class="aud-dh">${esc((a.dataHora || '').replace('T', ' ').slice(0, 19))}</td>
        <td>${esc(a.usuario || '—')}<div class="aud-perfil">${esc(a.perfil || '')}</div></td>
        <td><span class="aud-acao" style="background:${cor}1a;color:${cor}">${esc(a.acao)}</span></td>
        <td>${esc(a.recurso || '—')}${a.recursoId ? ' <b>#' + esc(a.recursoId) + '</b>' : ''}</td>
        <td><span class="aud-result ${negado ? 'neg' : 'ok'}">${esc(a.resultado)}</span></td>
        <td class="aud-ip">${esc(a.origemIp || '—')}</td>
        <td class="aud-hash" title="${esc(rotuloAnterior)}: ${esc(a.hashAnterior)}&#10;${esc(rotuloHash)}: ${esc(a.hash)}">
          ${esc((a.hashAnterior || '').slice(0, 8))} → ${esc((a.hash || '').slice(0, 8))}
        </td>
      </tr>`;
    }).join('');
  }

  async function verificarIntegridade() {
    const painel = document.getElementById('aud-integridade');
    if (!painel) return;
    // Sai do controle do data-i18n: a partir daqui o texto e o resultado da
    // verificacao, nao o aviso estatico da tela.
    painel.removeAttribute('data-i18n');
    painel.className = 'aud-integridade verificando';
    painel.innerHTML = esc(T('aud.recalculando', 'Recalculando a cadeia de hashes…'));
    try {
      const r = await Backend.verificarIntegridade();
      if (r.integra) {
        painel.className = 'aud-integridade ok';
        painel.innerHTML = `✅ <b>${esc(T('aud.integra', 'Cadeia íntegra.'))}</b> ${esc(r.totalDeRegistros)} `
          + esc(T('aud.integra_sub', 'registros foram recalculados e todos os elos conferem.'));
      } else {
        painel.className = 'aud-integridade falha';
        painel.innerHTML = `🚨 <b>${esc(T('aud.rompida', 'Cadeia rompida no registro'))} #${esc(r.rompidoNoRegistro)}.</b> ${esc(r.motivo)}`;
      }
    } catch (e) {
      painel.className = 'aud-integridade falha';
      painel.innerHTML = '❌ ' + esc(e.message);
    }
  }

  async function popularAcoes() {
    const sel = document.getElementById('aud-f-acao');
    if (!sel || sel.dataset.pronto) return;
    try {
      const acoes = await Backend.acoesAuditadas();
      Object.keys(acoes).sort().forEach(a => {
        const o = document.createElement('option');
        o.value = a;
        o.textContent = a.replace(/_/g, ' ').toLowerCase();
        o.title = acoes[a];
        sel.appendChild(o);
      });
      sel.dataset.pronto = '1';
    } catch (_) { /* perfil sem acesso: o filtro fica só com "todas" */ }
  }

  function limpar() {
    ['aud-f-usuario', 'aud-f-acao', 'aud-f-inicio', 'aud-f-fim']
      .forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });
    carregar(0);
  }

  // ── Backups do banco (Fase 7, pilar Disponibilidade) ─────────────
  // GET /api/backup: AUDITOR e ADMIN conferem a lista. POST: só ADMIN gera.
  // A tela só esconde o botão; quem decide é o servidor (403 para os demais).
  // Não há plano B local: um backup é um arquivo do servidor.

  let backups = null;        // última resposta de GET /api/backup
  let seqBackup = 0;         // descarta respostas de pedidos já superados
  let gerando = false;
  let papelBackup = null;    // perfil para o qual a lista foi montada

  const $ = id => document.getElementById(id);
  const podeBackup = acao => typeof Acesso !== 'undefined' && Acesso.pode(acao);
  const LOCALE = () => (typeof I18n !== 'undefined' && I18n.atual && I18n.atual() === 'en') ? 'en-US' : 'pt-BR';

  /** "protege-20261027-203428-469.zip" → "2026-10-27 20:34:28" (hora do servidor). */
  function dataDoArquivo(nome) {
    const m = /^protege-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})-\d{3}\.zip$/.exec(String(nome || ''));
    return m ? `${m[1]}-${m[2]}-${m[3]} ${m[4]}:${m[5]}:${m[6]}` : '-';
  }

  function tamanhoLegivel(bytes) {
    const n = Number(bytes);
    if (!Number.isFinite(n) || n < 0) return '-';
    const UN = ['B', 'KB', 'MB', 'GB', 'TB'];
    let v = n, i = 0;
    while (v >= 1024 && i < UN.length - 1) { v /= 1024; i++; }
    const casas = i === 0 || v >= 10 ? 0 : 1;
    return v.toLocaleString(LOCALE(), { minimumFractionDigits: casas, maximumFractionDigits: casas }) + ' ' + UN[i];
  }

  const SITUACAO = {
    'integro':      { cls: 'ok',  icone: '✓',  rot: ['aud.bkp.sit.integro', 'íntegro'],
                      dica: ['aud.bkp.sit.integro_dica', 'O arquivo bate com o hash registrado no momento da cópia.'] },
    'ALTERADO':     { cls: 'alt', icone: '⚠', rot: ['aud.bkp.sit.alterado', 'ALTERADO'],
                      dica: ['aud.bkp.sit.alterado_dica', 'O arquivo não bate com o hash registrado. Não restaure este backup.'] },
    'sem registro': { cls: 'sem', icone: '○', rot: ['aud.bkp.sit.sem', 'sem registro'],
                      dica: ['aud.bkp.sit.sem_dica', 'Não há hash registrado para este arquivo: o sistema não reconhece esta cópia.'] },
  };

  const FONTES = {
    trilha:    ['aud.bkp.fonte.trilha', 'trilha'],
    manifesto: ['aud.bkp.fonte.manifesto', 'manifesto'],
  };

  // Valor vindo do servidor nunca indexa o objeto direto ("constructor" etc.).
  const proprio = (obj, chave) => Object.prototype.hasOwnProperty.call(obj, chave) ? obj[chave] : null;

  function linhaBackup(texto, classe) {
    return `<tr><td colspan="5" class="aud-vazio ${classe || ''}">${texto}</td></tr>`;
  }

  /** Mostra (ou limpa, com tipo null) o aviso do card. Todo texto é escapado. */
  function alertaBackup(tipo, icone, titulo, detalhe) {
    const el = $('bkp-alerta');
    if (!el) return;
    if (!tipo) { el.hidden = true; el.innerHTML = ''; return; }
    el.className = 'bkp-alerta ' + tipo;
    el.innerHTML = `${esc(icone)} <b>${esc(titulo)}</b>${detalhe ? ' ' + esc(detalhe) : ''}`;
    el.hidden = false;
  }

  /** Mostra o card só para quem lê backups e o botão só para quem gera. */
  function aplicarPerfil() {
    const card = $('bkp-card');
    if (!card) return;
    const papel = typeof Acesso !== 'undefined' ? Acesso.papel() : null;
    if (papel !== papelBackup) {
      // Perfil novo não herda a lista nem o aviso montados para o anterior.
      papelBackup = papel;
      backups = null;
      seqBackup++;
      const corpo = $('bkp-tbody');
      if (corpo) corpo.innerHTML = '';
      const resumo = $('bkp-resumo');
      if (resumo) resumo.innerHTML = '';
      alertaBackup(null);
    }
    card.hidden = !podeBackup('verBackup');
    const btn = $('bkp-gerar');
    if (btn) btn.hidden = !podeBackup('gerarBackup');
  }

  function rotuloBotao() {
    const btn = $('bkp-gerar');
    if (!btn) return;
    btn.textContent = gerando ? T('aud.bkp.gerando', 'Gerando…') : T('aud.bkp.gerar', 'Gerar backup agora');
    btn.disabled = gerando || !!(backups && backups.suportado === false);
  }

  function renderBackups() {
    const corpo = $('bkp-tbody');
    const resumo = $('bkp-resumo');
    if (!corpo || !backups) return;
    rotuloBotao();
    const lista = Array.isArray(backups.backups) ? backups.backups : [];
    const conta = s => lista.filter(b => b && b.situacao === s).length;
    const total = Number.isFinite(Number(backups.total)) ? Number(backups.total) : lista.length;
    const integros = Number.isFinite(Number(backups.integros)) ? Number(backups.integros) : conta('integro');
    const alterados = conta('ALTERADO');
    const semRegistro = conta('sem registro');

    if (resumo) {
      let h = `<span><b>${esc(total)}</b> ${esc(T('aud.bkp.qtd', 'backup(s)'))}</span>`
            + `<span><b>${esc(integros)}</b> ${esc(T('aud.bkp.qtd_integros', 'íntegro(s)'))}</span>`;
      if (alterados) h += `<span class="alt"><b>${esc(alterados)}</b> ${esc(T('aud.bkp.qtd_alterados', 'ALTERADO(s): não restaure'))}</span>`;
      if (semRegistro) h += `<span class="sem"><b>${esc(semRegistro)}</b> ${esc(T('aud.bkp.qtd_sem', 'sem registro'))}</span>`;
      if (backups.suportado === false) {
        h += `<span class="nao-suportado">${esc(T('aud.bkp.nao_suportado',
          'Backup interno disponível apenas com o banco H2 em arquivo. No PostgreSQL, use o backup do serviço gerenciado.'))}</span>`;
      }
      resumo.innerHTML = h;
    }

    if (!lista.length) {
      corpo.innerHTML = linhaBackup(esc(T('aud.bkp.vazio', 'Nenhum backup gerado até agora.')));
      return;
    }

    const R = {
      arquivo: T('aud.bkp.th.arquivo', 'Arquivo'), data: T('aud.bkp.th.datahora', 'Data e hora'),
      tamanho: T('aud.bkp.th.tamanho', 'Tamanho'), sha: T('aud.bkp.th.sha', 'SHA-256'),
      integridade: T('aud.bkp.th.integridade', 'Integridade'),
    };
    const nenhum = T('aud.bkp.sha_nenhum', 'nenhum');
    const bytesRot = T('aud.bkp.bytes', 'bytes');

    corpo.innerHTML = lista.map(b => {
      b = b || {};
      const sit = proprio(SITUACAO, b.situacao);
      const atual = String(b.sha256Atual || '');
      const fonteConhecida = proprio(FONTES, b.fonteDoRegistro);
      const fonte = fonteConhecida ? T(fonteConhecida[0], fonteConhecida[1]) : String(b.fonteDoRegistro || '');
      const dicaHash = `${T('aud.bkp.sha_atual', 'SHA-256 atual')}: ${atual || nenhum}\n`
        + `${T('aud.bkp.sha_reg', 'SHA-256 registrado')}${fonte ? ' (' + fonte + ')' : ''}: ${b.sha256Registrado || nenhum}`;
      const badge = sit
        ? `<span class="bkp-sit ${sit.cls}" title="${escAttr(T(sit.dica[0], sit.dica[1]))}">${esc(sit.icone)} ${esc(T(sit.rot[0], sit.rot[1]))}</span>`
        : `<span class="bkp-sit sem">${esc(b.situacao || '-')}</span>`;
      const origem = fonte
        ? `<span class="bkp-fonte">${esc(T('aud.bkp.fonte', 'registro'))}: ${esc(fonte)}</span>` : '';
      const bytes = Number(b.bytes);
      return `<tr class="${sit && sit.cls === 'alt' ? 'bkp-alterado' : ''}">
        <td data-rotulo="${escAttr(R.arquivo)}"><span class="bkp-arq">${esc(b.arquivo || '-')}</span></td>
        <td data-rotulo="${escAttr(R.data)}"><span class="aud-dh">${esc(dataDoArquivo(b.arquivo))}</span></td>
        <td data-rotulo="${escAttr(R.tamanho)}"><span class="bkp-num"${Number.isFinite(bytes)
          ? ` title="${escAttr(bytes.toLocaleString(LOCALE()) + ' ' + bytesRot)}"` : ''}>${esc(tamanhoLegivel(b.bytes))}</span></td>
        <td data-rotulo="${escAttr(R.sha)}"><span class="aud-hash" title="${escAttr(dicaHash)}">${esc(atual.slice(0, 12) || '-')}</span></td>
        <td data-rotulo="${escAttr(R.integridade)}"><span class="bkp-sit-wrap">${badge}${origem}</span></td>
      </tr>`;
    }).join('');
  }

  async function carregarBackups() {
    aplicarPerfil();
    if (!podeBackup('verBackup')) return;
    const corpo = $('bkp-tbody');
    if (!corpo) return;
    const seq = ++seqBackup;
    backups = null;
    corpo.innerHTML = linhaBackup(esc(T('aud.carregando', 'Carregando…')));
    const resumo = $('bkp-resumo');
    if (resumo) resumo.innerHTML = '';

    let r;
    try {
      r = await Backend.listarBackups();
    } catch (e) {
      if (seq !== seqBackup) return;
      const negado = e.status === 401 || e.status === 403;
      corpo.innerHTML = linhaBackup(
        (negado ? '🚫 <b>' + esc(T('aud.negado', 'Acesso negado.')) + '</b> ' : '❌ ') + esc(e.message)
        + (e.status === 403 ? '<br><span class="aud-nota">' + esc(T('aud.negado_nota',
            'Esta tentativa foi registrada na própria trilha de auditoria.')) + '</span>' : ''),
        negado ? 'negado' : 'erro');
      return;
    }
    if (seq !== seqBackup) return;
    if (!r) {
      corpo.innerHTML = linhaBackup(esc(T('aud.bkp.offline', 'API fora do ar: a lista de backups vem só do servidor.')), 'erro');
      return;
    }
    backups = r;
    renderBackups();
  }

  async function gerarBackup() {
    if (gerando || !podeBackup('gerarBackup')) return;
    gerando = true;
    rotuloBotao();
    alertaBackup(null);
    try {
      const r = await Backend.gerarBackup();
      let msg = `✅ ${T('aud.bkp.ok', 'Backup gerado')}: ${r.arquivo} (${tamanhoLegivel(r.bytes)})`;
      if (Number(r.removidosPorRetencao) > 0) {
        msg += `. ${r.removidosPorRetencao} ${T('aud.bkp.removidos', 'antigo(s) removido(s) pela retenção')}`;
      }
      if (typeof showToast === 'function') showToast(msg);
      gerando = false;
      await carregarBackups();
    } catch (e) {
      if (e.status === 409) {
        // Intervalo mínimo entre backups manuais: a mensagem do servidor diz quanto falta.
        alertaBackup('aviso', '⏳', T('aud.bkp.recusado', 'Backup recusado pelo servidor.'), e.message);
      } else if (e.status === 403) {
        alertaBackup('erro', '🚫', T('aud.bkp.negado_gerar', 'Só o perfil Administrador pode gerar backups.'),
          T('aud.negado_nota', 'Esta tentativa foi registrada na própria trilha de auditoria.'));
      } else if (e.status === 401) {
        alertaBackup('erro', '🔑', e.message);
      } else {
        alertaBackup('erro', '❌', T('aud.bkp.falha', 'Não foi possível gerar o backup.'), e.message);
      }
    } finally {
      gerando = false;
      rotuloBotao();
    }
  }

  async function abrir() {
    alertaBackup(null);
    carregarBackups();          // em paralelo com a trilha; trata os próprios erros
    await popularAcoes();
    await carregar(0);
  }

  document.addEventListener('protege:idioma', () => {
    const painel = document.getElementById('tab-auditoria');
    if (painel && painel.style.display !== 'none') carregar(pagina);
    // A lista de backups é redesenhada com a resposta já recebida, sem novo pedido.
    if (backups) renderBackups(); else rotuloBotao();
  });

  return {
    abrir, carregar, limpar, verificarIntegridade,
    carregarBackups, gerarBackup, aplicarPerfil,
    anterior: () => carregar(pagina - 1),
    proxima:  () => carregar(pagina + 1),
  };
})();

window.Auditoria = Auditoria;
