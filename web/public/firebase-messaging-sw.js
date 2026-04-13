/// <reference lib="webworker" />

/**
 * Firebase Messaging Service Worker
 * Handles background push notifications for Moment app.
 *
 * This is a separate SW from the main PWA sw.js because Firebase
 * messaging requires its own service worker registration.
 */

importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js",
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js"
);

// Firebase config is injected at build time via env vars.
// For the SW, we read from a fetch to /api/firebase-config or use defaults.
// In production, replace these with actual values during deployment.
firebase.initializeApp({
  apiKey: self.__FIREBASE_CONFIG__?.apiKey ?? "",
  projectId: self.__FIREBASE_CONFIG__?.projectId ?? "",
  messagingSenderId: self.__FIREBASE_CONFIG__?.messagingSenderId ?? "",
  appId: self.__FIREBASE_CONFIG__?.appId ?? "",
});

const messaging = firebase.messaging();

// Background message handler
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

// Handle notification click — navigate to the event page
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const url = event.notification.data?.url ?? "/";
  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        // Focus existing tab if open
        for (const client of clientList) {
          if (client.url.includes(url) && "focus" in client) {
            return client.focus();
          }
        }
        // Otherwise open new tab
        return self.clients.openWindow(url);
      })
  );
});
