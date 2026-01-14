class HeadingAnchorManager {
  constructor() {
    this.anchors = document.querySelectorAll('.heading-anchor');
    this.init();
  }

  init() {
    this.anchors.forEach(anchor => {
      anchor.addEventListener('click', (e) => this.handleClick(e, anchor));
    });
  }

  
  handleClick(e, anchor) {
    e.preventDefault();

    const headingId = anchor.dataset.headingId;
    const url = `${window.location.origin}${window.location.pathname}#${headingId}`;

    this.copyToClipboard(url, anchor);

    history.pushState(null, null, `#${headingId}`);

    const heading = document.getElementById(headingId);
    if (heading) {
      const offsetTop = heading.getBoundingClientRect().top + window.pageYOffset - this.getScrollOffset();
      window.scrollTo({
        top: offsetTop,
        behavior: 'smooth'
      });
    }
  }

  getScrollOffset() {
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

  
  async copyToClipboard(text, anchor) {
    try {
      await navigator.clipboard.writeText(text);
      this.showFeedback(anchor, true);
    } catch (err) {
      this.fallbackCopyToClipboard(text);
      this.showFeedback(anchor, true);
    }
  }

  
  fallbackCopyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
  }

  
  showFeedback(anchor, success) {
    const originalTitle = anchor.getAttribute('aria-label');
    anchor.setAttribute('aria-label', success ? 'Link copied!' : 'Failed to copy');

    anchor.style.color = success ? 'var(--color-success, #10b981)' : 'var(--color-danger, #ef4444)';

    setTimeout(() => {
      anchor.setAttribute('aria-label', originalTitle);
      anchor.style.color = '';
    }, 2000);
  }
}

if (typeof window !== 'undefined') {
  document.addEventListener('DOMContentLoaded', () => {
    new HeadingAnchorManager();
  });
}
