
  // Profile dropdown toggle
  (function(){
    const btn = document.getElementById('profileBtn');
    const menu = document.getElementById('profileMenu');
    if (btn && menu) {
      btn.addEventListener('click', () => {
        const open = menu.classList.toggle('show');
        btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      });
      document.addEventListener('click', (e) => {
        if (!menu.contains(e.target) && !btn.contains(e.target)) menu.classList.remove('show');
      });
    }
  })();

  // Carousel arrows with wrap-around
  (function(){
    const track = document.getElementById('carTrack');
    const prev  = document.getElementById('carPrev');
    const next  = document.getElementById('carNext');
    if (!track || !prev || !next) return;

    const slideWidth = () => track.getBoundingClientRect().width;
    const slides     = () => Array.from(track.children);
    const maxIndex   = () => Math.max(0, slides().length - 1);

    const currentIndex = () => {
      const w = slideWidth();
      return w ? Math.round(track.scrollLeft / w) : 0;
    };

    const goToIndex = (i) => {
      const w = slideWidth();
      track.scrollTo({ left: i * w, behavior: 'smooth' });
    };

    prev.addEventListener('click', () => {
      const i = currentIndex();
      if (i <= 0) {
        goToIndex(maxIndex()); // wrap to last
      } else {
        goToIndex(i - 1);
      }
    });

    next.addEventListener('click', () => {
      const i = currentIndex();
      if (i >= maxIndex()) {
        goToIndex(0); // wrap to first
      } else {
        goToIndex(i + 1);
      }
    });

    // Optional keyboard nav
    track.setAttribute('tabindex', '0');
    track.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') prev.click();
      if (e.key === 'ArrowRight') next.click();
    });
  })();
