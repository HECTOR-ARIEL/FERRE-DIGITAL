// Primero intenta la red (así siempre ves lo último) y guarda una copia
// de las páginas para poder abrir la app sin conexión.
const CACHE = 'v3';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(
  caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => clients.claim())));
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET' || new URL(r.url).origin !== location.origin) return;
  // cache:'no-cache' pregunta siempre al servidor si hay versión nueva
  e.respondWith(fetch(r, { cache: 'no-cache' }).then(res => {
    if (res.ok) { const c = res.clone(); caches.open(CACHE).then(x => x.put(r, c)); }
    return res;
  }).catch(() => caches.match(r)));
});
