class CopyPageManager {
  constructor() {
    this.buttons = document.querySelectorAll('[data-copy-page]');
    this.markdownElement = document.getElementById('page-markdown');

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
    const iconElement = button.querySelector('i[class*="ph-"]');
    const textElement = button.querySelector('.page-actions__copy-text');
    const originalClasses = iconElement?.className;

    button.classList.add('is-copied');

    if (iconElement) {
      iconElement.className = 'ph ph-check';
      iconElement.classList.add('icon-animate-in');
    }
    if (textElement) {
      textElement.textContent = 'Copied';
    }

    setTimeout(() => {
      button.classList.remove('is-copied');
      if (iconElement && originalClasses) {
        iconElement.classList.add('icon-animate-out');
        setTimeout(() => {
          iconElement.className = originalClasses;
        }, 150);
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
