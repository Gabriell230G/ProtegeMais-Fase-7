/**
 * storage-guard.js — Proteção global de armazenamento.
 *
 * Alguns contextos (aba anônima em certos navegadores, cookies/armazenamento
 * bloqueados, políticas corporativas) fazem o localStorage LANÇAR exceção ao
 * ser lido ou gravado. Sem tratamento, isso derrubaria o site inteiro.
 *
 * Este guard testa o localStorage no início e, se ele não estiver disponível,
 * substitui por um armazenamento equivalente em memória (dura só a sessão).
 * Assim, todo o resto do código continua usando localStorage normalmente.
 *
 * DEVE ser o PRIMEIRO script carregado na página.
 *
 * Por ser o primeiro script, este arquivo também publica os helpers globais
 * de escape contra XSS (escHtml, escAttr, jsArg, dataUrlSegura), usados por
 * todos os módulos que montam HTML com dado vindo do cidadão, da API, do
 * localStorage, da URL, do IBGE ou da IA.
 */

/* ── Escape global contra injeção de HTML/script (XSS) ─────────────────
 * Este é um canal anônimo: qualquer texto de uma denúncia pode ter sido
 * escrito por um atacante e é exibido no painel do servidor público, que
 * tem token com privilégios. Toda interpolação de dado em HTML deve passar
 * por um destes helpers.
 *
 *   escHtml(v)       texto dentro de elemento (<td>${escHtml(v)}</td>)
 *   escAttr(v)       valor de atributo entre aspas (title="${escAttr(v)}")
 *   jsArg(v)         argumento de handler inline:
 *                    onclick="verDetalhes(${jsArg(id)})"
 *                    gera um literal JSON já escapado para o atributo, de
 *                    modo que aspas simples ou duplas no dado não quebram
 *                    nem injetam código no handler.
 *   dataUrlSegura(u) devolve a data: URL só se for imagem, áudio, vídeo
 *                    ou PDF em base64; caso contrário devolve ''.
 */
(function () {
  'use strict';

  var MAPA = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;', '`': '&#96;' };

  function escHtml(v) {
    if (v == null) return '';
    return String(v).replace(/[&<>"'`]/g, function (c) { return MAPA[c]; });
  }

  // Escapa o mesmo conjunto: suficiente para atributos sempre entre aspas.
  function escAttr(v) { return escHtml(v); }

  function jsArg(v) {
    var json = JSON.stringify(v === undefined ? null : v);
    // U+2028/U+2029 são válidos em JSON mas quebravam literais JS antigos.
    json = String(json).replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
    return escAttr(json);
  }

  // SVG fica de fora de propósito: pode carregar script se aberto direto.
  var DATA_URL_OK = /^data:(image\/(png|jpe?g|gif|webp|bmp|avif)|audio\/[a-z0-9.+-]+|video\/[a-z0-9.+-]+|application\/pdf)(;[a-z0-9=.+-]+)*;base64,[a-z0-9+\/=\s]*$/i;

  function dataUrlSegura(u) {
    if (typeof u !== 'string') return '';
    return DATA_URL_OK.test(u) ? u : '';
  }

  window.escHtml = escHtml;
  window.escAttr = escAttr;
  window.jsArg = jsArg;
  window.dataUrlSegura = dataUrlSegura;
})();

(function () {
  'use strict';

  function disponivel() {
    try {
      var k = '__protege_test__';
      window.localStorage.setItem(k, '1');
      window.localStorage.removeItem(k);
      return true;
    } catch (e) {
      return false;
    }
  }

  if (disponivel()) return; // tudo certo, usa o localStorage nativo

  console.warn('[Protege+] localStorage indisponível — usando armazenamento temporário em memória (não persiste após fechar a aba).');

  var mem = Object.create(null);
  var shim = {
    getItem: function (k) { return Object.prototype.hasOwnProperty.call(mem, k) ? mem[k] : null; },
    setItem: function (k, v) { mem[k] = String(v); },
    removeItem: function (k) { delete mem[k]; },
    clear: function () { mem = Object.create(null); },
    key: function (i) { return Object.keys(mem)[i] || null; },
    get length() { return Object.keys(mem).length; }
  };

  try {
    Object.defineProperty(window, 'localStorage', { value: shim, configurable: true, writable: false });
  } catch (e) {
    try { window.localStorage = shim; } catch (e2) { /* ultimo recurso: ignora */ }
  }
})();
