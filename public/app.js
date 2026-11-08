// Search, filters and sorting run on the server: the form is a plain GET.
// This only adds the `/` search shortcut and applies a filter as soon as it
// is chosen.
document.addEventListener('keydown', event => {
  if (event.key === '/' && !event.ctrlKey && !event.metaKey && !['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName)) {
    const search = document.querySelector('#search');
    if (search) { event.preventDefault(); search.focus(); }
  }
});

const filters = document.querySelector('#filters');
if (filters) {
  for (const select of filters.querySelectorAll('select')) {
    select.addEventListener('change', () => filters.requestSubmit());
  }
}
