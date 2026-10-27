/**
 * safe-mode.js — Modo Seguro
 * Disfarça a tela do sistema como um buscador genérico.
 * Ativado via botão "Modo Seguro". Desativado com ESC ou botão Voltar.
 */

const SafeMode = (() => {

  const SUGGESTIONS = [
    'previsão do tempo',
    'como fazer bolo de cenoura',
    'notícias de hoje',
    'receita de macarrão',
    'futebol resultado',
    'temperatura amanhã',
    'como tirar mancha de roupa',
    'horário de ônibus',
  ];

  let active = false;

  function init() {
    const overlay    = document.getElementById('safe-mode-overlay');
    const safeInput  = document.getElementById('safe-search-input');
    const sugBox     = document.getElementById('safe-suggestions');
    const backBtn    = document.getElementById('safe-back-btn');

    if (!overlay) return;

    // ESC para sair
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape' && active) deactivate();
    });

    // Botão Voltar
    backBtn?.addEventListener('click', deactivate);

    // Campo de busca — sugestões e submit
    safeInput?.addEventListener('input', () => {
      const val = safeInput.value.trim().toLowerCase();
      if (val.length === 0) {
        sugBox.innerHTML = _buildSuggestions(SUGGESTIONS.slice(0, 3));
        sugBox.classList.add('visible');
      } else {
        const filtered = SUGGESTIONS.filter(s => s.includes(val)).slice(0, 4);
        if (filtered.length) {
          sugBox.innerHTML = _buildSuggestions(filtered);
          sugBox.classList.add('visible');
        } else {
          sugBox.classList.remove('visible');
        }
      }
    });

    safeInput?.addEventListener('focus', () => {
      sugBox.innerHTML = _buildSuggestions(SUGGESTIONS.slice(0, 3));
      sugBox.classList.add('visible');
    });

    safeInput?.addEventListener('blur', () => {
      // delay para permitir clique na sugestão
      setTimeout(() => sugBox.classList.remove('visible'), 200);
    });

    safeInput?.addEventListener('keydown', e => {
      if (e.key === 'Enter') {
        const q = safeInput.value.trim() || 'pesquisa';
        _goToResults(q);
      }
    });

    document.getElementById('safe-search-btn')?.addEventListener('click', () => {
      const q = safeInput?.value.trim() || 'pesquisa';
      _goToResults(q);
    });
  }

  function activate() {
    active = true;
    const overlay = document.getElementById('safe-mode-overlay');
    if (overlay) overlay.classList.add('active');
    document.title = 'Search';
    document.getElementById('safe-search-input')?.focus();
  }

  function deactivate() {
    active = false;
    const overlay = document.getElementById('safe-mode-overlay');
    if (overlay) overlay.classList.remove('active');
    document.title = 'Protege+ | Canal Nacional de Denúncias';
  }

  function toggle() {
    active ? deactivate() : activate();
  }

  /**
   * Navega para a página de resultados fake interna.
   *
   * Fase 7: usa location.replace em vez de location.href. Com href, a página
   * do Protege+ ficava no histórico e o botão "voltar" do navegador trazia
   * o canal de denúncia de volta à tela, exatamente a falha mais comum que a
   * pesquisa de Turk e Hutchings (CHI 2023) encontrou em botões de saída. A
   * busca vai em sessionStorage, que some ao fechar a aba.
   */
  function _goToResults(query) {
    const encoded = encodeURIComponent(query);
    try { sessionStorage.setItem('safeSearchQuery', query); } catch (_) {}
    window.location.replace(`search.html?q=${encoded}`);
  }

  function _buildSuggestions(list) {
    return list.map(s => `
      <div class="safe-suggestion" onmousedown="SafeMode.pickSuggestion('${s}')">
        <i class="fa-solid fa-magnifying-glass"></i>
        <span>${s}</span>
      </div>`).join('');
  }

  function pickSuggestion(text) {
    const input = document.getElementById('safe-search-input');
    if (input) {
      input.value = text;
      _goToResults(text);
    }
  }

  return { init, activate, deactivate, toggle, pickSuggestion };
})();