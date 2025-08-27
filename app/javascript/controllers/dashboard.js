// Profile dropdown toggle
  (function(){
    const btn  = document.getElementById('fdProfileBtn');
    const menu = document.getElementById('fdProfileMenu');
    if (!btn || !menu) return;

    btn.addEventListener('click', () => {
      const open = menu.classList.toggle('show');
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });

    document.addEventListener('click', (e) => {
      if (!menu.contains(e.target) && !btn.contains(e.target)) menu.classList.remove('show');
    });
  })();

  // Carousel arrows with wrap-around
  (function(){
    const track = document.getElementById('fdCarTrack');
    const prev  = document.getElementById('fdCarPrev');
    const next  = document.getElementById('fdCarNext');
    if (!track || !prev || !next) return;

    const slideWidth   = () => track.getBoundingClientRect().width;
    const slides       = () => Array.from(track.children);
    const maxIndex     = () => Math.max(0, slides().length - 1);
    const currentIndex = () => {
      const w = slideWidth();
      return w ? Math.round(track.scrollLeft / w) : 0;
    };
    const goToIndex    = (i) => track.scrollTo({ left: i * slideWidth(), behavior: 'smooth' });

    prev.addEventListener('click', () => {
      const i = currentIndex();
      goToIndex(i <= 0 ? maxIndex() : i - 1);
    });

    next.addEventListener('click', () => {
      const i = currentIndex();
      goToIndex(i >= maxIndex() ? 0 : i + 1);
    });

    // Optional keyboard nav
    track.setAttribute('tabindex', '0');
    track.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') prev.click();
      if (e.key === 'ArrowRight') next.click();
    });
  })();
