"use client";

export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-4">
      <h1 className="text-4xl font-bold text-muted-foreground">오류 발생</h1>
      <p className="mt-4 text-muted-foreground">
        문제가 발생했습니다. 다시 시도해주세요.
      </p>
      <button
        onClick={reset}
        className="mt-6 rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
      >
        다시 시도
      </button>
    </div>
  );
}
