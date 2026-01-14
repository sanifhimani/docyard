(function() {
  'use strict';

  function initMobileMenu() {
    const toggle = document.querySelector('.secondary-header-menu');
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.querySelector('.mobile-overlay');

    if (!toggle || !sidebar || !overlay) {
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

    function openMenu() {
      lockBodyScroll();
      sidebar.classList.add('is-open');
      overlay.classList.add('is-visible');
      toggle.setAttribute('aria-expanded', 'true');
    }

    function closeMenu() {
      sidebar.classList.remove('is-open');
      overlay.classList.remove('is-visible');
      toggle.setAttribute('aria-expanded', 'false');
      unlockBodyScroll();
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

    function getDefaultCollapsed(navGroup) {
      return navGroup.getAttribute('data-default-collapsed') === 'true';
    }

    function collapseGroup(navGroup, animate) {
      var header = navGroup.querySelector('[data-nav-toggle]');
      var children = navGroup.querySelector('.nav-group-children');
      if (!header || !children) return;

      if (animate) {
        children.style.transition = 'max-height 0.2s cubic-bezier(0.4, 0, 1, 1)';
      } else {
        children.style.transition = 'none';
      }
      header.setAttribute('aria-expanded', 'false');
      children.classList.add('collapsed');
      children.style.maxHeight = '0';
    }

    function expandGroup(navGroup, animate) {
      var header = navGroup.querySelector('[data-nav-toggle]');
      var children = navGroup.querySelector('.nav-group-children');
      if (!header || !children) return;

      var fullHeight = children.scrollHeight;
      if (animate) {
        children.style.transition = 'max-height 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)';
      } else {
        children.style.transition = 'none';
      }
      header.setAttribute('aria-expanded', 'true');
      children.classList.remove('collapsed');
      children.style.maxHeight = fullHeight + 'px';
    }

    function revertOthersToDefault(currentNavGroup) {
      document.querySelectorAll('.nav-group').forEach(function(navGroup) {
        if (navGroup === currentNavGroup) return;

        var defaultCollapsed = getDefaultCollapsed(navGroup);
        var children = navGroup.querySelector('.nav-group-children');
        if (!children) return;

        var isCurrentlyCollapsed = children.classList.contains('collapsed');

        if (defaultCollapsed && !isCurrentlyCollapsed) {
          collapseGroup(navGroup, true);
        } else if (!defaultCollapsed && isCurrentlyCollapsed) {
          expandGroup(navGroup, true);
        }
      });
    }

    toggles.forEach(function(toggle) {
      toggle.addEventListener('click', function(e) {
        var expanded = toggle.getAttribute('aria-expanded') === 'true';
        var navGroup = toggle.closest('.nav-group');
        var children = navGroup ? navGroup.querySelector('.nav-group-children') : null;

        if (!children) {
          return;
        }

        revertOthersToDefault(navGroup);

        if (toggle.tagName === 'A') {
          var href = toggle.getAttribute('href');
          var states = {};
          states[href] = true;
          sessionStorage.setItem(TOGGLE_STATE_KEY, JSON.stringify(states));
          return;
        }

        if (expanded) {
          collapseGroup(navGroup, true);
        } else {
          expandGroup(navGroup, true);
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
    sessionStorage.removeItem(TOGGLE_STATE_KEY);

    document.querySelectorAll('[data-nav-toggle]').forEach(function(toggle) {
      if (toggle.tagName !== 'A') return;

      var href = toggle.getAttribute('href');
      var shouldOpen = toggleStates[href] === true;

      if (!shouldOpen) return;

      var navGroup = toggle.closest('.nav-group');
      var children = navGroup ? navGroup.querySelector('.nav-group-children') : null;

      if (!children || !children.classList.contains('collapsed')) return;

      var fullHeight = children.scrollHeight;

      children.style.transition = 'none';
      children.style.maxHeight = '0';
      children.offsetHeight;

      children.style.transition = 'max-height 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)';
      requestAnimationFrame(function() {
        toggle.setAttribute('aria-expanded', 'true');
        children.classList.remove('collapsed');
        children.style.maxHeight = fullHeight + 'px';
      });
    });

    var expandedGroups = document.querySelectorAll('.nav-group-children:not(.collapsed)');

    expandedGroups.forEach(function(group) {
      if (group.style.maxHeight) {
        return;
      }

      var navGroup = group.closest('.nav-group');
      var header = navGroup ? navGroup.querySelector('.nav-group-header') : null;
      var headerHref = header && header.tagName === 'A' ? header.getAttribute('href') : null;

      if (headerHref && toggleStates[headerHref] === true) {
        group.style.maxHeight = group.scrollHeight + 'px';
        return;
      }

      var wasInGroup = headerHref && (lastUrl === headerHref || lastUrl.startsWith(headerHref + '/'));
      var shouldAnimate = header && header.classList.contains('active') && !wasInGroup;
      var fullHeight = group.scrollHeight;

      if (shouldAnimate) {
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
