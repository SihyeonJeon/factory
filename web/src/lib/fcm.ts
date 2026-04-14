/**
 * Firebase Cloud Messaging client-side integration.
 *
 * Handles:
 * - Firebase app initialization (lazy singleton)
 * - Requesting notification permission
 * - Getting FCM token
 * - Saving token to Supabase fcm_tokens table
 *
 * Required env vars:
 *   NEXT_PUBLIC_FIREBASE_API_KEY
 *   NEXT_PUBLIC_FIREBASE_PROJECT_ID
 *   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
 *   NEXT_PUBLIC_FIREBASE_APP_ID
 */

import { createClient } from "./supabase/client";

interface FirebaseConfig {
  apiKey: string;
  projectId: string;
  messagingSenderId: string;
  appId: string;
}

function getFirebaseConfig(): FirebaseConfig {
  return {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY!,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID!,
  };
}

let firebaseApp: unknown = null;
let messaging: unknown = null;

async function getMessaging() {
  if (typeof window === "undefined") return null;

  if (messaging) return messaging;

  const firebase = await import("firebase/app");
  const fcm = await import("firebase/messaging");

  if (!firebaseApp) {
    firebaseApp = firebase.initializeApp(getFirebaseConfig());
  }

  messaging = fcm.getMessaging(firebaseApp as ReturnType<typeof firebase.initializeApp>);
  return messaging;
}

/**
 * Request notification permission, get FCM token, and save it to Supabase.
 * Returns the token on success, null if permission denied or unavailable.
 */
export async function registerFCMToken(): Promise<string | null> {
  if (typeof window === "undefined") return null;
  if (!("Notification" in window)) return null;

  const permission = await Notification.requestPermission();
  if (permission !== "granted") return null;

  try {
    const fcm = await import("firebase/messaging");
    const msg = await getMessaging();
    if (!msg) return null;

    const vapidKey = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY;

    // Register FCM SW with a dedicated scope to avoid conflict with PWA sw.js
    const swReg = await navigator.serviceWorker.register(
      "/firebase-messaging-sw.js",
      { scope: "/firebase-cloud-messaging-push-scope" },
    );

    // Inject Firebase config into the SW (public/ files can't use process.env)
    const activeWorker = swReg.active ?? swReg.installing ?? swReg.waiting;
    if (activeWorker) {
      activeWorker.postMessage({
        type: "FIREBASE_CONFIG",
        config: getFirebaseConfig(),
      });
    }

    const token = await fcm.getToken(
      msg as ReturnType<typeof fcm.getMessaging>,
      {
        vapidKey,
        serviceWorkerRegistration: swReg,
      },
    );

    if (!token) return null;

    // Save token to Supabase
    await saveFCMToken(token);

    return token;
  } catch (err) {
    console.error("FCM registration failed:", err);
    return null;
  }
}

/**
 * Save FCM token to the current user's profile in Supabase.
 */
async function saveFCMToken(token: string): Promise<void> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return;

  await supabase
    .from("fcm_tokens")
    .upsert({
      user_id: user.id,
      token,
      updated_at: new Date().toISOString(),
    });
}

/**
 * Listen for foreground FCM messages.
 * Returns an unsubscribe function.
 */
export async function onForegroundMessage(
  callback: (payload: { title?: string; body?: string; link?: string }) => void,
): Promise<(() => void) | null> {
  try {
    const fcm = await import("firebase/messaging");
    const msg = await getMessaging();
    if (!msg) return null;

    return fcm.onMessage(
      msg as ReturnType<typeof fcm.getMessaging>,
      (payload) => {
        callback({
          title: payload.notification?.title,
          body: payload.notification?.body,
          link: payload.fcmOptions?.link,
        });
      },
    );
  } catch {
    return null;
  }
}
