class TableOfContentsManager {
  constructor() {
    this.toc = document.querySelector('.docyard-toc');
    if (!this.toc) return;

    this.links = Array.from(this.toc.querySelectorAll('.docyard-toc__link'));
    this.headings = this.getHeadings();
    this.nav = this.toc.querySelector('.docyard-toc__nav');
    this.activeLink = null;
    this.observer = null;
    this.ticking = false;

    this.init();
  }

  init() {
    if (this.headings.length === 0) return;

    this.aside = document.querySelector('.doc-aside');
    this.createIndicator();
    this.setupScrollSpy();
    this.setupSmoothScrolling();
    this.setupMobileToggle();
    this.setupKeyboardNavigation();
    this.setupScrollFadeIndicators();
    this.setupAsideOverflowDetection();
    this.handleInitialHash();

    requestAnimationFrame(() => {
      this.updateIndicator();
    });
  }

  
  createIndicator() {
    const list = this.toc.querySelector('.docyard-toc__list');
    if (!list) return;

    this.indicator = document.createElement('div');
    this.indicator.className = 'docyard-toc__indicator';
    this.indicator.style.opacity = '0';
    list.appendChild(this.indicator);
  }

  
  updateIndicator() {
    if (!this.indicator || !this.activeLink) return;

    const list = this.toc.querySelector('.docyard-toc__list');
    if (!list) return;

    const listRect = list.getBoundingClientRect();
    const linkRect = this.activeLink.getBoundingClientRect();

    const top = linkRect.top - listRect.top;
    const height = linkRect.height;

    this.indicator.style.top = `${top}px`;
    this.indicator.style.height = `${height}px`;
    this.indicator.style.opacity = '1';
  }

  
  isMobile() {
    return window.innerWidth <= 1280;
  }

  
  isTablet() {
    return window.innerWidth > 1024 && window.innerWidth <= 1280;
  }

  
  getScrollOffset() {
    const hasTabs = document.body.classList.contains('has-tabs');
    const headerHeight = 64;
    const tabBarHeight = hasTabs ? 48 : 0;
    const buffer = 24;

    if (this.isTablet()) {
      return headerHeight + 48 + buffer;
    }

    if (window.innerWidth <= 1024) {
      const secondaryHeaderHeight = 48;
      return headerHeight + secondaryHeaderHeight + buffer;
    }

    return headerHeight + tabBarHeight + buffer;
  }

  
  getHeadings() {
    return this.links
      .map(link => {
        const id = link.dataset.headingId;
        return document.getElementById(id);
      })
      .filter(Boolean);
  }

  
  setupScrollSpy() {
    const options = {
      root: null,
      rootMargin: '-80px 0px -80% 0px',
      threshold: 0
    };

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.setActiveLink(entry.target.id);
        }
      });
    }, options);

    this.headings.forEach(heading => {
      this.observer.observe(heading);
    });
  }

  
  setActiveLink(id) {
    const link = this.links.find(l => l.dataset.headingId === id);
    if (!link || link === this.activeLink) return;

    if (this.activeLink) {
      this.activeLink.classList.remove('is-active');
    }

    link.classList.add('is-active');
    this.activeLink = link;

    this.updateIndicator();
    this.scrollLinkIntoView(link);
  }

  
  scrollLinkIntoView(link) {
    if (this.isMobile()) return;

    const scrollContainer = this.toc.querySelector('.docyard-toc__scroll');
    if (!scrollContainer) return;

    if (!this.ticking) {
      requestAnimationFrame(() => {
        const containerRect = scrollContainer.getBoundingClientRect();
        const linkRect = link.getBoundingClientRect();

        if (linkRect.top < containerRect.top || linkRect.bottom > containerRect.bottom) {
          link.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }

        this.ticking = false;
      });
      this.ticking = true;
    }
  }

  
  setupSmoothScrolling() {
    this.links.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();

        const id = link.dataset.headingId;
        const heading = document.getElementById(id);

        if (heading) {
          const offsetTop = heading.getBoundingClientRect().top + window.pageYOffset - this.getScrollOffset();

          window.scrollTo({
            top: offsetTop,
            behavior: 'smooth'
          });

          history.pushState(null, null, `#${id}`);

          heading.focus({ preventScroll: true });

          if (this.isMobile()) {
            this.collapseMobile();
          }
        }
      });
    });
  }

  
  setupMobileToggle() {
    const secondaryToggle = document.querySelector('.secondary-header-toc-toggle');

    if (!secondaryToggle || !this.nav) {
      return;
    }

    secondaryToggle.addEventListener('click', () => {
      const isExpanded = secondaryToggle.getAttribute('aria-expanded') === 'true';
      secondaryToggle.setAttribute('aria-expanded', !isExpanded);
      this.nav.classList.toggle('is-expanded', !isExpanded);

      if (!isExpanded) {
        document.body.style.overflow = 'hidden';
        requestAnimationFrame(() => this.updateIndicator());
      } else {
        document.body.style.overflow = '';
      }
    });

    document.addEventListener('click', (e) => {
      if (!this.isMobile()) return;

      const isExpanded = secondaryToggle.getAttribute('aria-expanded') === 'true';
      if (!isExpanded) return;

      const isClickInsideToc = this.nav.contains(e.target);
      const isClickOnToggle = secondaryToggle.contains(e.target);

      if (!isClickInsideToc && !isClickOnToggle) {
        this.collapseMobile();
      }
    });

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        const isExpanded = secondaryToggle.getAttribute('aria-expanded') === 'true';
        if (isExpanded) {
          this.collapseMobile();
          secondaryToggle.focus();
        }
      }
    });
  }

  
  collapseMobile() {
    const secondaryToggle = document.querySelector('.secondary-header-toc-toggle');
    if (secondaryToggle) {
      secondaryToggle.setAttribute('aria-expanded', 'false');
      if (this.nav) {
        this.nav.classList.remove('is-expanded');
      }
      document.body.style.overflow = '';
    }
  }

  
  setupKeyboardNavigation() {
    this.links.forEach((link, index) => {
      link.addEventListener('keydown', (e) => {
        let targetIndex = -1;

        switch (e.key) {
          case 'ArrowDown':
            e.preventDefault();
            targetIndex = index + 1;
            break;
          case 'ArrowUp':
            e.preventDefault();
            targetIndex = index - 1;
            break;
          case 'Home':
            e.preventDefault();
            targetIndex = 0;
            break;
          case 'End':
            e.preventDefault();
            targetIndex = this.links.length - 1;
            break;
          default:
            return;
        }

        if (targetIndex >= 0 && targetIndex < this.links.length) {
          this.links[targetIndex].focus();
        }
      });
    });
  }

  
  setupAsideOverflowDetection() {
    if (!this.aside) return;

    const checkOverflow = () => {
      if (this.isMobile()) {
        this.aside.classList.remove('has-overflow');
        return;
      }

      this.aside.classList.remove('has-overflow');

      const footer = this.aside.querySelector('.doc-footer-desktop');
      const tocScroll = this.toc.querySelector('.docyard-toc__scroll');
      if (!footer || !tocScroll) return;

      requestAnimationFrame(() => {
        const asideHeight = this.aside.clientHeight;
        const tocNaturalHeight = this.toc.offsetHeight;
        const footerHeight = footer.offsetHeight;
        const totalContentHeight = tocNaturalHeight + footerHeight;

        if (totalContentHeight > asideHeight) {
          this.aside.classList.add('has-overflow');
        }
      });
    };

    checkOverflow();
    window.addEventListener('resize', checkOverflow);
  }

  setupScrollFadeIndicators() {
    const scrollContainer = this.toc.querySelector('.docyard-toc__scroll');
    if (!scrollContainer) return;

    const updateFadeIndicators = () => {
      if (this.isMobile()) {
        this.toc.classList.remove('can-scroll-top', 'can-scroll-bottom');
        return;
      }

      const scrollTop = scrollContainer.scrollTop;
      const scrollHeight = scrollContainer.scrollHeight;
      const clientHeight = scrollContainer.clientHeight;
      const threshold = 10;

      if (scrollTop > threshold) {
        this.toc.classList.add('can-scroll-top');
      } else {
        this.toc.classList.remove('can-scroll-top');
      }

      if (scrollTop + clientHeight < scrollHeight - threshold) {
        this.toc.classList.add('can-scroll-bottom');
      } else {
        this.toc.classList.remove('can-scroll-bottom');
      }
    };

    updateFadeIndicators();
    scrollContainer.addEventListener('scroll', () => {
      updateFadeIndicators();
      this.updateIndicator();
    });
    window.addEventListener('resize', () => {
      updateFadeIndicators();
      this.updateIndicator();
    });
  }

  
  handleInitialHash() {
    const hash = window.location.hash.slice(1);
    if (!hash) return;

    const heading = document.getElementById(hash);
    if (!heading) return;

    this.setActiveLink(hash);

    const offsetTop = heading.getBoundingClientRect().top + window.pageYOffset - this.getScrollOffset();
    window.scrollTo({
      top: offsetTop,
      behavior: 'instant'
    });
  }

  
  destroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }
}

if (typeof window !== 'undefined') {
  document.addEventListener('DOMContentLoaded', () => {
    window.tocManager = new TableOfContentsManager();
  });

  window.addEventListener('beforeunload', () => {
    if (window.tocManager) {
      window.tocManager.destroy();
    }
  });
}
