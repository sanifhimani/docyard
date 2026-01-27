function initializeRelativeTime() {
  const elements = document.querySelectorAll('.page-actions__last-updated time[datetime]');
  if (elements.length === 0) return;

  const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });
  elements.forEach(el => updateRelativeTime(el, rtf));
}

function updateRelativeTime(element, rtf) {
  const datetime = element.getAttribute('datetime');
  if (!datetime) return;

  const date = new Date(datetime);
  if (isNaN(date.getTime())) return;

  const seconds = (date.getTime() - Date.now()) / 1000;
  const absSeconds = Math.abs(seconds);

  const units = [
    [31536000, 'year'],
    [2592000, 'month'],
    [604800, 'week'],
    [86400, 'day'],
    [3600, 'hour'],
    [60, 'minute']
  ];

  for (const [threshold, unit] of units) {
    if (absSeconds >= threshold) {
      element.textContent = rtf.format(Math.round(seconds / threshold), unit);
      return;
    }
  }

  element.textContent = rtf.format(Math.round(seconds), 'second');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeRelativeTime);
} else {
  initializeRelativeTime();
}
