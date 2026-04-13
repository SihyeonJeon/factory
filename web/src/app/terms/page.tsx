import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "서비스 이용약관 — 모먼트",
};

export default function TermsPage() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold">서비스 이용약관</h1>

      <div className="prose prose-sm prose-gray max-w-none space-y-6 text-sm leading-relaxed text-gray-700">
        <section>
          <h2 className="text-base font-semibold text-gray-900">제1조 (목적)</h2>
          <p>
            본 약관은 모먼트(이하 &quot;서비스&quot;)가 제공하는 프라이빗 모임 운영 플랫폼 서비스의
            이용조건 및 절차, 회사와 이용자의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">제2조 (서비스의 내용)</h2>
          <p>서비스는 다음의 기능을 제공합니다:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>이벤트(모임) 페이지 생성 및 관리</li>
            <li>참석 여부 응답(RSVP) 수집</li>
            <li>사진 타임라인 공유</li>
            <li>정산 기능</li>
            <li>D-1 리마인더 알림</li>
          </ul>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">제3조 (이용자의 의무)</h2>
          <p>
            이용자는 서비스 이용 시 타인의 개인정보를 무단으로 수집하거나, 서비스를 부정한
            목적으로 이용해서는 안 됩니다. 이용자는 관계 법령, 본 약관의 규정, 이용안내 및
            서비스와 관련하여 공지한 주의사항을 준수하여야 합니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">제4조 (서비스의 중단)</h2>
          <p>
            회사는 시스템 점검, 교체 및 고장, 통신 두절 등의 사유가 발생한 경우에는 서비스의
            제공을 일시적으로 중단할 수 있습니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">제5조 (면책조항)</h2>
          <p>
            회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는
            서비스 제공에 관한 책임이 면제됩니다. 이용자의 귀책사유로 인한 서비스 이용의 장애에
            대하여 책임을 지지 않습니다.
          </p>
        </section>

        <p className="pt-4 text-xs text-gray-400">시행일: 2026년 4월 1일</p>
      </div>
    </main>
  );
}
