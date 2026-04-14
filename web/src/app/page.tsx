import Link from "next/link";

export default function Home() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-4 md:px-8">
      <div className="w-full max-w-md space-y-6 text-center md:max-w-lg xl:max-w-xl">
        <h1 className="text-4xl font-bold tracking-tight md:text-5xl xl:text-6xl">
          모먼트
        </h1>
        <p className="text-lg text-muted-foreground leading-relaxed md:text-xl">
          60초 만에 감성 이벤트 페이지를 만들고
          <br />
          카카오톡으로 공유하세요.
        </p>
        <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
          <Link
            href="/create"
            className="inline-flex h-12 items-center justify-center rounded-xl bg-primary px-8 text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90 md:h-14 md:px-10 md:text-lg"
          >
            이벤트 만들기
          </Link>
          <Link
            href="/my"
            className="inline-flex h-12 items-center justify-center rounded-xl border border-gray-200 px-8 text-base font-semibold text-gray-700 transition-colors hover:bg-gray-50 md:h-14 md:px-10 md:text-lg"
          >
            내 이벤트
          </Link>
        </div>
      </div>
    </div>
  );
}
