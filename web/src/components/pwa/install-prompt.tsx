"use client";

import { useInstallPrompt } from "@/hooks/use-install-prompt";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";

export function InstallPrompt() {
  const { canInstall, install, dismiss } = useInstallPrompt();

  if (!canInstall) return null;

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 mx-auto max-w-md animate-in slide-in-from-bottom-4 fade-in duration-300">
      <div className="flex items-center gap-3 rounded-2xl bg-card border border-border p-4 shadow-lg">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10">
          <span className="text-lg" role="img" aria-label="모먼트">
            M
          </span>
        </div>

        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-foreground">
            모먼트 앱 설치
          </p>
          <p className="text-xs text-muted-foreground">
            홈 화면에 추가하면 더 빠르게 접근할 수 있어요
          </p>
        </div>

        <div className="flex shrink-0 items-center gap-1">
          <Button size="sm" onClick={install} className="h-8 rounded-xl px-3 text-xs">
            설치
          </Button>
          <button
            onClick={dismiss}
            className="flex h-8 w-8 items-center justify-center rounded-full text-muted-foreground hover:bg-muted transition-colors"
            aria-label="닫기"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
