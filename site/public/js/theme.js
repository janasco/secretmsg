// SecretMsg Dynamic Theme System (Dark, Light, System)
(function () {
  const THEME_KEY = 'secretmsg_theme';

  function getSystemTheme() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function getSavedTheme() {
    return localStorage.getItem(THEME_KEY) || 'system';
  }

  function applyTheme(theme) {
    const active = theme === 'system' ? getSystemTheme() : theme;
    const root = document.documentElement;

    if (active === 'dark') {
      root.classList.add('dark');
      root.classList.remove('light');
      root.setAttribute('data-theme', 'dark');
    } else {
      root.classList.remove('dark');
      root.classList.add('light');
      root.setAttribute('data-theme', 'light');
    }

    localStorage.setItem(THEME_KEY, theme);
    updateThemeUI(theme);

    // Dispatch event for components that need to react (e.g. Three.js canvas in dice.html)
    window.dispatchEvent(new CustomEvent('secretmsg-theme-change', { detail: { theme, active } }));
  }

  function updateThemeUI(theme) {
    // Update any theme selector buttons on the page
    document.querySelectorAll('[data-theme-btn]').forEach(btn => {
      const btnTheme = btn.getAttribute('data-theme-btn');
      if (btnTheme === theme) {
        btn.classList.add('theme-btn-active');
        btn.setAttribute('aria-pressed', 'true');
      } else {
        btn.classList.remove('theme-btn-active');
        btn.setAttribute('aria-pressed', 'false');
      }
    });

    // Update icons on toggle buttons
    const active = theme === 'system' ? getSystemTheme() : theme;
    document.querySelectorAll('[data-theme-icon]').forEach(el => {
      if (theme === 'system') {
        el.textContent = 'devices';
      } else if (theme === 'light') {
        el.textContent = 'light_mode';
      } else {
        el.textContent = 'dark_mode';
      }
    });
  }

  // Set up listeners
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (getSavedTheme() === 'system') {
        applyTheme('system');
      }
    });
  }

  // Initial apply
  applyTheme(getSavedTheme());

  // Attach global API
  window.SecretMsgTheme = {
    get: getSavedTheme,
    set: applyTheme,
    toggle: function () {
      const current = getSavedTheme();
      if (current === 'dark') applyTheme('light');
      else if (current === 'light') applyTheme('system');
      else applyTheme('dark');
    }
  };

  // Wire up any data-theme-btn clicks on DOM ready
  document.addEventListener('DOMContentLoaded', () => {
    updateThemeUI(getSavedTheme());
    document.querySelectorAll('[data-theme-btn]').forEach(btn => {
      btn.addEventListener('click', () => {
        const theme = btn.getAttribute('data-theme-btn');
        applyTheme(theme);
      });
    });
  });
})();
