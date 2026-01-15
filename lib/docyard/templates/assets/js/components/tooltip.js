function initializeTooltips() {
  const tooltips = document.querySelectorAll('.docyard-tooltip');
  if (tooltips.length === 0) return;

  const popover = createTooltipPopover();
  document.body.appendChild(popover);

  let hideTimeout;
  let isHoveringPopover = false;

  popover.addEventListener('mouseenter', () => {
    isHoveringPopover = true;
    clearTimeout(hideTimeout);
  });

  popover.addEventListener('mouseleave', () => {
    isHoveringPopover = false;
    hideTimeout = setTimeout(() => {
      hideTooltipPopover(popover);
    }, 100);
  });

  tooltips.forEach(tooltip => {
    tooltip.addEventListener('mouseenter', () => {
      clearTimeout(hideTimeout);
      showTooltipPopover(popover, tooltip);
    });

    tooltip.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => {
        if (!isHoveringPopover) {
          hideTooltipPopover(popover);
        }
      }, 100);
    });
  });
}

function createTooltipPopover() {
  const popover = document.createElement('div');
  popover.className = 'docyard-tooltip-popover';
  popover.innerHTML = `
    <span class="docyard-tooltip-popover__term"></span>
    <span class="docyard-tooltip-popover__description"></span>
    <a class="docyard-tooltip-popover__link" style="display: none;">
      <span class="docyard-tooltip-popover__link-text"></span>
      <svg class="docyard-tooltip-popover__link-icon" viewBox="0 0 256 256" fill="currentColor">
        <path d="M221.66,133.66l-72,72a8,8,0,0,1-11.32-11.32L196.69,136H40a8,8,0,0,1,0-16H196.69l-58.35-58.34a8,8,0,0,1,11.32-11.32l72,72A8,8,0,0,1,221.66,133.66Z"></path>
      </svg>
    </a>
  `;
  return popover;
}

function showTooltipPopover(popover, tooltip) {
  const term = tooltip.textContent;
  const description = tooltip.dataset.description;
  const link = tooltip.dataset.link;
  const linkText = tooltip.dataset.linkText;

  popover.querySelector('.docyard-tooltip-popover__term').textContent = term;
  popover.querySelector('.docyard-tooltip-popover__description').textContent = description;

  const linkEl = popover.querySelector('.docyard-tooltip-popover__link');
  if (link) {
    linkEl.href = link;
    linkEl.querySelector('.docyard-tooltip-popover__link-text').textContent = linkText;
    linkEl.style.display = 'inline-flex';
  } else {
    linkEl.style.display = 'none';
  }

  const rect = tooltip.getBoundingClientRect();
  const scrollX = window.scrollX;
  const scrollY = window.scrollY;

  popover.style.visibility = 'hidden';
  popover.classList.add('is-visible');

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
    } else {
      popover.classList.remove('is-below');
    }

    const arrowLeft = rect.left + scrollX + (rect.width / 2) - left;
    popover.style.setProperty('--arrow-left', `${Math.max(12, Math.min(arrowLeft, popoverRect.width - 12))}px`);

    popover.style.left = `${left}px`;
    popover.style.top = `${top}px`;
    popover.style.visibility = 'visible';
  });
}

function hideTooltipPopover(popover) {
  popover.classList.remove('is-visible');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeTooltips);
} else {
  initializeTooltips();
}
