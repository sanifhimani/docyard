(function () {
  var ssePort = window.__DOCYARD_SSE_PORT__;
  if (!ssePort) return;

  var url = 'http://127.0.0.1:' + ssePort + '/';
  var eventSource = new EventSource(url);

  eventSource.addEventListener('reload', function (event) {
    var data = JSON.parse(event.data);
    if (data.type === 'content') {
      console.log('[Docyard] Content updated');
      reloadContent();
    } else if (data.type === 'css') {
      console.log('[Docyard] CSS updated');
      reloadStyles();
    } else {
      console.log('[Docyard] Full reload');
      location.reload();
    }
  });

  eventSource.onerror = function () {
    eventSource.close();
  };

  function reloadStyles() {
    var links = document.querySelectorAll('link[rel="stylesheet"]');
    var cacheBuster = Date.now();

    links.forEach(function (link) {
      var href = link.getAttribute('href');
      if (!href) return;

      var baseHref = href.split('?')[0];
      var newHref = baseHref + '?_dc=' + cacheBuster;

      var newLink = document.createElement('link');
      newLink.rel = 'stylesheet';
      newLink.href = newHref;

      newLink.onload = function () {
        link.remove();
      };

      link.parentNode.insertBefore(newLink, link.nextSibling);
    });
  }

  function reinitializeComponents(container) {
    if (window.Prism) window.Prism.highlightAll();
    if (window.docyardTOC) window.docyardTOC.init();

    var docyard = window.docyard || {};
    if (docyard.initTabs) docyard.initTabs(container);
    if (docyard.initFileTrees) docyard.initFileTrees(container);
    if (docyard.initCodeGroups) docyard.initCodeGroups(container);
    if (docyard.initCodeBlocks) docyard.initCodeBlocks(container);
    if (docyard.initHeadingAnchors) docyard.initHeadingAnchors(container);
    if (docyard.initAbbreviations) docyard.initAbbreviations(container);
    if (docyard.initLightbox) docyard.initLightbox(container);
    if (docyard.initTooltips) docyard.initTooltips(container);
    if (docyard.initCodeAnnotations) docyard.initCodeAnnotations(container);
  }

  function reloadContent() {
    var cacheBuster = '_dc=' + Date.now();
    var separator = location.href.indexOf('?') === -1 ? '?' : '&';
    fetch(location.href + separator + cacheBuster)
      .then(function (response) { return response.text(); })
      .then(function (html) {
        var parser = new DOMParser();
        var newDoc = parser.parseFromString(html, 'text/html');
        var newContent = newDoc.querySelector('.content');
        var currentContent = document.querySelector('.content');

        if (newContent && currentContent) {
          currentContent.innerHTML = newContent.innerHTML;
          reinitializeComponents(currentContent);
          updateErrorOverlay(newDoc);
        } else {
          location.reload();
        }
      })
      .catch(function () {
        location.reload();
      });
  }

  function updateErrorOverlay(newDoc) {
    var newOverlay = newDoc.getElementById('docyard-error-overlay');
    var currentOverlay = document.getElementById('docyard-error-overlay');

    var newData = newOverlay ? newOverlay.dataset : null;
    var currentData = currentOverlay ? currentOverlay.dataset : null;

    var changed = diagnosticsChanged(newData, currentData);
    if (!changed) return;

    if (newOverlay && window.docyardErrorOverlay && window.docyardErrorOverlay.update) {
      window.docyardErrorOverlay.update(newOverlay.dataset);
    } else {
      location.reload();
    }
  }

  function diagnosticsChanged(newData, currentData) {
    if (!newData && !currentData) return false;
    if (!newData || !currentData) return true;
    return newData.errorCount !== currentData.errorCount ||
      newData.warningCount !== currentData.warningCount ||
      newData.diagnostics !== currentData.diagnostics;
  }
})();
