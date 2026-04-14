const CACHE_NAME = 'abz-tech-v1';
const urlsToCache = [
  './',
  'index.html',
  'style.css',
  'images/icon-192.png' // Assure-toi que celui-là existe bien !
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      console.log('Installation : Mise en cache individuelle...');
      return Promise.all(
        urlsToCache.map(url => {
          return cache.add(url).catch(err => {
            console.warn(`⚠️ Fichier ignoré (introuvable) : ${url}`);
          });
        })
      );
    })
  );
});