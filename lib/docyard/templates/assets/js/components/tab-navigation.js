(function() {
  'use strict';

  var tabIndicator;

  function updateIndicator(activeTab) {
    if (!activeTab || !tabIndicator) return;

    var rect = activeTab.getBoundingClientRect();
    var parentRect = activeTab.parentElement.getBoundingClientRect();
    var inset = 4;

    tabIndicator.style.left = (rect.left - parentRect.left + inset) + 'px';
    tabIndicator.style.width = (rect.width - (inset * 2)) + 'px';
  }

  function showIndicator() {
    if (tabIndicator) {
      tabIndicator.classList.add('is-ready');
    }
  }

  function initTabIndicator() {
    tabIndicator = document.getElementById('tabIndicator');
    var tabItems = document.querySelectorAll('.tab-item');

    if (!tabIndicator || tabItems.length === 0) {
      return;
    }

    var activeTab = document.querySelector('.tab-item.is-active');
    if (activeTab) {
      updateIndicator(activeTab);
      tabIndicator.offsetHeight;
      requestAnimationFrame(showIndicator);
    }

    window.addEventListener('resize', function() {
      var active = document.querySelector('.tab-item.is-active');
      if (active) {
        updateIndicator(active);
      }
    });
  }

  // Handle cross-document view transitions
  function initViewTransitions() {
    if (!document.startViewTransition) return;

    // Position indicator immediately when new page is revealed (before animation)
    window.addEventListener('pagereveal', function(e) {
      if (!e.viewTransition) return;

      tabIndicator = document.getElementById('tabIndicator');
      var activeTab = document.querySelector('.tab-item.is-active');

      if (activeTab && tabIndicator) {
        // Position and show indicator immediately so view transition can animate it
        updateIndicator(activeTab);
        tabIndicator.classList.add('is-ready');
      }
    });
  }

  function initNavMenu() {
    var navMenuBtn = document.getElementById('navMenuBtn');
    var navMenuOverlay = document.getElementById('navMenuOverlay');
    var navMenuDropdown = document.getElementById('navMenuDropdown');

    if (!navMenuBtn || !navMenuOverlay || !navMenuDropdown) {
      return;
    }

    var scrollPosition = 0;

    function lockBodyScroll() {
      scrollPosition = window.pageYOffset;
      document.body.style.overflow = 'hidden';
      document.body.style.position = 'fixed';
      document.body.style.top = -scrollPosition + 'px';
      document.body.style.width = '100%';
    }

    function unlockBodyScroll() {
      document.body.style.removeProperty('overflow');
      document.body.style.removeProperty('position');
      document.body.style.removeProperty('top');
      document.body.style.removeProperty('width');
      window.scrollTo(0, scrollPosition);
    }

    function openDropdown() {
      lockBodyScroll();
      navMenuOverlay.classList.add('is-visible');
      navMenuDropdown.classList.add('is-open');
      navMenuBtn.setAttribute('aria-expanded', 'true');
    }

    function closeDropdown() {
      navMenuOverlay.classList.remove('is-visible');
      navMenuDropdown.classList.remove('is-open');
      navMenuBtn.setAttribute('aria-expanded', 'false');
      unlockBodyScroll();
    }

    function toggleDropdown() {
      if (navMenuDropdown.classList.contains('is-open')) {
        closeDropdown();
      } else {
        openDropdown();
      }
    }

    navMenuBtn.addEventListener('click', toggleDropdown);
    navMenuOverlay.addEventListener('click', closeDropdown);

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && navMenuDropdown.classList.contains('is-open')) {
        closeDropdown();
      }
    });

    navMenuDropdown.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', closeDropdown);
    });

    window.addEventListener('resize', function() {
      if (window.innerWidth > 1024) {
        closeDropdown();
      }
    });
  }

  function init() {
    initViewTransitions();
    initTabIndicator();
    initNavMenu();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
