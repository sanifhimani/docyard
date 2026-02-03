class CodeGroupManager {
  constructor() {
    this.groups = [];
    this.init();
  }

  init() {
    const containers = document.querySelectorAll('.docyard-code-group');
    if (containers.length === 0) return;

    containers.forEach(container => {
      if (container.hasAttribute('data-code-group-initialized')) return;
      container.setAttribute('data-code-group-initialized', 'true');
      this.groups.push(new CodeGroup(container, this));
    });

    this.loadPreference();
  }

  syncTabs(label) {
    this.groups.forEach(group => {
      group.activateTabByLabel(label, true);
    });
    this.savePreference(label);
  }

  loadPreference() {
    try {
      const preferredTab = localStorage.getItem('docyard-code-group-tab');
      if (!preferredTab) return;

      this.groups.forEach(group => {
        group.activateTabByLabel(preferredTab, false);
      });
    } catch (error) {
      // localStorage not available
    }
  }

  savePreference(label) {
    try {
      localStorage.setItem('docyard-code-group-tab', label.toLowerCase());
    } catch (error) {
      // localStorage not available
    }
  }
}

class CodeGroup {
  constructor(container, manager) {
    this.container = container;
    this.manager = manager;
    this.scrollContainer = container.querySelector('.docyard-code-group__tabs-scroll-container');
    this.tabList = container.querySelector('[role="tablist"]');
    this.tabs = Array.from(container.querySelectorAll('[role="tab"]'));
    this.panels = Array.from(container.querySelectorAll('[role="tabpanel"]'));
    this.indicator = container.querySelector('.docyard-code-group__indicator');
    this.copyButton = container.querySelector('.docyard-code-group__copy');
    this.activeIndex = 0;

    this.checkIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 256 256"><path d="M229.66,77.66l-128,128a8,8,0,0,1-11.32,0l-56-56a8,8,0,0,1,11.32-11.32L96,188.69,218.34,66.34a8,8,0,0,1,11.32,11.32Z"/></svg>';

    this.attachEventListeners();
    this.updateIndicator(false);

    requestAnimationFrame(() => {
      if (this.indicator) {
        this.indicator.classList.add('is-ready');
      }
      this.updateScrollIndicators();
    });
  }

  attachEventListeners() {
    this.tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => this.handleTabClick(index));
    });

    this.tabList.addEventListener('keydown', (e) => this.handleKeyDown(e));
    this.tabList.addEventListener('scroll', () => this.handleScroll());
    window.addEventListener('resize', () => this.handleResize());

    if (this.copyButton) {
      this.copyButton.addEventListener('click', () => this.handleCopy());
    }
  }

  handleScroll() {
    if (this.scrollTimeout) {
      cancelAnimationFrame(this.scrollTimeout);
    }

    this.scrollTimeout = requestAnimationFrame(() => {
      this.updateScrollIndicators();
    });
  }

  handleTabClick(index) {
    if (index === this.activeIndex) return;

    const label = this.tabs[index].dataset.label;
    this.manager.syncTabs(label);
  }

  handleKeyDown(event) {
    const { key } = event;

    if (key === 'ArrowLeft' || key === 'ArrowRight') {
      event.preventDefault();

      if (key === 'ArrowLeft') {
        this.activatePreviousTab();
      } else {
        this.activateNextTab();
      }

      this.tabs[this.activeIndex].focus();
      const label = this.tabs[this.activeIndex].dataset.label;
      this.manager.syncTabs(label);
    }

    if (key === 'Home') {
      event.preventDefault();
      this.activateTab(0, true);
      this.tabs[0].focus();
      const label = this.tabs[0].dataset.label;
      this.manager.syncTabs(label);
    }

    if (key === 'End') {
      event.preventDefault();
      const lastIndex = this.tabs.length - 1;
      this.activateTab(lastIndex, true);
      this.tabs[lastIndex].focus();
      const label = this.tabs[lastIndex].dataset.label;
      this.manager.syncTabs(label);
    }
  }

  handleResize() {
    if (this.resizeTimeout) {
      cancelAnimationFrame(this.resizeTimeout);
    }

    this.resizeTimeout = requestAnimationFrame(() => {
      this.updateIndicator(false);
      this.updateScrollIndicators();
    });
  }

  activateTab(index, animate = true) {
    if (index < 0 || index >= this.tabs.length) return;

    this.activeIndex = index;

    this.tabs.forEach((tab, i) => {
      const isActive = i === index;
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
      tab.setAttribute('tabindex', isActive ? '0' : '-1');
    });

    this.panels.forEach((panel, i) => {
      const isActive = i === index;
      panel.setAttribute('aria-hidden', isActive ? 'false' : 'true');
    });

    this.updateIndicator(animate);
  }

  activateTabByLabel(label, animate = true) {
    const index = this.tabs.findIndex(tab =>
      tab.dataset.label.toLowerCase() === label.toLowerCase()
    );

    if (index !== -1 && index !== this.activeIndex) {
      this.activateTab(index, animate);
    }
  }

  activateNextTab() {
    const nextIndex = (this.activeIndex + 1) % this.tabs.length;
    this.activateTab(nextIndex, true);
  }

  activatePreviousTab() {
    const prevIndex = (this.activeIndex - 1 + this.tabs.length) % this.tabs.length;
    this.activateTab(prevIndex, true);
  }

  updateIndicator(animate = true) {
    if (!this.indicator || !this.tabs[this.activeIndex]) return;

    const activeTab = this.tabs[this.activeIndex];
    const tabListRect = this.tabList.getBoundingClientRect();
    const activeTabRect = activeTab.getBoundingClientRect();

    const left = activeTabRect.left - tabListRect.left + this.tabList.scrollLeft;
    const width = activeTabRect.width;

    this.indicator.style.width = `${width}px`;
    this.indicator.style.transform = `translateX(${left}px)`;

    if (!animate) {
      this.indicator.style.transition = 'none';
      void this.indicator.offsetWidth;
      this.indicator.style.transition = '';
    }
  }

  updateScrollIndicators() {
    if (!this.tabList || !this.scrollContainer) return;

    const { scrollLeft, scrollWidth, clientWidth } = this.tabList;
    const hasOverflow = scrollWidth > clientWidth;

    if (!hasOverflow) {
      this.scrollContainer.classList.remove('can-scroll-left', 'can-scroll-right');
      return;
    }

    const canScrollLeft = scrollLeft > 5;
    this.scrollContainer.classList.toggle('can-scroll-left', canScrollLeft);

    const canScrollRight = scrollLeft < scrollWidth - clientWidth - 5;
    this.scrollContainer.classList.toggle('can-scroll-right', canScrollRight);
  }

  async handleCopy() {
    const activePanel = this.panels[this.activeIndex];
    if (!activePanel) return;

    const codeText = activePanel.dataset.code || '';

    try {
      await this.copyToClipboard(codeText);
      this.showCopySuccess();
    } catch (error) {
      console.warn('Failed to copy code:', error);
    }
  }

  async copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
    } else {
      const textArea = document.createElement('textarea');
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
    }
  }

  showCopySuccess() {
    if (!this.copyButton) return;

    const iconEl = this.copyButton.querySelector('.docyard-code-group__copy-icon');
    const textEl = this.copyButton.querySelector('.docyard-code-group__copy-text');

    if (!iconEl || !textEl) return;

    const originalIcon = iconEl.innerHTML;
    const originalText = textEl.textContent;

    iconEl.innerHTML = this.checkIcon;
    textEl.textContent = 'Copied';
    this.copyButton.classList.add('is-success');

    setTimeout(() => {
      iconEl.innerHTML = originalIcon;
      textEl.textContent = originalText;
      this.copyButton.classList.remove('is-success');
    }, 2000);
  }
}

function initializeCodeGroups(root = document) {
  const containers = root.querySelectorAll('.docyard-code-group');
  if (containers.length === 0) return;

  if (!window.docyardCodeGroupManager) {
    window.docyardCodeGroupManager = new CodeGroupManager();
  } else {
    containers.forEach(container => {
      if (container.hasAttribute('data-code-group-initialized')) return;
      container.setAttribute('data-code-group-initialized', 'true');
      window.docyardCodeGroupManager.groups.push(new CodeGroup(container, window.docyardCodeGroupManager));
    });
    window.docyardCodeGroupManager.loadPreference();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() { initializeCodeGroups(); });
} else {
  initializeCodeGroups();
}

window.docyard = window.docyard || {};
window.docyard.initCodeGroups = initializeCodeGroups;
