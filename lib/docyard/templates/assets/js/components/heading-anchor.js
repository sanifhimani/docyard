function initializeHeadingAnchors(root = document) {
  const anchors = root.querySelectorAll('.heading-anchor');
  if (anchors.length === 0) return;

  anchors.forEach(anchor => {
    if (anchor.hasAttribute('data-anchor-initialized')) return;
    anchor.setAttribute('data-anchor-initialized', 'true');
    anchor.addEventListener('click', (e) => handleHeadingAnchorClick(e, anchor));
  });
}

function handleHeadingAnchorClick(e, anchor) {
  e.preventDefault();

  const headingId = anchor.dataset.headingId;
  const url = `${window.location.origin}${window.location.pathname}#${headingId}`;

  copyAnchorToClipboard(url, anchor);

  history.pushState(null, null, `#${headingId}`);

  const heading = document.getElementById(headingId);
  if (heading) {
    const offsetTop = heading.getBoundingClientRect().top + window.pageYOffset - getAnchorScrollOffset();
    window.scrollTo({
      top: offsetTop,
      behavior: 'smooth'
    });
  }
}

function getAnchorScrollOffset() {
  const hasTabs = document.body.classList.contains('has-tabs');
  const headerHeight = 64;
  const tabBarHeight = hasTabs ? 48 : 0;
  const buffer = 24;

  if (window.innerWidth > 1024 && window.innerWidth <= 1280) {
    return headerHeight + 48 + buffer;
  }

  if (window.innerWidth <= 1024) {
    return headerHeight + 48 + buffer;
  }

  return headerHeight + tabBarHeight + buffer;
}

async function copyAnchorToClipboard(text, anchor) {
  try {
    await navigator.clipboard.writeText(text);
    showAnchorFeedback(anchor, true);
  } catch (err) {
    fallbackAnchorCopy(text);
    showAnchorFeedback(anchor, true);
  }
}

function fallbackAnchorCopy(text) {
  const textarea = document.createElement('textarea');
  textarea.value = text;
  textarea.style.position = 'fixed';
  textarea.style.opacity = '0';
  document.body.appendChild(textarea);
  textarea.select();
  document.execCommand('copy');
  document.body.removeChild(textarea);
}

function showAnchorFeedback(anchor, success) {
  const originalTitle = anchor.getAttribute('aria-label');
  anchor.setAttribute('aria-label', success ? 'Link copied!' : 'Failed to copy');

  anchor.style.color = success ? 'var(--color-success, #10b981)' : 'var(--color-danger, #ef4444)';

  setTimeout(() => {
    anchor.setAttribute('aria-label', originalTitle);
    anchor.style.color = '';
  }, 2000);
}

if (typeof window !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { initializeHeadingAnchors(); });
  } else {
    initializeHeadingAnchors();
  }

  window.docyard = window.docyard || {};
  window.docyard.initHeadingAnchors = initializeHeadingAnchors;
}
