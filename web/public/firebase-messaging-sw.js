/// <reference lib="webworker" />

/**
 * Firebase Messaging Service Worker
 * Handles background push notifications for Moment app.
 *
 * Scoped to /firebase-cloud-messaging-push-scope to avoid conflict
 * with the main PWA sw.js at root scope.
 *
 * Firebase config is injected via postMessage from fcm.ts and persisted
 * in Cache Storage so SW updates don't lose the config (R37-003).
 */

importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js",
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js"
);

const CONFIG_CACHE = "fcm-config-v1";
const CONFIG_KEY = "/fcm-config.json";
let firebaseInitialized = false;

async function persistConfig(config) {
  const cache = await caches.open(CONFIG_CACHE);
  await cache.put(CONFIG_KEY, new Response(JSON.stringify(config)));
}

async function loadPersistedConfig() {
  const cache = await caches.open(CONFIG_CACHE);
  const resp = await cache.match(CONFIG_KEY);
  if (!resp) return null;
  try { return await resp.json(); } catch { return null; }
}

function initFirebase(config) {
  if (firebaseInitialized || !config?.apiKey) return;
  firebase.initializeApp(config);
  firebaseInitialized = true;
  setupMessaging();
}

// On activation, try to restore config from cache (handles SW updates)
self.addEventListener("activate", (event) => {
  event.waitUntil(
    loadPersistedConfig().then((config) => {
      if (config) initFirebase(config);
    })
  );
});

// Receive Firebase config from the main app via postMessage
self.addEventListener("message", (event) => {
  if (event.data?.type === "FIREBASE_CONFIG") {
    const config = event.data.config;
    if (config?.apiKey) {
      persistConfig(config);
      initFirebase(config);
    }
  }
});

function setupMessaging() {
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const title = payload.notification?.title ?? "모먼트 알림";
    const body = payload.notification?.body ?? "";
    const link = payload.fcmOptions?.link ?? "/";

    self.registration.showNotification(title, {
      body,
      icon: "/icons/icon-192.svg",
      badge: "/icons/icon-192.svg",
      data: { url: link },
      tag: "moment-reminder",
    });
  });
}

// Handle notification click — navigate to the event page (R37-004: validate URL)
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const rawUrl = event.notification.data?.url ?? "/";

  // Only allow same-origin navigation to prevent open redirect
  let targetPath;
  try {
    const parsed = new URL(rawUrl, self.location.origin);
    if (parsed.origin !== self.location.origin) {
      targetPath = "/";
    } else {
      targetPath = parsed.pathname + parsed.search + parsed.hash;
    }
  } catch {
    targetPath = "/";
  }

  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        // Match by pathname instead of substring includes
        for (const client of clientList) {
          const clientUrl = new URL(client.url);
          if (clientUrl.pathname === targetPath && "focus" in client) {
            return client.focus();
          }
        }
        return self.clients.openWindow(targetUrl);
      })
  );
});
