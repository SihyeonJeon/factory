/// <reference lib="webworker" />

const CACHE_NAME = "moment-v1";
const STATIC_ASSETS = [
  "/",
  "/manifest.json",
  "/icons/icon-192.svg",
  "/icons/icon-512.svg",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET and cross-origin requests
  if (request.method !== "GET" || url.origin !== self.location.origin) return;

  // Never cache API routes — they contain auth-dependent and sensitive data
  if (url.pathname.startsWith("/api/")) {
    return;
  }

  // Network-only for Next.js data routes (may contain auth-dependent page data)
  if (url.pathname.startsWith("/_next/data/")) {
    return;
  }

  // Cache-first for static assets (_next/static, icons, covers)
  if (
    url.pathname.startsWith("/_next/static/") ||
    url.pathname.startsWith("/icons/") ||
    url.pathname.startsWith("/covers/")
  ) {
    event.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ||
          fetch(request).then((response) => {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
            return response;
          })
      )
    );
    return;
  }

  // Network-only for protected routes (auth-dependent content)
  if (
    url.pathname.startsWith("/dashboard") ||
    url.pathname.startsWith("/create") ||
    url.pathname.startsWith("/login") ||
    url.pathname.startsWith("/auth")
  ) {
    return;
  }

  // Stale-while-revalidate for public HTML pages (event pages, home, etc.)
  event.respondWith(
    caches.match(request).then((cached) => {
      const fetchPromise = fetch(request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() => cached);

      return cached || fetchPromise;
    })
  );
});
