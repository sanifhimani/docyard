/**
 * CodeBlockManager - Manages code block copy functionality
 *
 * @class CodeBlockManager
 */
class CodeBlockManager {
  /**
   * Create a CodeBlockManager instance
   * @param {HTMLElement} container - The .docyard-code-block container element
   */
  constructor(container) {
    if (!container) return;

    this.container = container;
    this.copyButton = container.querySelector('.docyard-code-block__copy');
    this.codeText = this.copyButton?.getAttribute('data-code') || '';

    this.originalIcon = this.copyButton?.innerHTML || '';

    this.checkIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 256 256"><path d="M229.66,77.66l-128,128a8,8,0,0,1-11.32,0l-56-56a8,8,0,0,1,11.32-11.32L96,188.69,218.34,66.34a8,8,0,0,1,11.32,11.32Z"/></svg>';

    this.handleCopy = this.handleCopy.bind(this);

    this.init();
  }

  /**
   * Initialize the code block component
   */
  init() {
    if (!this.copyButton) return;

    this.copyButton.addEventListener('click', this.handleCopy);
  }

  /**
   * Handle copy button click
   */
  async handleCopy() {
    try {
      await this.copyToClipboard(this.codeText);
      this.showSuccess();
    } catch (error) {
      console.warn('Failed to copy code:', error);
      this.showError();
    }
  }

  /**
   * Copy text to clipboard
   * @param {string} text - Text to copy
   * @returns {Promise<void>}
   */
  async copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
    } else {
      this.fallbackCopy(text);
    }
  }

  /**
   * Fallback copy method for older browsers
   * @param {string} text - Text to copy
   */
  fallbackCopy(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
      document.execCommand('copy');
      textArea.remove();
    } catch (error) {
      textArea.remove();
      throw error;
    }
  }

  /**
   * Show success state
   */
  showSuccess() {
    this.copyButton.classList.add('is-success');
    this.copyButton.setAttribute('aria-label', 'Copied to clipboard!');

    this.copyButton.innerHTML = this.checkIcon;

    if (this.resetTimeout) {
      clearTimeout(this.resetTimeout);
    }

    this.resetTimeout = setTimeout(() => {
      this.resetState();
    }, 2000);
  }

  /**
   * Show error state
   */
  showError() {
    this.copyButton.classList.add('is-error');
    this.copyButton.setAttribute('aria-label', 'Failed to copy');

    if (this.resetTimeout) {
      clearTimeout(this.resetTimeout);
    }

    this.resetTimeout = setTimeout(() => {
      this.resetState();
    }, 2000);
  }

  /**
   * Reset button to default state
   */
  resetState() {
    this.copyButton.classList.remove('is-success', 'is-error');
    this.copyButton.setAttribute('aria-label', 'Copy code to clipboard');

    this.copyButton.innerHTML = this.originalIcon;
  }

  /**
   * Cleanup - remove event listeners
   */
  destroy() {
    if (this.copyButton) {
      this.copyButton.removeEventListener('click', this.handleCopy);
    }

    if (this.resetTimeout) {
      clearTimeout(this.resetTimeout);
    }
  }
}

/**
 * Auto-initialize all code blocks on page load
 */
function initializeCodeBlocks() {
  const codeBlocks = document.querySelectorAll('.docyard-code-block');

  codeBlocks.forEach(container => {
    new CodeBlockManager(container);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeCodeBlocks);
} else {
  initializeCodeBlocks();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { CodeBlockManager };
}
