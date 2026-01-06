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
    const toggles = document.querySelectorAll('.nav-group-toggle');

    toggles.forEach(function(toggle) {
      toggle.addEventListener('click', function() {
        const expanded = toggle.getAttribute('aria-expanded') === 'true';
        const children = toggle.nextElementSibling;

        if (!children || !children.classList.contains('nav-group-children')) {
          return;
        }

        toggle.setAttribute('aria-expanded', !expanded);
        children.classList.toggle('collapsed');

        if (expanded) {
          children.style.maxHeight = '0';
        } else {
          children.style.maxHeight = children.scrollHeight + 'px';
        }
      });
    });

    document.querySelectorAll('.nav-group-children.collapsed').forEach(function(el) {
      el.style.maxHeight = '0';
    });
  }

  function expandActiveGroups() {
    const activeLinks = document.querySelectorAll('a.active');

    activeLinks.forEach(function(activeLink) {
      let parent = activeLink.closest('.nav-group-children');

      while (parent) {
        if (parent.classList.contains('nav-group-children')) {
          parent.classList.remove('collapsed');

          const toggle = parent.previousElementSibling;
          if (toggle && toggle.classList.contains('nav-group-toggle')) {
            toggle.setAttribute('aria-expanded', 'true');

            parent.style.maxHeight = 'none';
            const height = parent.scrollHeight;
            parent.style.maxHeight = height + 'px';
          }
        }

        parent = parent.parentElement?.closest('.nav-group-children');
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
