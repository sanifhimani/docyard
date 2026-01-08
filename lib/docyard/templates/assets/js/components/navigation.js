(function() {
  'use strict';

  function initMobileMenu() {
    const toggle = document.querySelector('.secondary-header-menu');
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.querySelector('.mobile-overlay');

    if (!toggle || !sidebar || !overlay) {
      return;
    }

    function openMenu() {
      sidebar.classList.add('is-open');
      overlay.classList.add('is-visible');
      toggle.setAttribute('aria-expanded', 'true');
      document.body.style.overflow = 'hidden';
    }

    function closeMenu() {
      sidebar.classList.remove('is-open');
      overlay.classList.remove('is-visible');
      toggle.setAttribute('aria-expanded', 'false');
      document.body.style.overflow = '';
    }

    function toggleMenu() {
      if (sidebar.classList.contains('is-open')) {
        closeMenu();
      } else {
        openMenu();
      }
    }

    toggle.addEventListener('click', function(e) {
      toggleMenu();
    });
    overlay.addEventListener('click', closeMenu);

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && sidebar.classList.contains('is-open')) {
        closeMenu();
      }
    });

    sidebar.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', closeMenu);
    });
  }

  function initAccordion() {
    var TOGGLE_STATE_KEY = 'docyard_toggle_states';
    var toggles = document.querySelectorAll('[data-nav-toggle]');

    toggles.forEach(function(toggle) {
      toggle.addEventListener('click', function(e) {
        var expanded = toggle.getAttribute('aria-expanded') === 'true';
        var navGroup = toggle.closest('.nav-group');
        var children = navGroup ? navGroup.querySelector('.nav-group-children') : null;

        if (!children) {
          return;
        }

        // For links, save toggle state to sessionStorage before navigation
        if (toggle.tagName === 'A') {
          var href = toggle.getAttribute('href');
          var states = JSON.parse(sessionStorage.getItem(TOGGLE_STATE_KEY) || '{}');
          states[href] = !expanded; // Store the NEW state (toggled)
          sessionStorage.setItem(TOGGLE_STATE_KEY, JSON.stringify(states));
          return; // Let browser navigate
        }

        // For buttons, toggle with animation
        var fullHeight = children.scrollHeight;

        if (expanded) {
          // Closing - fast ease-in
          children.style.transition = 'max-height 0.2s cubic-bezier(0.4, 0, 1, 1)';
          toggle.setAttribute('aria-expanded', 'false');
          children.classList.add('collapsed');
          children.style.maxHeight = '0';
        } else {
          // Opening - springy
          children.style.transition = 'max-height 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)';
          toggle.setAttribute('aria-expanded', 'true');
          children.classList.remove('collapsed');
          children.style.maxHeight = fullHeight + 'px';
        }
      });
    });

    document.querySelectorAll('.nav-group-children.collapsed').forEach(function(el) {
      el.style.maxHeight = '0';
    });
  }

  function expandActiveGroups() {
    var TOGGLE_STATE_KEY = 'docyard_toggle_states';
    var currentUrl = window.location.pathname;
    var lastUrl = sessionStorage.getItem('docyard_last_url') || '';
    var toggleStates = JSON.parse(sessionStorage.getItem(TOGGLE_STATE_KEY) || '{}');

    sessionStorage.setItem('docyard_last_url', currentUrl);

    // Apply saved toggle states for link-based toggles with animation
    document.querySelectorAll('[data-nav-toggle]').forEach(function(toggle) {
      if (toggle.tagName !== 'A') return;

      var href = toggle.getAttribute('href');
      var savedState = toggleStates[href];

      if (savedState === undefined) return; // No saved state

      var navGroup = toggle.closest('.nav-group');
      var children = navGroup ? navGroup.querySelector('.nav-group-children') : null;

      if (!children) return;

      var fullHeight = children.scrollHeight;

      if (savedState === false) {
        // Animate to collapsed - start expanded, then collapse
        children.style.transition = 'none';
        children.classList.remove('collapsed');
        children.style.maxHeight = fullHeight + 'px';
        children.offsetHeight; // Force reflow

        // Animate closed (fast)
        children.style.transition = 'max-height 0.2s cubic-bezier(0.4, 0, 1, 1)';
        requestAnimationFrame(function() {
          toggle.setAttribute('aria-expanded', 'false');
          children.classList.add('collapsed');
          children.style.maxHeight = '0';
        });
      } else {
        // Animate to expanded - start collapsed, then expand
        children.style.transition = 'none';
        children.classList.add('collapsed');
        children.style.maxHeight = '0';
        children.offsetHeight; // Force reflow

        // Animate open (springy)
        children.style.transition = 'max-height 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)';
        requestAnimationFrame(function() {
          toggle.setAttribute('aria-expanded', 'true');
          children.classList.remove('collapsed');
          children.style.maxHeight = fullHeight + 'px';
        });
      }

      // Clear the saved state after applying
      delete toggleStates[href];
      sessionStorage.setItem(TOGGLE_STATE_KEY, JSON.stringify(toggleStates));
    });

    // Handle remaining expanded groups (not controlled by saved state)
    var expandedGroups = document.querySelectorAll('.nav-group-children:not(.collapsed)');

    expandedGroups.forEach(function(group) {
      // Skip if already has max-height set (already processed)
      if (group.style.maxHeight) {
        return;
      }

      var navGroup = group.closest('.nav-group');
      var header = navGroup ? navGroup.querySelector('.nav-group-header') : null;
      var headerHref = header && header.tagName === 'A' ? header.getAttribute('href') : null;

      // Only animate if:
      // 1. Header itself is active (navigated to group's index page)
      // 2. Previous URL was not within this group (dropdown wasn't already open)
      var wasInGroup = headerHref && (lastUrl === headerHref || lastUrl.startsWith(headerHref + '/'));
      var shouldAnimate = header && header.classList.contains('active') && !wasInGroup;
      var fullHeight = group.scrollHeight;

      if (shouldAnimate) {
        // Animate open with spring
        group.style.transition = 'none';
        group.style.maxHeight = '0';
        group.classList.add('collapsed');
        group.offsetHeight;

        group.style.transition = 'max-height 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)';
        requestAnimationFrame(function() {
          group.classList.remove('collapsed');
          group.style.maxHeight = fullHeight + 'px';
        });
      } else {
        // Just set max-height without animation
        group.style.maxHeight = fullHeight + 'px';
      }
    });
  }

  function initSidebarScroll() {
    const scrollContainer = document.querySelector('.sidebar-scroll');
    if (!scrollContainer) return;

    const STORAGE_KEY = 'docyard_sidebar_scroll';
    const savedPosition = sessionStorage.getItem(STORAGE_KEY);

    if (savedPosition) {
      const position = parseInt(savedPosition, 10);
      scrollContainer.scrollTop = position;

      setTimeout(function() {
        scrollContainer.scrollTop = position;
      }, 100);
    } else {
      const activeLink = scrollContainer.querySelector('a.active');
      if (activeLink) {
        setTimeout(function() {
          activeLink.scrollIntoView({
            behavior: 'instant',
            block: 'center'
          });
        }, 50);
      }
    }

    scrollContainer.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function() {
        sessionStorage.setItem(STORAGE_KEY, scrollContainer.scrollTop);
      });
    });

    let scrollTimeout;
    scrollContainer.addEventListener('scroll', function() {
      clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(function() {
        sessionStorage.setItem(STORAGE_KEY, scrollContainer.scrollTop);
      }, 150);
    });

    const logo = document.querySelector('.header-logo');
    if (logo) {
      logo.addEventListener('click', function() {
        sessionStorage.removeItem(STORAGE_KEY);
        scrollContainer.scrollTop = 0;
      });
    }
  }

  function initScrollFadeIndicators() {
    const sidebar = document.querySelector('.sidebar');
    const scrollContainer = document.querySelector('.sidebar-scroll');
    if (!sidebar || !scrollContainer) return;

    function updateFadeIndicators() {
      const scrollTop = scrollContainer.scrollTop;
      const scrollHeight = scrollContainer.scrollHeight;
      const clientHeight = scrollContainer.clientHeight;
      const threshold = 10;

      if (scrollTop > threshold) {
        sidebar.classList.add('can-scroll-top');
      } else {
        sidebar.classList.remove('can-scroll-top');
      }

      if (scrollTop + clientHeight < scrollHeight - threshold) {
        sidebar.classList.add('can-scroll-bottom');
      } else {
        sidebar.classList.remove('can-scroll-bottom');
      }
    }

    updateFadeIndicators();

    scrollContainer.addEventListener('scroll', updateFadeIndicators);

    window.addEventListener('resize', updateFadeIndicators);
  }

  function initScrollBehavior() {
    const header = document.querySelector('.header');
    const secondaryHeader = document.querySelector('.secondary-header');

    if (!header || !secondaryHeader) return;

    let lastScrollTop = 0;
    let ticking = false;

    function isMobile() {
      return window.innerWidth <= 1024;
    }

    function updateHeaders() {
      if (!isMobile()) {
        header.classList.remove('hide-on-scroll');
        secondaryHeader.classList.remove('shift-up');
        ticking = false;
        return;
      }

      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

      if (scrollTop > lastScrollTop && scrollTop > 100) {
        header.classList.add('hide-on-scroll');
        secondaryHeader.classList.add('shift-up');
      } else if (scrollTop < lastScrollTop) {
        header.classList.remove('hide-on-scroll');
        secondaryHeader.classList.remove('shift-up');
      }

      lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
      ticking = false;
    }

    window.addEventListener('scroll', function() {
      if (!ticking) {
        window.requestAnimationFrame(updateHeaders);
        ticking = true;
      }
    });

    window.addEventListener('resize', function() {
      if (!isMobile()) {
        header.classList.remove('hide-on-scroll');
        secondaryHeader.classList.remove('shift-up');
      }
    });
  }

  if ('scrollRestoration' in history) {
    history.scrollRestoration = 'manual';
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initMobileMenu();
      initAccordion();
      expandActiveGroups();
      initSidebarScroll();
      initScrollFadeIndicators();
      initScrollBehavior();
    });
  } else {
    initMobileMenu();
    initAccordion();
    expandActiveGroups();
    initSidebarScroll();
    initScrollFadeIndicators();
    initScrollBehavior();
  }
})();
