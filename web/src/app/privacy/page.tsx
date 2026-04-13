import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "개인정보처리방침 — 모먼트",
};

export default function PrivacyPage() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold">개인정보처리방침</h1>

      <div className="prose prose-sm prose-gray max-w-none space-y-6 text-sm leading-relaxed text-gray-700">
        <section>
          <h2 className="text-base font-semibold text-gray-900">1. 수집하는 개인정보 항목</h2>
          <p>서비스는 회원가입 및 서비스 이용을 위해 아래 개인정보를 수집합니다:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li><strong>카카오 로그인:</strong> 닉네임, 프로필 사진, 이메일(선택)</li>
            <li><strong>Apple 로그인:</strong> 이름, 이메일</li>
            <li><strong>서비스 이용 중 생성:</strong> 이벤트 정보, RSVP 응답, 업로드 사진</li>
          </ul>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">2. 개인정보의 수집 및 이용 목적</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>회원 식별 및 인증</li>
            <li>이벤트 생성, 참석 관리, 알림 발송</li>
            <li>서비스 개선 및 통계 분석</li>
          </ul>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">3. 개인정보의 보유 및 이용기간</h2>
          <p>
            회원 탈퇴 시 지체 없이 파기합니다. 다만 관계 법령에 의한 보존 의무가 있는 경우
            해당 기간 동안 보관합니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">4. 개인정보의 제3자 제공</h2>
          <p>
            서비스는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만 이용자가
            사전에 동의한 경우 또는 법령에 의해 요구되는 경우에는 예외로 합니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">5. 개인정보의 파기절차 및 방법</h2>
          <p>
            전자적 파일 형태로 저장된 개인정보는 복구할 수 없는 기술적 방법을 사용하여
            삭제합니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">6. 이용자의 권리</h2>
          <p>
            이용자는 언제든지 자신의 개인정보를 조회하거나 수정할 수 있으며, 회원 탈퇴를 통해
            개인정보의 처리 정지를 요청할 수 있습니다.
          </p>
        </section>

        <section>
          <h2 className="text-base font-semibold text-gray-900">7. 개인정보 보호책임자</h2>
          <p>
            개인정보 처리에 관한 업무를 총괄해서 책임지고, 관련 불만처리 및 피해구제를
            위해 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.
          </p>
          <p>문의: support@moment.app</p>
        </section>

        <p className="pt-4 text-xs text-gray-400">시행일: 2026년 4월 1일</p>
      </div>
    </main>
  );
}
