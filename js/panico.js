/**
 * panico.js — Botão de Pânico / Saída Rápida
 *
 * Reforça o diferencial do Protege+: proteger quem denuncia com medo.
 * Uma faixa sempre visível permite sair do site INSTANTANEAMENTE,
 * substituindo a página por um site neutro e tentando limpar o rastro.
 *
 * Atalhos:
 *   • Clique no botão "Sair agora"
 *   • Tecla ESC pressionada 2x rapidamente
 *   • Tecla SHIFT pressionada 3x em até 5 segundos (Fase 7, padrão do
 *     componente "Exit this page" do GOV.UK, testado com vítimas de
 *     violência doméstica)
 *
 * Fase 7: antes de sair, apaga o que o site guardou neste navegador
 * (localStorage e sessionStorage) e descarta o login. Sair rápido não
 * adianta se o rascunho da denúncia continua no aparelho para quem
 * pegar o celular depois.
 *
 * Diferença para o Modo Seguro: o Modo Seguro DISFARÇA a tela (vira um
 * buscador). O Pânico SAI de vez, levando para fora do site.
 */

const Panico = (() => {

  // Para onde a saída leva (site neutro e comum)
  const DESTINO = 'https://www.google.com';

  let escTimer = null;
  let escCount = 0;
  let shiftTimer = null;
  let shiftCount = 0;

  function init() {
    // injeta a faixa se ainda não existir
    if (!document.getElementById('panico-bar')) _injetarBarra();

    // Atalho de teclado: ESC 2x rápido
    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape') return;
      escCount++;
      if (escCount >= 2) { sair(); return; }
      clearTimeout(escTimer);
      escTimer = setTimeout(() => { escCount = 0; }, 600);
    });

    // Atalho do GOV.UK: SHIFT 3x em até 5 s. Fica ao lado do ESC porque o
    // ESC sozinho também fecha o Modo Seguro e outros diálogos.
    //
    // Duas travas para não expulsar quem está escrevendo a denúncia: (1) o
    // atalho não vale com o foco num campo de texto, e (2) as três teclas
    // precisam ser SHIFT seguidos; qualquer outra tecla zera a contagem.
    // Sem isso, digitar "Meu marido João me bateu em Osasco. Tenho medo."
    // (três maiúsculas) levava a pessoa para fora do site e apagava o rascunho.
    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Shift') { shiftCount = 0; return; }
      if (e.repeat) return;
      if (_editavel(e.target)) { shiftCount = 0; return; }
      shiftCount++;
      if (shiftCount === 1) {
        clearTimeout(shiftTimer);
        shiftTimer = setTimeout(() => { shiftCount = 0; }, 5000);
      }
      if (shiftCount >= 3) { shiftCount = 0; sair(); }
    });
  }

  /** Campo onde a pessoa está digitando: o atalho de SHIFT não vale ali. */
  function _editavel(el) {
    if (!el) return false;
    const tag = (el.tagName || '').toLowerCase();
    return tag === 'input' || tag === 'textarea' || tag === 'select' || !!el.isContentEditable;
  }

  function _injetarBarra() {
    const bar = document.createElement('div');
    bar.id = 'panico-bar';
    bar.innerHTML = `
      <span class="panico-txt">Precisa sair rápido? Ninguém saberá que você esteve aqui.</span>
      <button class="panico-btn" onclick="Panico.sair()">
        <span>✕ Sair agora</span>
      </button>
      <span class="panico-dica">ou aperte ESC 2x ou SHIFT 3x</span>
    `;
    document.body.appendChild(bar);
    document.body.classList.add('panico-ativo');   // landing começa visível
  }

  // Mostra a faixa (landing / área pública)
  function mostrar() {
    const bar = document.getElementById('panico-bar');
    if (bar) bar.style.display = 'flex';
    document.body.classList.add('panico-ativo');
  }

  // Esconde a faixa (painel do gestor — não faz sentido lá)
  function esconder() {
    const bar = document.getElementById('panico-bar');
    if (bar) bar.style.display = 'none';
    document.body.classList.remove('panico-ativo');
  }

  /** Apaga o rastro local: rascunhos, lista offline, preferências e login. */
  function limparRastro() {
    try { if (typeof Backend !== 'undefined') Backend.logout(); } catch (_) {}
    try { localStorage.clear(); } catch (_) {}
    try { sessionStorage.clear(); } catch (_) {}
  }

  function sair() {
    // 0) Fase 7: limpa o que o site guardou neste aparelho
    limparRastro();

    // 1) Tenta substituir todo o conteúdo imediatamente (resposta visual instantânea)
    try {
      document.documentElement.innerHTML =
        '<body style="margin:0;font-family:sans-serif;background:#fff"></body>';
    } catch (_) {}

    // 2) Tenta apagar o rastro do histórico desta página
    try {
      // substitui a entrada atual do histórico antes de sair
      history.replaceState(null, '', DESTINO);
    } catch (_) {}

    // 3) Sai do site — replace() não deixa o site no botão "voltar"
    try {
      window.location.replace(DESTINO);
    } catch (_) {
      window.location.href = DESTINO;
    }
  }

  return { init, sair, mostrar, esconder, limparRastro };
})();

document.addEventListener('DOMContentLoaded', () => {
  if (typeof Panico !== 'undefined') Panico.init();
});