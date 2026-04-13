"use client";

import { useServiceWorker } from "@/hooks/use-service-worker";
import { InstallPrompt } from "./install-prompt";

export function PwaProvider() {
  useServiceWorker();
  return <InstallPrompt />;
}
