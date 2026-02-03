var abbrPopover = null;
var abbrHideTimeout = null;

function initializeAbbreviations(root = document) {
  const abbreviations = root.querySelectorAll('.docyard-abbr');
  if (abbreviations.length === 0) return;

  if (!abbrPopover) {
    abbrPopover = createPopover();
    document.body.appendChild(abbrPopover);
  }

  abbreviations.forEach(abbr => {
    if (abbr.hasAttribute('data-abbr-initialized')) return;
    abbr.setAttribute('data-abbr-initialized', 'true');

    abbr.addEventListener('mouseenter', () => {
      clearTimeout(abbrHideTimeout);
      showPopover(abbrPopover, abbr);
    });

    abbr.addEventListener('mouseleave', () => {
      abbrHideTimeout = setTimeout(() => {
        hidePopover(abbrPopover);
      }, 100);
    });
  });
}

function createPopover() {
  const popover = document.createElement('div');
  popover.className = 'docyard-abbr-popover';
  popover.innerHTML = `
    <span class="docyard-abbr-popover__term"></span>
    <span class="docyard-abbr-popover__definition"></span>
  `;
  return popover;
}

function showPopover(popover, abbr) {
  const term = abbr.textContent;
  const definition = abbr.dataset.definition;

  popover.querySelector('.docyard-abbr-popover__term').textContent = term;
  popover.querySelector('.docyard-abbr-popover__definition').textContent = definition;

  const rect = abbr.getBoundingClientRect();
  const scrollX = window.scrollX;
  const scrollY = window.scrollY;

  popover.style.visibility = 'hidden';
  popover.classList.add('is-visible');
  popover.classList.remove('is-below');

  requestAnimationFrame(() => {
    const popoverRect = popover.getBoundingClientRect();
    let left = rect.left + scrollX + (rect.width / 2) - (popoverRect.width / 2);
    let top = rect.top + scrollY - popoverRect.height - 8;

    const viewportWidth = window.innerWidth;
    const padding = 16;

    if (left < padding) {
      left = padding;
    } else if (left + popoverRect.width > viewportWidth - padding) {
      left = viewportWidth - popoverRect.width - padding;
    }

    if (top < scrollY + padding) {
      top = rect.bottom + scrollY + 8;
      popover.classList.add('is-below');
    }

    const arrowLeft = rect.left + scrollX + (rect.width / 2) - left;
    popover.style.setProperty('--arrow-left', `${Math.max(12, Math.min(arrowLeft, popoverRect.width - 12))}px`);

    popover.style.left = `${left}px`;
    popover.style.top = `${top}px`;
    popover.style.visibility = 'visible';
  });
}

function hidePopover(popover) {
  popover.classList.remove('is-visible');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() { initializeAbbreviations(); });
} else {
  initializeAbbreviations();
}

window.docyard = window.docyard || {};
window.docyard.initAbbreviations = initializeAbbreviations;
