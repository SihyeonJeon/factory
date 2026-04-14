export default function ProfileLoading() {
  return (
    <div className="flex min-h-dvh flex-col pb-20">
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-center px-4">
          <span className="text-sm font-medium">프로필</span>
        </div>
      </header>
      <main className="mx-auto w-full max-w-lg flex-1 px-4 py-6">
        <div className="space-y-6 animate-pulse">
          {/* Avatar skeleton */}
          <div className="flex flex-col items-center gap-4 py-4">
            <div className="h-20 w-20 rounded-full bg-gray-200" />
            <div className="h-6 w-32 rounded bg-gray-200" />
          </div>
          {/* Stats skeleton */}
          <div className="grid grid-cols-2 gap-3">
            <div className="h-20 rounded-2xl bg-gray-100" />
            <div className="h-20 rounded-2xl bg-gray-100" />
          </div>
          {/* Info skeleton */}
          <div className="space-y-3">
            <div className="h-4 w-16 rounded bg-gray-200" />
            <div className="h-32 rounded-2xl bg-gray-100" />
          </div>
        </div>
      </main>
    </div>
  );
}
