class CodeBlockManager {
  
  constructor(container) {
    if (!container) return;

    this.container = container;
    this.copyButton = container.querySelector('.docyard-code-block__copy');
    this.codeText = this.copyButton?.getAttribute('data-code') || '';

    this.iconElement = this.copyButton?.querySelector('.docyard-code-block__copy-icon');
    this.textElement = this.copyButton?.querySelector('.docyard-code-block__copy-text');
    this.originalIcon = this.iconElement?.innerHTML || '';

    this.checkIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 256 256"><path d="M229.66,77.66l-128,128a8,8,0,0,1-11.32,0l-56-56a8,8,0,0,1,11.32-11.32L96,188.69,218.34,66.34a8,8,0,0,1,11.32,11.32Z"/></svg>';

    this.handleCopy = this.handleCopy.bind(this);

    this.init();
  }

  
  init() {
    if (!this.copyButton) return;

    this.copyButton.addEventListener('click', this.handleCopy);
  }

  
  async handleCopy() {
    try {
      await this.copyToClipboard(this.codeText);
      this.showSuccess();
    } catch (error) {
      console.warn('Failed to copy code:', error);
      this.showError();
    }
  }

  
  async copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
    } else {
      this.fallbackCopy(text);
    }
  }

  
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

  
  showSuccess() {
    this.copyButton.classList.add('is-success');
    this.copyButton.setAttribute('aria-label', 'Copied to clipboard!');

    if (this.iconElement) {
      this.iconElement.innerHTML = this.checkIcon;
    }
    if (this.textElement) {
      this.textElement.textContent = 'Copied';
    }

    if (this.resetTimeout) {
      clearTimeout(this.resetTimeout);
    }

    this.resetTimeout = setTimeout(() => {
      this.resetState();
    }, 2000);
  }

  
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

  
  resetState() {
    this.copyButton.classList.remove('is-success', 'is-error');
    this.copyButton.setAttribute('aria-label', 'Copy code to clipboard');

    if (this.iconElement) {
      this.iconElement.innerHTML = this.originalIcon;
    }
    if (this.textElement) {
      this.textElement.textContent = 'Copy';
    }
  }

  
  destroy() {
    if (this.copyButton) {
      this.copyButton.removeEventListener('click', this.handleCopy);
    }

    if (this.resetTimeout) {
      clearTimeout(this.resetTimeout);
    }
  }
}

function initializeCodeBlocks(root = document) {
  const codeBlocks = root.querySelectorAll('.docyard-code-block');

  codeBlocks.forEach(container => {
    if (container.hasAttribute('data-code-block-initialized')) return;
    container.setAttribute('data-code-block-initialized', 'true');
    new CodeBlockManager(container);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() { initializeCodeBlocks(); });
} else {
  initializeCodeBlocks();
}

window.docyard = window.docyard || {};
window.docyard.initCodeBlocks = initializeCodeBlocks;

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { CodeBlockManager };
}
