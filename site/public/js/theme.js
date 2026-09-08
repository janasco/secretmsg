// SecretMsg Dual-Theme System (Light & Dark, Auto-Detecting System Preference by Default)
(function () {
  const THEME_KEY = 'secretmsg_theme';

  function getSystemTheme() {
    return (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
  }

  function getUserPreference() {
    const val = localStorage.getItem(THEME_KEY);
    if (val === 'dark' || val === 'light') return val;
    return null;
  }

  function getCurrentTheme() {
    return getUserPreference() || getSystemTheme();
  }

  function applyTheme(theme, persist = true) {
    const active = (theme === 'light') ? 'light' : 'dark';
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

    if (persist) {
      localStorage.setItem(THEME_KEY, active);
    }

    updateThemeUI(active);

    // Dispatch event for components that need to react (e.g. Three.js canvas in dice.html)
    window.dispatchEvent(new CustomEvent('secretmsg-theme-change', { detail: { theme: active, active } }));
  }

  function updateThemeUI(theme) {
    // Update any theme selector buttons on the page (Dark vs Light)
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
    document.querySelectorAll('[data-theme-icon]').forEach(el => {
      if (theme === 'light') {
        el.textContent = 'light_mode';
      } else {
        el.textContent = 'dark_mode';
      }
    });

    // Update button title/aria-label for 2-way toggle buttons
    document.querySelectorAll('button[onclick*="SecretMsgTheme.toggle"]').forEach(btn => {
      const nextTheme = theme === 'dark' ? 'Light' : 'Dark';
      btn.setAttribute('title', `Switch to ${nextTheme} Mode`);
      btn.setAttribute('aria-label', `Switch to ${nextTheme} Mode`);
    });
  }

  // Set up listeners for system color scheme changes
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      // Only auto-switch if user hasn't explicitly locked in a theme choice
      if (!getUserPreference()) {
        applyTheme(e.matches ? 'dark' : 'light', false);
      }
    });
  }

  // Initial apply (clean legacy 'system' value if found)
  const legacy = localStorage.getItem(THEME_KEY);
  if (legacy && legacy !== 'dark' && legacy !== 'light') {
    localStorage.removeItem(THEME_KEY);
  }
  applyTheme(getCurrentTheme(), Boolean(getUserPreference()));

  // Attach global API
  window.SecretMsgTheme = {
    get: getCurrentTheme,
    getUserPreference: getUserPreference,
    getSystemTheme: getSystemTheme,
    set: function (theme) {
      applyTheme(theme, true);
    },
    toggle: function () {
      const current = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
      const next = (current === 'dark') ? 'light' : 'dark';
      applyTheme(next, true);
    }
  };

  // Wire up any data-theme-btn clicks on DOM ready
  document.addEventListener('DOMContentLoaded', () => {
    updateThemeUI(getCurrentTheme());
    document.querySelectorAll('[data-theme-btn]').forEach(btn => {
      btn.addEventListener('click', () => {
        const theme = btn.getAttribute('data-theme-btn');
        if (theme === 'dark' || theme === 'light') {
          applyTheme(theme, true);
        }
      });
    });
  });
})();
