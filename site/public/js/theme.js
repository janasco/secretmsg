// SecretMsg Theme System (Light, Dark, and Follow System Settings default)
(function () {
  const THEME_KEY = 'secretmsg_theme';

  function getSystemTheme() {
    return (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
  }

  function getUserPreference() {
    const val = localStorage.getItem(THEME_KEY);
    if (val === 'dark' || val === 'light' || val === 'system') return val;
    return 'system'; // default
  }

  function getEffectiveTheme() {
    const pref = getUserPreference();
    if (pref === 'dark') return 'dark';
    if (pref === 'light') return 'light';
    return getSystemTheme();
  }

  function applyTheme(pref, persist = true) {
    const preference = (pref === 'light' || pref === 'dark' || pref === 'system') ? pref : 'system';
    const effective = (preference === 'system') ? getSystemTheme() : preference;
    const root = document.documentElement;

    if (effective === 'dark') {
      root.classList.add('dark');
      root.classList.remove('light');
      root.setAttribute('data-theme', 'dark');
    } else {
      root.classList.remove('dark');
      root.classList.add('light');
      root.setAttribute('data-theme', 'light');
    }

    if (persist) {
      localStorage.setItem(THEME_KEY, preference);
    }

    updateThemeUI(effective, preference);

    // Dispatch event for components that need to react (e.g. Three.js canvas in dice.html)
    window.dispatchEvent(new CustomEvent('secretmsg-theme-change', { detail: { theme: effective, preference } }));
  }

  function updateThemeUI(effective, preference) {
    const currentPref = preference || getUserPreference();
    const currentEffective = effective || getEffectiveTheme();

    // Update 3-way or 2-way theme selector buttons on the page
    document.querySelectorAll('[data-theme-btn]').forEach(btn => {
      const btnTheme = btn.getAttribute('data-theme-btn');
      const isActive = (btnTheme === currentPref) || (!currentPref && btnTheme === 'system');
      if (isActive) {
        btn.classList.add('theme-btn-active', 'bg-white', 'text-[#0B0E14]', 'font-bold', 'shadow-sm');
        btn.classList.remove('text-slate-300', 'hover:text-white');
        btn.setAttribute('aria-pressed', 'true');
      } else {
        btn.classList.remove('theme-btn-active', 'bg-white', 'text-[#0B0E14]', 'font-bold', 'shadow-sm');
        btn.classList.add('text-slate-300', 'hover:text-white');
        btn.setAttribute('aria-pressed', 'false');
      }
    });

    // Update icons on toggle buttons
    document.querySelectorAll('[data-theme-icon]').forEach(el => {
      el.textContent = (currentEffective === 'light') ? 'light_mode' : 'dark_mode';
    });

    // Update button title/aria-label for 2-way toggle buttons
    document.querySelectorAll('button[onclick*="SecretMsgTheme.toggle"]').forEach(btn => {
      const nextTheme = currentEffective === 'dark' ? 'Light' : 'Dark';
      btn.setAttribute('title', `Switch to ${nextTheme} Mode`);
      btn.setAttribute('aria-label', `Switch to ${nextTheme} Mode`);
    });
  }

  // Set up listeners for system color scheme changes
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      const pref = getUserPreference();
      if (pref === 'system') {
        applyTheme('system', false);
      }
    });
  }

  // Initial apply
  applyTheme(getUserPreference(), false);

  // Attach global API
  window.SecretMsgTheme = {
    get: getEffectiveTheme,
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
    updateThemeUI(getEffectiveTheme(), getUserPreference());
    document.querySelectorAll('[data-theme-btn]').forEach(btn => {
      btn.addEventListener('click', () => {
        const theme = btn.getAttribute('data-theme-btn');
        if (theme === 'dark' || theme === 'light' || theme === 'system') {
          applyTheme(theme, true);
        }
      });
    });

    // Auto-load SecretMsg Native Mobile Bridge if running in a mobile app context
    if (!window.SecretMsgNative && !document.querySelector('script[src*="mobile-bridge.js"]')) {
      const bridgeScript = document.createElement('script');
      bridgeScript.src = (window.location.pathname.startsWith('/p/') || window.location.pathname.startsWith('/m/')) ? '/js/mobile-bridge.js' : 'js/mobile-bridge.js';
      bridgeScript.async = true;
      document.head.appendChild(bridgeScript);
    }
  });
})();
