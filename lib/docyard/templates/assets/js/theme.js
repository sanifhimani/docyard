// Docyard Theme JavaScript
// Handles dark/light theme toggling

(function() {
  'use strict';

  function initThemeToggle() {
    const toggle = document.querySelector('.theme-toggle');
    if (!toggle) return;

    toggle.addEventListener('click', function() {
      const html = document.documentElement;
      const isDark = html.classList.contains('dark');
      const newTheme = isDark ? 'light' : 'dark';

      html.classList.toggle('dark', !isDark);
      localStorage.setItem('theme', newTheme);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initThemeToggle);
  } else {
    initThemeToggle();
  }
})();
