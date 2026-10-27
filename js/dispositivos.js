/**
 * dispositivos.js  .  Tela de dispositivos de campo (Fase 6)
 *
 * Mostra o barramento de eventos das tres origens fisicas: botao de panico,
 * tornozeleira com geofencing e totem publico.
 *
 * Uma decisao de honestidade atravessa este modulo: aqui NAO existe modo
 * offline com dados de exemplo. O resto do painel cai para o localStorage
 * quando a API esta fora, e isso e legitimo porque aquelas denuncias foram
 * mesmo digitadas por alguem. Um evento de dispositivo, nao. Inventar um
 * acionamento de botao de panico seria fabricar exatamente a evidencia que
 * esta tela existe para exibir, e uma central que aprende a ver alertas que
 * nao aconteceram deixa de acreditar nos que aconteceram. Sem API, a tela
 * diz que esta sem API.
 */
const Dispositivos = (() => {

  const ORIGENS = {
    SOS:      { rotulo: 'Botao de panico',  icone: '🆘', cor: '#E4572E' },
    GEOFENCE: { rotulo: 'Tornozeleira',     icone: '📍', cor: '#F5B93B' },
    TOTEM:    { rotulo: 'Totem publico',    icone: '🏛️', cor: '#3B8DE0' },
  };

  const SITUACOES = {
    ACEITO:     { rotulo: 'Aceito',     classe: 'disp-ok' },
    DUPLICADO:  { rotulo: 'Duplicado',  classe: 'disp-dup' },
    DESCARTADO: { rotulo: 'Descartado', classe: 'disp-desc' },
  };

  let filtro = '';
  let timer  = null;

  // Delegado ao helper global (storage-guard.js).
  function _esc(t) { return escHtml(t); }

  /** Horario legivel. O evento vem do servidor ja truncado em milissegundos. */
  function _hora(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d)) return _esc(iso);
    return d.toLocaleString('pt-BR', { day: '2-digit', month: '2-digit',
                                       hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }

  async function abrir() {
    await atualizar();
    // Um barramento de eventos parado na tela nao e um barramento. A cada
    // oito segundos a tela se repinta sozinha, o que tambem e o que torna a
    // demonstracao com o simulador visivel sem ninguem apertar atualizar.
    clearInterval(timer);
    timer = setInterval(atualizar, 8000);
  }

  function fechar() { clearInterval(timer); timer = null; }

  function filtrar(origem, el) {
    filtro = origem || '';
    document.querySelectorAll('.disp-filtro').forEach(b => b.classList.remove('active'));
    if (el) el.classList.add('active');
    atualizar();
  }

  async function atualizar() {
    const corpo = document.getElementById('disp-lista');
    if (!corpo) return;

    let eventos = null, resumo = null, falha = null;
    try {
      [eventos, resumo] = await Promise.all([
        Backend.listarEventosIot(filtro, 60),
        Backend.resumoIot(),
      ]);
    } catch (e) {
      console.warn('[Dispositivos] falha ao consultar o barramento:', e);
      falha = e;
    }

    _pintarResumo(resumo);

    // Fase 7: recusa (401/403) ou erro da API no ar nao e "sem conexao".
    if (falha && (falha.acessoNegado || falha.status)) {
      const titulo = falha.status === 401 ? 'Faça login novamente'
                   : falha.status === 403 ? 'Seu perfil não tem acesso a este conteúdo'
                   : falha.message;
      corpo.innerHTML = `
        <div class="disp-vazio">
          <div class="disp-vazio-ic">${falha.status === 401 ? '🔑' : falha.status === 403 ? '🚫' : '❌'}</div>
          <p><strong>${_esc(titulo)}</strong></p>
          <p class="disp-vazio-dica">O servidor recusou a consulta ao barramento de eventos.</p>
        </div>`;
      return;
    }

    if (eventos === null) {
      corpo.innerHTML = `
        <div class="disp-vazio">
          <div class="disp-vazio-ic">🔌</div>
          <p><strong>Sem conexao com a API.</strong></p>
          <p>Esta tela nao tem modo de demonstracao offline: um evento de
             dispositivo so aparece aqui se um dispositivo o enviou de verdade.</p>
          <p class="disp-vazio-dica">Suba o backend e abra o simulador em
             <code>simulador-iot.html</code>.</p>
        </div>`;
      return;
    }

    if (!eventos.length) {
      corpo.innerHTML = `
        <div class="disp-vazio">
          <div class="disp-vazio-ic">📡</div>
          <p><strong>Nenhum evento recebido ainda.</strong></p>
          <p class="disp-vazio-dica">Abra <code>simulador-iot.html</code> e acione um aparelho.</p>
        </div>`;
      return;
    }

    corpo.innerHTML = `
      <table class="disp-tabela">
        <thead>
          <tr>
            <th>Recebido</th><th>Origem</th><th>Dispositivo</th><th>Coordenadas</th>
            <th>Situacao</th><th>Protocolo</th><th>O que o servidor decidiu</th>
          </tr>
        </thead>
        <tbody>${eventos.map(_linha).join('')}</tbody>
      </table>`;
  }

  function _linha(e) {
    const o = ORIGENS[e.origem]   || { rotulo: e.origem, icone: '📟', cor: '#8894A6' };
    const s = SITUACOES[e.situacao] || { rotulo: e.situacao, classe: 'disp-desc' };
    return `
      <tr>
        <td class="disp-hora">${_hora(e.recebidoEm)}</td>
        <td><span class="disp-org" style="--c:${_esc(o.cor)}">${_esc(o.icone)} ${_esc(o.rotulo)}</span></td>
        <td class="disp-mono">${_esc(e.dispositivo)}</td>
        <td class="disp-mono">${_coordenadas(e)}</td>
        <td><span class="disp-sit ${_esc(s.classe)}">${_esc(s.rotulo)}</span></td>
        <td class="disp-mono">${e.protocoloGerado ? _esc(e.protocoloGerado) : '<span class="disp-nulo">nao gerou caso</span>'}</td>
        <td class="disp-det">${_esc(e.detalhe)}</td>
      </tr>`;
  }

  /**
   * Fase 7: para o ATENDENTE o servidor arredonda lat/lng a 3 casas (cerca
   * de 100 m). A tela diz isso, para ninguem tomar a regiao por um endereco.
   */
  function _coordenadas(e) {
    const lat = Number(e.latitude), lng = Number(e.longitude);
    if (e.latitude == null || e.longitude == null || !isFinite(lat) || !isFinite(lng)) {
      return '<span class="disp-nulo">sem coordenada</span>';
    }
    const aprox = typeof Acesso !== 'undefined' && Acesso.papel() === 'analista';
    const casas = aprox ? 3 : 5;
    const txt = _esc(lat.toFixed(casas) + ', ' + lng.toFixed(casas));
    return aprox
      ? `${txt}<br><span class="disp-nulo" title="O servidor arredonda a coordenada para o seu perfil">aproximadas (±100 m)</span>`
      : txt;
  }

  function _pintarResumo(resumo) {
    Object.keys(ORIGENS).forEach(k => {
      const el = document.getElementById('disp-kpi-' + k.toLowerCase());
      if (el) el.textContent = resumo && resumo[k] != null ? resumo[k] : '.';
    });
  }

  return { abrir, fechar, filtrar, atualizar };
})();

window.Dispositivos = Dispositivos;
