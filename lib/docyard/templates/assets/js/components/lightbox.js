(function() {
  'use strict';

  let lightbox = null;
  let lightboxImg = null;

  function createLightbox() {
    if (lightbox) return;

    lightbox = document.createElement('div');
    lightbox.className = 'docyard-lightbox';
    lightbox.innerHTML = `
      <button class="docyard-lightbox-close" aria-label="Close">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" fill="currentColor">
          <path d="M205.66,194.34a8,8,0,0,1-11.32,11.32L128,139.31,61.66,205.66a8,8,0,0,1-11.32-11.32L116.69,128,50.34,61.66A8,8,0,0,1,61.66,50.34L128,116.69l66.34-66.35a8,8,0,0,1,11.32,11.32L139.31,128Z"/>
        </svg>
      </button>
      <img src="" alt="">
    `;

    document.body.appendChild(lightbox);
    lightboxImg = lightbox.querySelector('img');

    lightbox.addEventListener('click', closeLightbox);
    lightbox.querySelector('.docyard-lightbox-close').addEventListener('click', closeLightbox);

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && lightbox.classList.contains('active')) {
        closeLightbox();
      }
    });
  }

  function openLightbox(src, alt) {
    createLightbox();
    lightboxImg.src = src;
    lightboxImg.alt = alt || '';
    requestAnimationFrame(function() {
      lightbox.classList.add('active');
      document.body.style.overflow = 'hidden';
    });
  }

  function closeLightbox(e) {
    if (e && e.target === lightboxImg) return;
    if (lightbox) {
      lightbox.classList.remove('active');
      document.body.style.overflow = '';
    }
  }

  function initLightbox(root) {
    var container = root || document;
    var contentImages = container.querySelectorAll('.content img');

    contentImages.forEach(function(img) {
      if (img.hasAttribute('data-no-zoom')) {
        img.style.cursor = 'default';
        return;
      }

      if (img.hasAttribute('data-lightbox-initialized')) return;
      img.setAttribute('data-lightbox-initialized', 'true');

      img.addEventListener('click', function() {
        openLightbox(this.src, this.alt);
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { initLightbox(); });
  } else {
    initLightbox();
  }

  window.docyard = window.docyard || {};
  window.docyard.initLightbox = initLightbox;
})();
