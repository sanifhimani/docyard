/**
 * TabsManager - Manages tab component interactions
 *
 * @class TabsManager
 */
class TabsManager {
  /**
   * Create a TabsManager instance
   * @param {HTMLElement} container - The .docyard-tabs container element
   */
  constructor(container) {
    if (!container) return;

    this.container = container;
    this.tabListWrapper = container.querySelector('.docyard-tabs__list-wrapper');
    this.tabList = container.querySelector('[role="tablist"]');
    this.tabs = Array.from(container.querySelectorAll('[role="tab"]'));
    this.panels = Array.from(container.querySelectorAll('[role="tabpanel"]'));
    this.indicator = container.querySelector('.docyard-tabs__indicator');
    this.activeIndex = 0;
    this.groupId = container.getAttribute('data-tabs');

    this.handleTabClick = this.handleTabClick.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleResize = this.handleResize.bind(this);
    this.handleScroll = this.handleScroll.bind(this);

    this.init();
  }

  /**
   * Initialize the tabs component
   */
  init() {
    if (!this.tabList || this.tabs.length === 0 || this.panels.length === 0) {
      return;
    }

    this.createScrollIndicators();
    this.loadPreference();
    this.attachEventListeners();
    this.activateTab(this.activeIndex, false);
    this.updateIndicator();
    this.updateScrollIndicators();
  }

  /**
   * Create scroll indicator elements
   */
  createScrollIndicators() {
    if (!this.tabListWrapper || !this.tabList) return;

    this.leftIndicator = document.createElement('div');
    this.leftIndicator.className = 'docyard-tabs__scroll-indicator docyard-tabs__scroll-indicator--left';
    this.tabListWrapper.insertBefore(this.leftIndicator, this.tabList);

    this.rightIndicator = document.createElement('div');
    this.rightIndicator.className = 'docyard-tabs__scroll-indicator docyard-tabs__scroll-indicator--right';
    this.tabListWrapper.appendChild(this.rightIndicator);
  }

  /**
   * Attach all event listeners
   */
  attachEventListeners() {
    this.tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => this.handleTabClick(index));
    });

    this.tabList.addEventListener('keydown', this.handleKeyDown);

    this.tabList.addEventListener('scroll', this.handleScroll);

    window.addEventListener('resize', this.handleResize);
  }

  /**
   * Handle tab click
   * @param {number} index - Index of clicked tab
   */
  handleTabClick(index) {
    if (index === this.activeIndex) return;

    this.activateTab(index, true);
    this.savePreference(index);
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
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
    }

    if (key === 'Home') {
      event.preventDefault();
      this.activateTab(0, true);
      this.tabs[0].focus();
    }

    if (key === 'End') {
      event.preventDefault();
      const lastIndex = this.tabs.length - 1;
      this.activateTab(lastIndex, true);
      this.tabs[lastIndex].focus();
    }
  }

  /**
   * Handle scroll event - update scroll indicators
   */
  handleScroll() {
    if (this.scrollTimeout) {
      cancelAnimationFrame(this.scrollTimeout);
    }

    this.scrollTimeout = requestAnimationFrame(() => {
      this.updateScrollIndicators();
    });
  }

  /**
   * Handle window resize - update indicator and scroll indicators
   */
  handleResize() {
    if (this.resizeTimeout) {
      cancelAnimationFrame(this.resizeTimeout);
    }

    this.resizeTimeout = requestAnimationFrame(() => {
      this.updateIndicator(false);
      this.updateScrollIndicators();
    });
  }

  /**
   * Activate a specific tab
   * @param {number} index - Index of tab to activate
   * @param {boolean} animate - Whether to animate the transition
   */
  activateTab(index, animate = true) {
    if (index < 0 || index >= this.tabs.length) return;

    const previousIndex = this.activeIndex;
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

    if (previousIndex !== index) {
      this.savePreference(index);
    }
  }

  /**
   * Activate the next tab (wraps around)
   */
  activateNextTab() {
    const nextIndex = (this.activeIndex + 1) % this.tabs.length;
    this.activateTab(nextIndex, true);
  }

  /**
   * Activate the previous tab (wraps around)
   */
  activatePreviousTab() {
    const prevIndex = (this.activeIndex - 1 + this.tabs.length) % this.tabs.length;
    this.activateTab(prevIndex, true);
  }

  /**
   * Update the visual indicator position
   * @param {boolean} animate - Whether to animate the transition
   */
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

  /**
   * Update scroll indicators visibility based on scroll position
   */
  updateScrollIndicators() {
    if (!this.tabList || !this.leftIndicator || !this.rightIndicator) return;

    const { scrollLeft, scrollWidth, clientWidth } = this.tabList;
    const hasOverflow = scrollWidth > clientWidth;

    if (!hasOverflow) {
      this.leftIndicator.classList.remove('is-visible');
      this.rightIndicator.classList.remove('is-visible');
      return;
    }

    const canScrollLeft = scrollLeft > 5;
    if (canScrollLeft) {
      this.leftIndicator.classList.add('is-visible');
    } else {
      this.leftIndicator.classList.remove('is-visible');
    }

    const canScrollRight = scrollLeft < scrollWidth - clientWidth - 5;
    if (canScrollRight) {
      this.rightIndicator.classList.add('is-visible');
    } else {
      this.rightIndicator.classList.remove('is-visible');
    }
  }

  /**
   * Load user preference from localStorage
   */
  loadPreference() {
    try {
      const preferredTab = localStorage.getItem('docyard-preferred-pm');
      if (!preferredTab) return;

      const index = this.tabs.findIndex(tab =>
        tab.textContent.trim().toLowerCase() === preferredTab.toLowerCase()
      );

      if (index !== -1) {
        this.activeIndex = index;
      }
    } catch (error) {
      console.warn('Could not load tab preference:', error);
    }
  }

  /**
   * Save user preference to localStorage
   * @param {number} index - Index of active tab
   */
  savePreference(index) {
    if (index < 0 || index >= this.tabs.length) return;

    try {
      const tabName = this.tabs[index].textContent.trim().toLowerCase();
      localStorage.setItem('docyard-preferred-pm', tabName);
    } catch (error) {
      console.warn('Could not save tab preference:', error);
    }
  }

  /**
   * Activate tab by name
   * @param {string} name - Name of tab to activate
   */
  activateTabByName(name) {
    const index = this.tabs.findIndex(tab =>
      tab.textContent.trim().toLowerCase() === name.toLowerCase()
    );

    if (index !== -1) {
      this.activateTab(index, true);
    }
  }

  /**
   * Cleanup - remove event listeners
   */
  destroy() {
    this.tabs.forEach((tab, index) => {
      tab.removeEventListener('click', () => this.handleTabClick(index));
    });

    this.tabList.removeEventListener('keydown', this.handleKeyDown);
    this.tabList.removeEventListener('scroll', this.handleScroll);
    window.removeEventListener('resize', this.handleResize);

    if (this.resizeTimeout) {
      cancelAnimationFrame(this.resizeTimeout);
    }

    if (this.scrollTimeout) {
      cancelAnimationFrame(this.scrollTimeout);
    }
  }
}

/**
 * Auto-initialize all tabs on page load
 */
function initializeTabs() {
  const tabsContainers = document.querySelectorAll('.docyard-tabs');

  tabsContainers.forEach(container => {
    new TabsManager(container);
  });
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTabs);
} else {
  initializeTabs();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { TabsManager };
}
