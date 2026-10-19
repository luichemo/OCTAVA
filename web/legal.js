// Shared by the privacy policy and terms (web/privacy, web/terms).

// The address people write to about privacy, their account or these terms.
// Set it once here; every page shows it. Empty shows a placeholder.
const CONTACT_EMAIL = '';

(function () {
  const root = document.documentElement;
  let lang = '';
  try { lang = localStorage.getItem('octava-get-lang') || ''; } catch (e) { lang = ''; }
  if (lang !== 'en' && lang !== 'ka') {
    lang = (navigator.languages || [navigator.language || 'en']).some((l) => /^ka/i.test(l)) ? 'ka' : 'en';
  }
  function apply() {
    root.dataset.lang = lang;
    root.lang = lang;
    const toggle = document.getElementById('lang');
    if (toggle) toggle.textContent = lang === 'en' ? 'ქართული' : 'English';
    document.querySelectorAll('.contact').forEach((el) => {
      if (CONTACT_EMAIL) {
        const a = document.createElement('a');
        a.href = 'mailto:' + CONTACT_EMAIL;
        a.textContent = CONTACT_EMAIL;
        el.replaceChildren(a);
      } else {
        el.textContent = lang === 'ka'
          ? '[საკონტაქტო ელფოსტა მალე დაემატება]'
          : '[contact email coming soon]';
      }
    });
  }
  apply();
  document.getElementById('lang').addEventListener('click', () => {
    lang = lang === 'en' ? 'ka' : 'en';
    try { localStorage.setItem('octava-get-lang', lang); } catch (e) {}
    apply();
  });
})();
