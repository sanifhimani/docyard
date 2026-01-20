class FeedbackManager {
  constructor() {
    this.container = document.querySelector('.feedback');
    if (!this.container) return;

    this.buttons = this.container.querySelectorAll('.feedback__btn');
    this.thanks = this.container.querySelector('.feedback__thanks');
    this.pagePath = window.location.pathname;

    this.init();
  }

  init() {
    this.buttons.forEach(button => {
      button.addEventListener('click', (e) => this.handleFeedback(e));
    });
  }

  handleFeedback(event) {
    const button = event.currentTarget;
    const value = button.dataset.feedback;
    const isHelpful = value === 'yes';

    this.updateUI(button);
    this.sendAnalytics(isHelpful);
  }

  updateUI(selectedButton) {
    this.buttons.forEach(button => {
      if (button === selectedButton) {
        button.classList.add('is-selected');
      } else {
        button.classList.add('is-not-selected');
      }
    });

    setTimeout(() => {
      this.container.classList.add('is-submitted');
      this.thanks.hidden = false;
    }, 600);
  }

  sendAnalytics(isHelpful) {
    const helpful = isHelpful ? 'yes' : 'no';

    if (typeof gtag === 'function') {
      gtag('event', 'page_feedback', {
        feedback_page: this.pagePath,
        helpful: helpful,
        value: isHelpful ? 1 : 0
      });
    }

    if (typeof plausible === 'function') {
      plausible('Feedback', { props: { helpful: helpful, page: this.pagePath } });
    }

    if (typeof fathom === 'object' && typeof fathom.trackEvent === 'function') {
      fathom.trackEvent(`feedback_${helpful}`);
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new FeedbackManager();
});
