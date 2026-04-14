/// <reference lib="webworker" />

const CACHE_NAME = "moment-v1";
const STATIC_ASSETS = [
  "/manifest.json",
  "/icons/icon-192.svg",
  "/icons/icon-512.svg",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/offline.html",
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
  // Falls back to offline page if the network request fails
  if (
    url.pathname.startsWith("/dashboard") ||
    url.pathname.startsWith("/create") ||
    url.pathname.startsWith("/login") ||
    url.pathname.startsWith("/auth")
  ) {
    if (request.mode === "navigate") {
      event.respondWith(
        fetch(request).catch(() => caches.match("/offline.html"))
      );
    }
    return;
  }

  // Stale-while-revalidate for public HTML pages (event pages, home, etc.)
  event.respondWith(
    caches.match(request).then((cached) => {
      const fetchPromise = fetch(request)
        .then((response) => {
          // Only cache successful same-origin responses (R37-002)
          if (response.ok && response.type === "basic") {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          }
          return response;
        })
        .catch(() => {
          // Network failed — return cached version or offline fallback (R37-001)
          if (cached) return cached;
          if (request.mode === "navigate") {
            return caches.match("/offline.html");
          }
          return undefined;
        });

      return cached || fetchPromise;
    })
  );
});
