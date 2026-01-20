class CopyPageManager {
  constructor() {
    this.buttons = document.querySelectorAll('[data-copy-page]');
    this.markdownElement = document.getElementById('page-markdown');
    this.checkIcon = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 256 256"><path d="M229.66,77.66l-128,128a8,8,0,0,1-11.32,0l-56-56a8,8,0,0,1,11.32-11.32L96,188.69,218.34,66.34a8,8,0,0,1,11.32,11.32Z"/></svg>';

    this.handleCopy = this.handleCopy.bind(this);
    this.init();
  }

  init() {
    if (!this.markdownElement || this.buttons.length === 0) return;

    this.buttons.forEach(button => {
      button.addEventListener('click', this.handleCopy);
    });
  }

  getMarkdownContent() {
    if (!this.markdownElement) return null;

    try {
      return JSON.parse(this.markdownElement.textContent);
    } catch (error) {
      console.warn('Failed to parse markdown content:', error);
      return null;
    }
  }

  async handleCopy(event) {
    const button = event.currentTarget;
    const content = this.getMarkdownContent();

    if (!content) {
      console.warn('No markdown content available to copy');
      return;
    }

    try {
      await this.copyToClipboard(content);
      this.showSuccess(button);
    } catch (error) {
      console.warn('Failed to copy page:', error);
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

  showSuccess(button) {
    const iconElement = button.querySelector('svg');
    const textElement = button.querySelector('.page-actions__copy-text');
    const originalIcon = iconElement?.outerHTML;

    button.classList.add('is-copied');

    if (iconElement) {
      iconElement.outerHTML = this.checkIcon;
    }
    if (textElement) {
      textElement.textContent = 'Copied';
    }

    setTimeout(() => {
      button.classList.remove('is-copied');
      const newIcon = button.querySelector('svg');
      if (newIcon && originalIcon) {
        newIcon.outerHTML = originalIcon;
      }
      if (textElement) {
        textElement.textContent = 'Copy page';
      }
    }, 2000);
  }
}

function initializeCopyPage() {
  new CopyPageManager();
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeCopyPage);
} else {
  initializeCopyPage();
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { CopyPageManager };
}
