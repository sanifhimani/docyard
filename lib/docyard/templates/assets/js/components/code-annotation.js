var annotationPopover = null;
var activeAnnotationButton = null;

function initCodeAnnotations(root) {
  if (typeof root === 'undefined') root = document;
  var buttons = root.querySelectorAll('.docyard-code-annotation');
  if (buttons.length === 0) return;

  if (!annotationPopover) {
    annotationPopover = document.createElement('div');
    annotationPopover.className = 'docyard-code-annotation-popover';
    document.body.appendChild(annotationPopover);

    document.addEventListener('click', function(e) {
      if (activeAnnotationButton &&
          !annotationPopover.contains(e.target) &&
          !e.target.closest('.docyard-code-annotation')) {
        hideAnnotationPopover();
      }
    });

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && activeAnnotationButton) {
        hideAnnotationPopover();
        activeAnnotationButton.focus();
      }
    });
  }

  buttons.forEach(function(button) {
    if (button.hasAttribute('data-annotation-initialized')) return;
    button.setAttribute('data-annotation-initialized', 'true');

    button.addEventListener('click', function(e) {
      e.stopPropagation();
      if (activeAnnotationButton === button) {
        hideAnnotationPopover();
      } else {
        showAnnotationPopover(button);
      }
    });
  });
}

function setAnnotationIcon(button, name, animate) {
  var icon = button.querySelector('i[class*="ph-"]');
  if (!icon) return;
  if (!animate) {
    icon.className = 'ph ph-' + name;
    return;
  }
  icon.style.transition = 'opacity 100ms ease, transform 100ms ease';
  icon.style.opacity = '0';
  icon.style.transform = 'scale(0.5)';
  setTimeout(function() {
    icon.className = 'ph ph-' + name;
    icon.style.opacity = '1';
    icon.style.transform = 'scale(1)';
  }, 100);
}

function showAnnotationPopover(button) {
  if (activeAnnotationButton) {
    setAnnotationIcon(activeAnnotationButton, 'plus-circle', true);
    activeAnnotationButton.classList.remove('is-active');
  }

  activeAnnotationButton = button;
  button.classList.add('is-active');
  setAnnotationIcon(button, 'x-circle', true);
  annotationPopover.innerHTML = button.getAttribute('data-annotation-content');

  annotationPopover.classList.remove('is-above');
  annotationPopover.style.visibility = 'hidden';
  annotationPopover.classList.add('is-visible');

  requestAnimationFrame(function() {
    positionPopover(button);
  });
}

function positionPopover(button) {
  var rect = button.getBoundingClientRect();
  var scrollX = window.scrollX;
  var scrollY = window.scrollY;
  var popoverRect = annotationPopover.getBoundingClientRect();
  var gap = 6;
  var padding = 12;
  var viewportWidth = window.innerWidth;
  var viewportHeight = window.innerHeight;

  var left = rect.left + scrollX + (rect.width / 2) - (popoverRect.width / 2);
  var spaceBelow = viewportHeight - rect.bottom;
  var spaceAbove = rect.top;
  var openAbove = spaceBelow < popoverRect.height + gap + padding && spaceAbove > spaceBelow;

  var top;
  if (openAbove) {
    top = rect.top + scrollY - popoverRect.height - gap;
    annotationPopover.classList.add('is-above');
  } else {
    top = rect.bottom + scrollY + gap;
    annotationPopover.classList.remove('is-above');
  }

  if (left < padding) {
    left = padding;
  } else if (left + popoverRect.width > viewportWidth - padding) {
    left = viewportWidth - popoverRect.width - padding;
  }

  var arrowLeft = rect.left + scrollX + (rect.width / 2) - left;
  annotationPopover.style.setProperty('--arrow-left', Math.max(12, Math.min(arrowLeft, popoverRect.width - 12)) + 'px');
  annotationPopover.style.left = left + 'px';
  annotationPopover.style.top = top + 'px';
  annotationPopover.style.visibility = 'visible';
}

function hideAnnotationPopover() {
  if (!annotationPopover) return;
  if (activeAnnotationButton) {
    setAnnotationIcon(activeAnnotationButton, 'plus-circle', true);
    activeAnnotationButton.classList.remove('is-active');
  }
  annotationPopover.classList.remove('is-visible');
  activeAnnotationButton = null;
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() { initCodeAnnotations(); });
} else {
  initCodeAnnotations();
}

window.docyard = window.docyard || {};
window.docyard.initCodeAnnotations = initCodeAnnotations;
