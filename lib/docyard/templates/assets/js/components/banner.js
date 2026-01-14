(function () {
  var STORAGE_KEY = 'docyard-announcement-dismissed';

  function initAnnouncement() {
    var banner = document.querySelector('.docyard-announcement');
    if (!banner) return;

    var isDismissible = banner.dataset.dismissible === 'true';

    if (isDismissible && isDismissed()) {
      banner.style.display = 'none';
      document.body.classList.remove('has-announcement');
      return;
    }

    if (isDismissible) {
      var dismissButton = banner.querySelector('.docyard-announcement__dismiss');
      if (dismissButton) {
        dismissButton.addEventListener('click', function () {
          dismissAnnouncement(banner);
        });
      }
    }

    var actionLink = banner.querySelector('.docyard-announcement__link');
    var actionButton = banner.querySelector('.docyard-announcement__button');

    if (actionLink) {
      actionLink.addEventListener('click', function () {
        saveDismissed();
      });
    }

    if (actionButton) {
      actionButton.addEventListener('click', function () {
        saveDismissed();
      });
    }
  }

  function saveDismissed() {
    try {
      localStorage.setItem(STORAGE_KEY, Date.now().toString());
    } catch (e) {
    }
  }

  function isDismissed() {
    try {
      var dismissed = localStorage.getItem(STORAGE_KEY);
      if (!dismissed) return false;

      var dismissedAt = parseInt(dismissed, 10);
      var sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);

      return dismissedAt > sevenDaysAgo;
    } catch (e) {
      return false;
    }
  }

  function dismissAnnouncement(banner) {
    banner.classList.add('is-dismissed');

    try {
      localStorage.setItem(STORAGE_KEY, Date.now().toString());
    } catch (e) {
    }

    banner.addEventListener('animationend', function () {
      banner.style.display = 'none';
      document.body.classList.remove('has-announcement');
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAnnouncement);
  } else {
    initAnnouncement();
  }
})();
