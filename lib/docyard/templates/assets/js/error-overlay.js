(function () {
  var container = document.getElementById('docyard-error-overlay');
  if (!container) return;

  var diagnostics = JSON.parse(container.dataset.diagnostics);
  var currentFile = container.dataset.currentFile;
  var errorCount = parseInt(container.dataset.errorCount, 10);
  var warningCount = parseInt(container.dataset.warningCount, 10);
  var globalCount = parseInt(container.dataset.globalCount, 10);
  var pageCount = parseInt(container.dataset.pageCount, 10);
  var ssePort = container.dataset.ssePort;
  var editorAvailable = container.dataset.editorAvailable === 'true';

  var GLOBAL_CATEGORIES = ['CONFIG', 'SIDEBAR', 'ORPHAN'];
  var CATEGORY_LABELS = {
    CONFIG: 'Configuration',
    SIDEBAR: 'Sidebar',
    CONTENT: 'Content',
    COMPONENT: 'Components',
    LINK: 'Broken links',
    IMAGE: 'Missing images',
    SYNTAX: 'Syntax',
    ORPHAN: 'Orphan pages'
  };

  var STORAGE_KEY = 'docyard-error-overlay';

  function getStoredState() {
    try {
      var stored = sessionStorage.getItem(STORAGE_KEY);
      return stored ? JSON.parse(stored) : null;
    } catch (e) {
      return null;
    }
  }

  function storeState(dismissed, totalCount) {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
        dismissed: dismissed,
        lastTotalCount: totalCount
      }));
    } catch (e) {
    }
  }

  function shouldStartExpanded() {
    var stored = getStoredState();
    if (!stored || !stored.dismissed) {
      return true;
    }
    var currentTotal = errorCount + warningCount;
    var storedTotal = stored.lastTotalCount || 0;
    if (currentTotal < storedTotal) {
      storeState(true, currentTotal);
      return false;
    }
    return currentTotal > storedTotal;
  }

  var state = {
    expanded: shouldStartExpanded(),
    activeTab: pageCount > 0 ? 'page' : 'global'
  };

  function init() {
    render();
    setupEventListeners();
    setupSSE();
    if (state.expanded) {
      document.body.style.overflow = 'hidden';
    }
  }

  function render() {
    var html = renderBackdrop() + renderSheet() + renderToast();
    container.innerHTML = html;
    requestAnimationFrame(function () {
      updateTabIndicator();
      var indicator = container.querySelector('.docyard-error-tabs__indicator');
      if (indicator) {
        requestAnimationFrame(function () {
          indicator.classList.add('is-ready');
        });
      }
    });
  }

  function renderBackdrop() {
    return '<div class="docyard-error-backdrop' + (state.expanded ? ' is-visible' : '') + '"></div>';
  }

  function renderSheet() {
    return [
      '<div class="docyard-error-sheet' + (state.expanded ? ' is-expanded' : '') + '">',
      '<div class="docyard-error-sheet__drag-handle"></div>',
      renderHeader(),
      renderTabs(),
      renderContent(),
      renderFooter(),
      '</div>'
    ].join('');
  }

  function renderHeader() {
    return [
      '<div class="docyard-error-sheet__header">',
      '<div class="docyard-error-sheet__counts">',
      errorCount > 0 ? '<span class="docyard-error-sheet__count has-errors"><i class="ph ph-siren"></i>' + errorCount + ' error' + (errorCount !== 1 ? 's' : '') + '</span>' : '',
      warningCount > 0 ? '<span class="docyard-error-sheet__count has-warnings"><i class="ph ph-warning"></i>' + warningCount + ' warning' + (warningCount !== 1 ? 's' : '') + '</span>' : '',
      '</div>',
      '<button class="docyard-error-sheet__close" data-action="dismiss"><i class="ph ph-x"></i></button>',
      '</div>'
    ].join('');
  }

  function renderTabs() {
    var total = diagnostics.length;
    return [
      '<div class="docyard-error-tabs">',
      '<button class="docyard-error-tabs__tab' + (state.activeTab === 'global' ? ' is-active' : '') + '" data-tab="global">Global<span class="docyard-error-tabs__tab-count">' + globalCount + '</span></button>',
      '<button class="docyard-error-tabs__tab' + (state.activeTab === 'page' ? ' is-active' : '') + '" data-tab="page">This page<span class="docyard-error-tabs__tab-count">' + pageCount + '</span></button>',
      '<button class="docyard-error-tabs__tab' + (state.activeTab === 'all' ? ' is-active' : '') + '" data-tab="all">All<span class="docyard-error-tabs__tab-count">' + total + '</span></button>',
      '<div class="docyard-error-tabs__indicator"></div>',
      '</div>'
    ].join('');
  }

  function renderContent() {
    var globalDiags = diagnostics.filter(function (d) { return GLOBAL_CATEGORIES.indexOf(d.category) !== -1; });
    var pageDiags = diagnostics.filter(function (d) { return GLOBAL_CATEGORIES.indexOf(d.category) === -1; });

    return [
      '<div class="docyard-error-sheet__content">',
      '<div class="docyard-error-section' + (state.activeTab === 'global' ? ' is-active' : '') + '" data-section="global">',
      globalDiags.length > 0 ? renderDiagnosticsList(globalDiags, 'affects all pages') : renderEmpty('No global issues'),
      '</div>',
      '<div class="docyard-error-section' + (state.activeTab === 'page' ? ' is-active' : '') + '" data-section="page">',
      pageDiags.length > 0 ? renderDiagnosticsList(pageDiags, currentFile) : renderEmpty('No issues on this page'),
      '</div>',
      '<div class="docyard-error-section' + (state.activeTab === 'all' ? ' is-active' : '') + '" data-section="all">',
      diagnostics.length > 0 ? renderDiagnosticsList(diagnostics, null) : renderEmpty('No issues'),
      '</div>',
      '</div>'
    ].join('');
  }

  function renderDiagnosticsList(diags, scope) {
    var grouped = groupByCategory(diags);
    var html = [];

    Object.keys(grouped).forEach(function (category) {
      var items = grouped[category];
      var label = CATEGORY_LABELS[category] || category;
      var scopeText = scope ? ' - ' + scope : '';

      html.push('<div class="docyard-error-section__header">' + label + '<span class="docyard-error-section__scope">' + scopeText + '</span></div>');

      items.forEach(function (diag) {
        html.push(renderDiagnosticItem(diag));
      });
    });

    return html.join('');
  }

  function groupByCategory(diags) {
    var groups = {};
    diags.forEach(function (d) {
      if (!groups[d.category]) groups[d.category] = [];
      groups[d.category].push(d);
    });
    return groups;
  }

  function renderDiagnosticItem(diag) {
    var icon = diag.severity === 'error' ? 'ph-siren' : 'ph-warning';
    var severityClass = diag.severity === 'error' ? 'is-error' : 'is-warning';
    var location = diag.file ? (diag.line ? diag.file + ':' + diag.line : diag.file) : (diag.field || '');

    var html = [
      '<div class="docyard-error-item">',
      '<div class="docyard-error-item__header">',
      '<i class="ph ' + icon + ' docyard-error-item__indicator ' + severityClass + '"></i>',
      '<div class="docyard-error-item__info">',
      '<div class="docyard-error-item__title">' + escapeHtml(diag.message) + '</div>',
      '<div class="docyard-error-item__meta">'
    ];

    if (location) {
      html.push('<a href="#" class="docyard-error-item__location" data-action="open" data-file="' + escapeAttr(diag.file || '') + '" data-line="' + (diag.line || 1) + '">' + escapeHtml(location) + '</a>');
    }

    if (diag.doc_url) {
      html.push('<a href="' + escapeAttr(diag.doc_url) + '" class="docyard-error-item__doc-link" target="_blank"><i class="ph ph-book-open"></i>Docs</a>');
    }

    html.push('</div></div>');

    if (editorAvailable && diag.file) {
      html.push('<div class="docyard-error-item__actions">');
      html.push('<button class="docyard-error-item__action" data-action="open" data-file="' + escapeAttr(diag.file) + '" data-line="' + (diag.line || 1) + '"><i class="ph ph-app-window"></i>Open in editor</button>');
      html.push('</div>');
    }

    html.push('</div>');

    if (diag.source_context && diag.source_context.length > 0) {
      html.push(renderCodeFrame(diag));
    }

    html.push('</div>');

    return html.join('');
  }

  function renderCodeFrame(diag) {
    var lines = diag.source_context.map(function (ctx) {
      var highlightClass = ctx.highlighted ? ' is-highlighted' : '';
      return [
        '<div class="docyard-error-code-frame__line' + highlightClass + '">',
        '<span class="docyard-error-code-frame__line-number">' + ctx.line + '</span>',
        '<span class="docyard-error-code-frame__line-content">' + escapeHtml(ctx.content) + '</span>',
        '</div>'
      ].join('');
    }).join('');

    return [
      '<div class="docyard-error-code-frame">',
      '<div class="docyard-error-code-frame__header">' + escapeHtml(diag.file) + '</div>',
      '<div class="docyard-error-code-frame__lines">',
      lines,
      '</div>',
      '</div>'
    ].join('');
  }

  function renderEmpty(message) {
    return '<div class="docyard-error-empty">' + message + '</div>';
  }

  function renderFooter() {
    return [
      '<div class="docyard-error-sheet__footer">',
      '<span class="docyard-error-sheet__hint">Press <kbd>Esc</kbd> to dismiss</span>',
      '</div>'
    ].join('');
  }

  function renderToast() {
    var html = [
      '<div class="docyard-error-toast' + (!state.expanded ? ' is-visible' : '') + '" data-action="expand">',
      '<div class="docyard-error-toast__content">'
    ];

    if (errorCount > 0) {
      html.push('<span class="docyard-error-toast__item has-errors"><i class="ph ph-siren"></i><span class="docyard-error-toast__count">' + errorCount + '</span><span class="docyard-error-toast__label"> error' + (errorCount !== 1 ? 's' : '') + '</span></span>');
    }

    if (errorCount > 0 && warningCount > 0) {
      html.push('<span class="docyard-error-toast__separator">|</span>');
    }

    if (warningCount > 0) {
      html.push('<span class="docyard-error-toast__item has-warnings"><i class="ph ph-warning"></i><span class="docyard-error-toast__count">' + warningCount + '</span><span class="docyard-error-toast__label"> warning' + (warningCount !== 1 ? 's' : '') + '</span></span>');
    }

    html.push('</div>');
    html.push('<span class="docyard-error-toast__hint">Click to view</span>');
    html.push('</div>');

    return html.join('');
  }

  function setupEventListeners() {
    container.addEventListener('click', function (e) {
      var target = e.target.closest('[data-action]');
      if (!target) {
        if (e.target.classList.contains('docyard-error-backdrop')) {
          dismiss();
        }
        return;
      }

      var action = target.dataset.action;

      if (action === 'dismiss') {
        dismiss();
      } else if (action === 'expand') {
        expand();
      } else if (action === 'open') {
        e.preventDefault();
        openInEditor(target.dataset.file, target.dataset.line);
      }
    });

    container.addEventListener('click', function (e) {
      var tab = e.target.closest('[data-tab]');
      if (!tab) return;

      var prevTab = state.activeTab;
      var newTab = tab.dataset.tab;
      if (prevTab === newTab) return;

      var tabs = ['global', 'page', 'all'];
      var prevIndex = tabs.indexOf(prevTab);
      var newIndex = tabs.indexOf(newTab);
      var direction = newIndex > prevIndex ? 'right' : 'left';

      state.activeTab = newTab;

      container.querySelectorAll('.docyard-error-tabs__tab').forEach(function (t) {
        t.classList.toggle('is-active', t.dataset.tab === newTab);
      });

      container.querySelectorAll('.docyard-error-section').forEach(function (section) {
        var isActive = section.dataset.section === newTab;
        section.classList.toggle('is-active', isActive);
        if (isActive) {
          section.dataset.direction = direction;
        }
      });

      updateTabIndicator();
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && state.expanded) {
        dismiss();
      }
    });

    setupTouchHandling();
  }

  function setupTouchHandling() {
    var startY = 0;
    var currentY = 0;
    var isDragging = false;
    var sheet = null;

    container.addEventListener('touchstart', function (e) {
      var handle = e.target.closest('.docyard-error-sheet__drag-handle');
      if (!handle) return;

      sheet = container.querySelector('.docyard-error-sheet');
      if (!sheet || !state.expanded) return;

      isDragging = true;
      startY = e.touches[0].clientY;
      currentY = startY;
      sheet.style.transition = 'none';
    }, { passive: true });

    document.addEventListener('touchmove', function (e) {
      if (!isDragging || !sheet) return;

      currentY = e.touches[0].clientY;
      var deltaY = currentY - startY;

      if (deltaY > 0) {
        sheet.style.transform = 'translateY(' + deltaY + 'px)';
      }
    }, { passive: true });

    document.addEventListener('touchend', function () {
      if (!isDragging || !sheet) return;

      var deltaY = currentY - startY;
      sheet.style.transition = '';
      sheet.style.transform = '';

      if (deltaY > 80) {
        dismiss();
      }

      isDragging = false;
      sheet = null;
    });
  }

  function updateTabIndicator() {
    var activeTab = container.querySelector('.docyard-error-tabs__tab.is-active');
    var indicator = container.querySelector('.docyard-error-tabs__indicator');
    if (!activeTab || !indicator) return;

    var tabsContainer = container.querySelector('.docyard-error-tabs');
    var containerRect = tabsContainer.getBoundingClientRect();
    var tabRect = activeTab.getBoundingClientRect();

    indicator.style.width = tabRect.width + 'px';
    indicator.style.transform = 'translateX(' + (tabRect.left - containerRect.left) + 'px)';
  }

  function dismiss() {
    state.expanded = false;
    document.body.style.overflow = '';
    storeState(true, errorCount + warningCount);

    var sheet = container.querySelector('.docyard-error-sheet');
    var backdrop = container.querySelector('.docyard-error-backdrop');
    var toast = container.querySelector('.docyard-error-toast');

    if (sheet) {
      sheet.classList.add('is-dismissing');
      sheet.classList.remove('is-expanded');
    }
    if (backdrop) backdrop.classList.remove('is-visible');

    setTimeout(function () {
      if (toast) toast.classList.add('is-visible');
      if (sheet) sheet.classList.remove('is-dismissing');
    }, 150);
  }

  function expand() {
    state.expanded = true;
    document.body.style.overflow = 'hidden';
    storeState(false, errorCount + warningCount);

    var sheet = container.querySelector('.docyard-error-sheet');
    var backdrop = container.querySelector('.docyard-error-backdrop');
    var toast = container.querySelector('.docyard-error-toast');

    if (toast) toast.classList.remove('is-visible');

    setTimeout(function () {
      if (sheet) sheet.classList.add('is-expanded');
      if (backdrop) backdrop.classList.add('is-visible');
    }, 50);
  }

  function openInEditor(file, line) {
    if (!editorAvailable) return;

    fetch('/__docyard/open-in-editor?file=' + encodeURIComponent(file) + '&line=' + (line || 1))
      .catch(function (err) {
        console.error('[Docyard] Failed to open editor:', err);
      });
  }

  function setupSSE() {
    if (!ssePort) return;

    var url = 'http://127.0.0.1:' + ssePort + '/';
    var eventSource = new EventSource(url);

    eventSource.addEventListener('diagnostics', function (event) {
      var data = JSON.parse(event.data);
      if (data.global) {
        updateGlobalDiagnostics(data.global);
      }
    });

    eventSource.onerror = function () {
      eventSource.close();
    };
  }

  function updateGlobalDiagnostics(globalDiags) {
    var pageDiags = diagnostics.filter(function(d) {
      return GLOBAL_CATEGORIES.indexOf(d.category) === -1;
    });

    var prevTotal = errorCount + warningCount;

    diagnostics = globalDiags.concat(pageDiags);
    errorCount = diagnostics.filter(function(d) { return d.severity === 'error'; }).length;
    warningCount = diagnostics.filter(function(d) { return d.severity === 'warning'; }).length;
    globalCount = globalDiags.length;
    pageCount = pageDiags.length;

    container.dataset.diagnostics = JSON.stringify(diagnostics);
    container.dataset.errorCount = errorCount;
    container.dataset.warningCount = warningCount;
    container.dataset.globalCount = globalCount;
    container.dataset.pageCount = pageCount;

    var currentTotal = errorCount + warningCount;
    if (!state.expanded && currentTotal > prevTotal) {
      state.expanded = true;
      storeState(false, currentTotal);
    }

    render();

    if (state.expanded) {
      document.body.style.overflow = 'hidden';
    }
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escapeAttr(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;');
  }

  function updateFromDataset(dataset) {
    var prevTotal = errorCount + warningCount;

    diagnostics = JSON.parse(dataset.diagnostics);
    currentFile = dataset.currentFile;
    errorCount = parseInt(dataset.errorCount, 10);
    warningCount = parseInt(dataset.warningCount, 10);
    globalCount = parseInt(dataset.globalCount, 10);
    pageCount = parseInt(dataset.pageCount, 10);

    container.dataset.diagnostics = dataset.diagnostics;
    container.dataset.currentFile = dataset.currentFile;
    container.dataset.errorCount = dataset.errorCount;
    container.dataset.warningCount = dataset.warningCount;
    container.dataset.globalCount = dataset.globalCount;
    container.dataset.pageCount = dataset.pageCount;

    if (pageCount > 0 && state.activeTab === 'global') {
      state.activeTab = 'page';
    }

    var currentTotal = errorCount + warningCount;
    if (!state.expanded && currentTotal > prevTotal) {
      state.expanded = true;
      storeState(false, currentTotal);
    }

    render();

    if (state.expanded) {
      document.body.style.overflow = 'hidden';
    }
  }

  window.docyardErrorOverlay = {
    update: updateFromDataset
  };

  init();
})();
