(function() {
  'use strict';

  var STORAGE_KEY = 'docyard_sidebar_collapsed';

  function initSidebarToggle() {
    var toggle = document.querySelector('.breadcrumb-toggle');
    var sidebar = document.querySelector('.sidebar');

    if (!toggle || !sidebar) {
      return;
    }

    var isCollapsed = document.documentElement.classList.contains('sidebar-collapsed');
    toggle.setAttribute('aria-expanded', !isCollapsed);

    toggle.addEventListener('click', function() {
      var collapsed = document.documentElement.classList.toggle('sidebar-collapsed');
      localStorage.setItem(STORAGE_KEY, collapsed);
      toggle.setAttribute('aria-expanded', !collapsed);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSidebarToggle);
  } else {
    initSidebarToggle();
  }
})();
