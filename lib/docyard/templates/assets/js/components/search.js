class SearchManager {
  constructor() {
    this.modal = document.querySelector('[data-search-modal]');
    this.trigger = document.querySelector('[data-search-trigger]');
    this.backdrop = document.querySelector('[data-search-backdrop]');
    this.input = document.querySelector('[data-search-input]');
    this.clearButton = document.querySelector('[data-search-clear]');
    this.closeButton = document.querySelector('[data-search-close]');
    this.body = document.querySelector('[data-search-body]');
    this.resultsContainer = document.querySelector('[data-search-results]');
    this.loadingState = document.querySelector('[data-search-loading]');
    this.emptyState = document.querySelector('[data-search-empty]');

    if (!this.modal) return;

    this.pagefind = null;
    this.isOpen = false;
    this.selectedIndex = -1;
    this.results = [];
    this.searchTimeout = null;
    this.DEBOUNCE_DELAY = 150;
    this.RESULTS_PER_PAGE = 6;

    this.allSearchResults = [];
    this.displayedCount = 0;
    this.currentQuery = '';
    this.groupedResults = [];

    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleInput = this.handleInput.bind(this);
    this.handleResultClick = this.handleResultClick.bind(this);
    this.handleLoadMore = this.handleLoadMore.bind(this);

    this.init();
  }

  init() {
    this.attachEventListeners();
    this.updateShortcutHint();
  }

  attachEventListeners() {
    document.addEventListener('keydown', this.handleKeyDown);

    if (this.trigger) {
      this.trigger.addEventListener('click', () => this.open());
    }

    if (this.backdrop) {
      this.backdrop.addEventListener('click', () => this.close());
    }

    if (this.closeButton) {
      this.closeButton.addEventListener('click', () => this.close());
    }

    if (this.clearButton) {
      this.clearButton.addEventListener('click', () => this.clearSearch());
    }

    if (this.input) {
      this.input.addEventListener('input', this.handleInput);
      this.input.addEventListener('keydown', (e) => this.handleInputKeyDown(e));
    }

    if (this.resultsContainer) {
      this.resultsContainer.addEventListener('click', this.handleResultClick);
    }
  }

  updateShortcutHint() {
    const shortcut = document.querySelector('[data-search-shortcut]');
    if (shortcut) {
      const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0 ||
                    navigator.userAgent.toUpperCase().indexOf('MAC') >= 0;
      if (!isMac) {
        shortcut.setAttribute('data-os', 'windows');
      }
    }
  }

  handleKeyDown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault();
      this.toggle();
      return;
    }

    if (event.key === 'Escape' && this.isOpen) {
      event.preventDefault();
      this.close();
      return;
    }

    if (event.key === '/' && !this.isOpen && !this.isInputFocused()) {
      event.preventDefault();
      this.open();
    }
  }

  handleInputKeyDown(event) {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.selectNext();
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.selectPrevious();
        break;
      case 'Enter':
        event.preventDefault();
        this.navigateToSelected();
        break;
    }
  }

  handleInput(event) {
    const query = event.target.value.trim();

    if (this.clearButton) {
      this.clearButton.hidden = query.length === 0;
    }

    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    if (query.length === 0) {
      this.hideBody();
      return;
    }

    this.searchTimeout = setTimeout(() => {
      this.search(query);
    }, this.DEBOUNCE_DELAY);
  }

  handleResultClick(event) {
    const resultElement = event.target.closest('.search-result');
    if (resultElement) {
      const url = resultElement.getAttribute('href');
      if (url) {
        this.close();
        window.location.href = url;
      }
    }
  }

  isInputFocused() {
    const activeElement = document.activeElement;
    return activeElement && (
      activeElement.tagName === 'INPUT' ||
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.isContentEditable
    );
  }

  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  async open() {
    if (this.isOpen) return;

    this.isOpen = true;
    this.modal.hidden = false;
    document.body.style.overflow = 'hidden';

    requestAnimationFrame(() => {
      this.modal.classList.add('is-open');
      requestAnimationFrame(() => {
        if (this.input) {
          this.input.focus();
        }
      });
    });

    if (!this.pagefind) {
      await this.initPagefind();
    }
  }

  close() {
    if (!this.isOpen) return;

    this.isOpen = false;
    this.modal.classList.remove('is-open');
    document.body.style.overflow = '';
    this.selectedIndex = -1;

    setTimeout(() => {
      if (!this.isOpen) {
        this.modal.hidden = true;
        if (this.body) {
          this.body.hidden = true;
        }
      }
    }, 200);

    if (this.trigger) {
      this.trigger.focus();
    }
  }

  clearSearch() {
    if (this.input) {
      this.input.value = '';
      this.input.focus();
    }
    if (this.clearButton) {
      this.clearButton.hidden = true;
    }
    this.hideBody();
  }

  async initPagefind() {
    try {
      this.pagefind = await import('/_docyard/pagefind/pagefind.js');
      await this.pagefind.init();
    } catch (error) {
      console.warn('Pagefind not available:', error);
      this.showErrorState('Search is not available. Run "docyard build" to generate the search index.');
    }
  }

  async search(query) {
    if (!this.pagefind) {
      await this.initPagefind();
      if (!this.pagefind) return;
    }

    this.showLoadingState();

    try {
      const searchResults = await this.pagefind.search(query);

      if (searchResults.results.length === 0) {
        this.showEmptyState(query);
        return;
      }

      this.allSearchResults = searchResults.results;
      this.currentQuery = query;
      this.displayedCount = 0;
      this.groupedResults = [];

      await this.loadMoreResults();
    } catch (error) {
      console.error('Search error:', error);
      this.showErrorState('An error occurred while searching.');
    }
  }

  async loadMoreResults() {
    const startIndex = this.displayedCount;
    const endIndex = Math.min(startIndex + this.RESULTS_PER_PAGE, this.allSearchResults.length);

    if (startIndex >= this.allSearchResults.length) return;

    const resultsData = await Promise.all(
      this.allSearchResults.slice(startIndex, endIndex).map(r => r.data())
    );

    const newGrouped = this.groupResults(resultsData);
    this.groupedResults = [...this.groupedResults, ...newGrouped];
    this.displayedCount = endIndex;

    this.results = this.flattenForNavigation(this.groupedResults);
    this.renderGroupedResults(this.groupedResults, this.currentQuery, this.allSearchResults.length);
  }

  handleLoadMore(event) {
    event.preventDefault();
    this.loadMoreResults();
  }

  groupResults(resultsData) {
    const grouped = [];

    for (const result of resultsData) {
      const pageTitle = result.meta?.title || this.extractTitleFromUrl(result.url);

      const subResults = (result.sub_results || [])
        .filter(sub => {
          if (sub.url === result.url) return false;
          if (!sub.title) return false;
          const cleanedTitle = this.cleanSectionTitle(sub.title);
          if (cleanedTitle.toLowerCase() === pageTitle.toLowerCase()) return false;
          return true;
        })
        .slice(0, 3)
        .map(sub => ({
          url: sub.url,
          title: this.cleanSectionTitle(sub.title),
          excerpt: sub.excerpt || '',
          type: 'section'
        }));

      grouped.push({
        url: result.url,
        title: pageTitle,
        excerpt: result.excerpt || '',
        type: 'page',
        sections: subResults
      });
    }

    return grouped;
  }

  cleanSectionTitle(title) {
    return title.replace(/#$/, '').trim();
  }

  flattenForNavigation(grouped) {
    const flat = [];
    for (const page of grouped) {
      flat.push({ url: page.url, title: page.title });
      for (const section of page.sections) {
        flat.push({ url: section.url, title: section.title });
      }
    }
    return flat;
  }

  renderGroupedResults(grouped, query, totalResults) {
    this.hideAllStates();
    if (this.body) {
      this.body.hidden = false;
    }
    this.resultsContainer.hidden = false;
    this.selectedIndex = 0;

    let navIndex = 0;
    const resultsHtml = grouped.map(page => {
      const pageIndex = navIndex++;
      const isPageSelected = pageIndex === 0;

      const sectionsHtml = page.sections.map(section => {
        const sectionIndex = navIndex++;
        const isSectionSelected = sectionIndex === 0;
        return this.renderSectionResult(section, sectionIndex, isSectionSelected, query);
      }).join('');

      return this.renderPageResult(page, pageIndex, isPageSelected, sectionsHtml, query);
    }).join('');

    const hasMore = this.displayedCount < totalResults;
    const loadMoreHtml = hasMore ? `
      <li class="search-load-more">
        <button type="button" class="search-load-more-btn" data-search-load-more>
          View more results
        </button>
      </li>
    ` : '';

    this.resultsContainer.innerHTML = resultsHtml + loadMoreHtml;

    const loadMoreBtn = this.resultsContainer.querySelector('[data-search-load-more]');
    if (loadMoreBtn) {
      loadMoreBtn.addEventListener('click', this.handleLoadMore);
    }
  }

  renderPageResult(page, index, isSelected, sectionsHtml, query) {
    const pageIcon = `<svg class="search-result-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor">
      <path d="M216,40H40A16,16,0,0,0,24,56V200a16,16,0,0,0,16,16H216a16,16,0,0,0,16-16V56A16,16,0,0,0,216,40Zm0,160H40V56H216V200ZM184,96a8,8,0,0,1-8,8H80a8,8,0,0,1,0-16h96A8,8,0,0,1,184,96Zm0,32a8,8,0,0,1-8,8H80a8,8,0,0,1,0-16h96A8,8,0,0,1,184,128Zm0,32a8,8,0,0,1-8,8H80a8,8,0,0,1,0-16h96A8,8,0,0,1,184,160Z"></path>
    </svg>`;

    const titleHtml = this.highlightTitle(page.title, query);
    const excerptHtml = page.excerpt ? `<span class="search-result-excerpt">${this.highlightQuery(page.excerpt, query, page.title)}</span>` : '';

    return `
      <li class="search-result-group">
        <a href="${page.url}" class="search-result search-result-page" role="option" aria-selected="${isSelected}" data-index="${index}">
          ${pageIcon}
          <div class="search-result-content">
            <span class="search-result-title">${titleHtml}</span>
            ${excerptHtml}
          </div>
        </a>
        ${sectionsHtml ? `<ul class="search-result-sections">${sectionsHtml}</ul>` : ''}
      </li>
    `;
  }

  renderSectionResult(section, index, isSelected, query) {
    const hashIcon = `<svg class="search-result-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor">
      <path d="M224,88H175.4l8.47-46.57a8,8,0,0,0-15.74-2.86l-9,49.43H111.4l8.47-46.57a8,8,0,0,0-15.74-2.86L95.14,88H48a8,8,0,0,0,0,16H92.23L83.5,152H32a8,8,0,0,0,0,16H80.6l-8.47,46.57a8,8,0,0,0,6.44,9.3A7.79,7.79,0,0,0,80,224a8,8,0,0,0,7.86-6.57l9-49.43H144.6l-8.47,46.57a8,8,0,0,0,6.44,9.3A7.79,7.79,0,0,0,144,224a8,8,0,0,0,7.86-6.57l9-49.43H208a8,8,0,0,0,0-16H163.77l8.73-48H224a8,8,0,0,0,0-16Zm-76.5,64H99.77l8.73-48h47.73Z"></path>
    </svg>`;

    const titleHtml = this.highlightTitle(section.title, query);
    const excerptHtml = section.excerpt ? `<span class="search-result-excerpt">${this.highlightQuery(section.excerpt, query, section.title)}</span>` : '';

    return `
      <li class="search-result-section-item">
        <a href="${section.url}" class="search-result search-result-section" role="option" aria-selected="${isSelected}" data-index="${index}">
          <span class="search-result-tree-line"></span>
          ${hashIcon}
          <div class="search-result-content">
            <span class="search-result-title">${titleHtml}</span>
            ${excerptHtml}
          </div>
        </a>
      </li>
    `;
  }

  extractTitleFromUrl(url) {
    const path = url.replace(/\/$/, '').split('/').pop() || 'Home';
    return path
      .replace(/-/g, ' ')
      .replace(/\b\w/g, c => c.toUpperCase());
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  highlightTitle(title, query) {
    if (!query || !title) return this.escapeHtml(title);

    const escaped = this.escapeHtml(title);
    const terms = query.trim().split(/\s+/).filter(t => t.length > 1);
    if (terms.length === 0) return escaped;

    const regex = new RegExp(`(${terms.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
      .join('|')})`, 'gi');
    return escaped.replace(regex, '<mark class="search-title-highlight">$1</mark>');
  }

  highlightQuery(text, query, title = '') {
    if (!query || !text) return this.escapeHtml(text);

    let cleanText = this.decodeHtmlEntities(text);

    cleanText = cleanText.replace(/<[^>]*>/g, '');

    if (title) {
      const titlePattern = new RegExp(`^${title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}[#:]?\\s*`, 'i');
      cleanText = cleanText.replace(titlePattern, '');
    }

    cleanText = this.cleanMarkdown(cleanText);

    const escaped = this.escapeHtml(cleanText);

    const terms = query.trim().split(/\s+/).filter(t => t.length > 1);
    if (terms.length === 0) return escaped;

    const regex = new RegExp(`(${terms.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
      .join('|')})`, 'gi');
    return escaped.replace(regex, '<mark>$1</mark>');
  }

  decodeHtmlEntities(text) {
    const textarea = document.createElement('textarea');
    textarea.innerHTML = text;
    return textarea.value;
  }

  cleanMarkdown(text) {
    return text
      .replace(/```\w*(?:\s+[^`\n]*)?\n?/g, '')
      .replace(/```/g, '')
      .replace(/\{:?:?[^}]*\}/g, '')
      .replace(/(\w)#(?=\s|$|[A-Z])/g, '$1')
      .replace(/\*\*([^*]+)\*\*/g, '$1')
      .replace(/\*([^*]+)\*/g, '$1')
      .replace(/__([^_]+)__/g, '$1')
      .replace(/_([^_]+)_/g, '$1')
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
      .replace(/`([^`]+)`/g, '$1')
      .replace(/`/g, '')
      .replace(/^#+\s*/gm, '')
      .replace(/\s*title=["'][^"']*["']/gi, '')
      .replace(/https?:\/\/[^\s<>"{}|\\^`[\]]+/gi, '')
      .replace(/ftp:\/\/[^\s<>"{}|\\^`[\]]+/gi, '')
      .replace(/\b\w+:\s*["']?[^"'\s,]+["']?(?=\s|,|$)/g, '')
      .replace(/\b(const|let|var|function|interface|class|import|export|return|if|else)\b/g, '')
      .replace(/[=;{}()<>[\]]/g, ' ')
      .replace(/[✓✔✗✘→←↑↓•·►▸▹▶]/g, '')
      .replace(/^---[\s\S]*?---/m, '')
      .replace(/Skip to main content/gi, '')
      .replace(/On this page/gi, '')
      .replace(/Menu/gi, '')
      .replace(/Search\.\.\./gi, '')
      .replace(/^[\s]*[-*+]\s+/gm, '')
      .replace(/^[\s]*\d+\.\s+/gm, '')
      .replace(/\s+/g, ' ')
      .replace(/^[.\s,;:]+/, '')
      .replace(/[.\s,;:]+$/, '')
      .trim();
  }

  selectNext() {
    if (this.results.length === 0) return;

    const newIndex = Math.min(this.selectedIndex + 1, this.results.length - 1);
    this.updateSelection(newIndex);
  }

  selectPrevious() {
    if (this.results.length === 0) return;

    const newIndex = Math.max(this.selectedIndex - 1, 0);
    this.updateSelection(newIndex);
  }

  updateSelection(newIndex) {
    const resultElements = this.resultsContainer.querySelectorAll('.search-result');

    if (this.selectedIndex >= 0 && resultElements[this.selectedIndex]) {
      resultElements[this.selectedIndex].setAttribute('aria-selected', 'false');
    }

    this.selectedIndex = newIndex;
    if (resultElements[newIndex]) {
      resultElements[newIndex].setAttribute('aria-selected', 'true');
      resultElements[newIndex].scrollIntoView({ block: 'nearest' });
    }
  }

  navigateToSelected() {
    if (this.selectedIndex < 0 || this.results.length === 0) return;

    const result = this.results[this.selectedIndex];
    if (result && result.url) {
      this.close();
      window.location.href = result.url;
    }
  }

  showLoadingState() {
    this.hideAllStates();
    if (this.body) {
      this.body.hidden = false;
    }
    if (this.loadingState) {
      this.loadingState.hidden = false;
    }
  }

  showEmptyState(query = '') {
    this.hideAllStates();
    if (this.body) {
      this.body.hidden = false;
    }
    if (this.emptyState) {
      const titleEl = this.emptyState.querySelector('.search-empty-title');
      if (titleEl && query) {
        titleEl.textContent = `No results for "${query}"`;
      } else if (titleEl) {
        titleEl.textContent = 'No results found';
      }
      this.emptyState.hidden = false;
    }
  }

  showErrorState(message) {
    this.hideAllStates();
    if (this.body) {
      this.body.hidden = false;
    }
    if (this.emptyState) {
      this.emptyState.querySelector('span').textContent = message;
      this.emptyState.hidden = false;
    }
  }

  hideBody() {
    this.hideAllStates();
    if (this.body) {
      this.body.hidden = true;
    }
    this.results = [];
    this.selectedIndex = -1;
  }

  hideAllStates() {
    if (this.loadingState) this.loadingState.hidden = true;
    if (this.emptyState) this.emptyState.hidden = true;
    if (this.resultsContainer) this.resultsContainer.hidden = true;
  }

  destroy() {
    document.removeEventListener('keydown', this.handleKeyDown);
  }
}

function initializeSearch() {
  new SearchManager();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeSearch);
} else {
  initializeSearch();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SearchManager };
}
