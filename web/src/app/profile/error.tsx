"use client";

interface ErrorProps {
  error: Error;
  reset: () => void;
}

export default function ProfileError({ error, reset }: ErrorProps) {
  return (
    <div className="flex min-h-dvh flex-col pb-20">
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-center px-4">
          <span className="text-sm font-medium">프로필</span>
        </div>
      </header>
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col items-center justify-center px-4 py-6 text-center">
        <p className="mb-4 text-sm text-gray-500">
          프로필을 불러오는 중 오류가 발생했습니다
        </p>
        <button
          onClick={reset}
          className="rounded-xl bg-gray-900 px-6 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-gray-800"
        >
          다시 시도
        </button>
      </main>
    </div>
  );
}
