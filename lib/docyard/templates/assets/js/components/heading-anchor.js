/**
 * HeadingAnchorManager handles anchor link interactions
 * Provides copy-to-clipboard functionality with visual feedback
 */
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

  /**
   * Handle anchor link click
   * @param {Event} e - Click event
   * @param {HTMLElement} anchor - Anchor element
   */
  handleClick(e, anchor) {
    e.preventDefault();

    const headingId = anchor.dataset.headingId;
    const url = `${window.location.origin}${window.location.pathname}#${headingId}`;

    this.copyToClipboard(url, anchor);

    history.pushState(null, null, `#${headingId}`);

    const heading = document.getElementById(headingId);
    if (heading) {
      heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  /**
   * Copy text to clipboard with visual feedback
   * @param {string} text - Text to copy
   * @param {HTMLElement} anchor - Anchor element for feedback
   */
  async copyToClipboard(text, anchor) {
    try {
      await navigator.clipboard.writeText(text);
      this.showFeedback(anchor, true);
    } catch (err) {
      this.fallbackCopyToClipboard(text);
      this.showFeedback(anchor, true);
    }
  }

  /**
   * Fallback copy method for older browsers
   * @param {string} text - Text to copy
   */
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

  /**
   * Show visual feedback on copy
   * @param {HTMLElement} anchor - Anchor element
   * @param {boolean} success - Whether copy succeeded
   */
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
