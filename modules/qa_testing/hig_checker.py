#!/usr/bin/env python3
"""
hig_checker.py — Apple Human Interface Guidelines 자동 검증기

소스 코드를 정적 분석하여 HIG 위반 사항을 감지한다.
Playwright 기반 시각적 QA와 별도로, 코드 레벨에서 먼저 걸러낸다.
"""

import re
from pathlib import Path
from dataclasses import dataclass


@dataclass
class HIGViolation:
    file: str
    line: int
    rule: str
    severity: str  # "critical" | "warning"
    detail: str


def check_hig(workspace: Path) -> list[HIGViolation]:
    """workspace 내 모든 TSX/TS 파일을 스캔하여 HIG 위반 목록 반환."""
    violations = []

    tsx_files = list(workspace.rglob("*.tsx")) + list(workspace.rglob("*.ts"))
    # node_modules 제외
    tsx_files = [f for f in tsx_files if "node_modules" not in str(f)]

    for filepath in tsx_files:
        try:
            content = filepath.read_text(encoding="utf-8")
            lines = content.split("\n")
        except Exception:
            continue

        rel_path = str(filepath.relative_to(workspace))

        for i, line in enumerate(lines, 1):
            # Rule 1: TouchableOpacity/Pressable에 최소 터치 타겟 확인
            if re.search(r"<(TouchableOpacity|Pressable)", line):
                # 해당 컴포넌트 블록 내에서 min-w-[44] 또는 minWidth: 44 확인
                block = "\n".join(lines[max(0, i-1):min(len(lines), i+10)])
                has_min_touch = (
                    "min-w-[44" in block or
                    "min-h-[44" in block or
                    "minWidth" in block or
                    "minTouchTarget" in block or
                    "hitSlop" in block or
                    "p-3" in block or  # p-3 = 12px padding, likely enough
                    "p-4" in block or
                    "w-12" in block or  # w-12 = 48px
                    "h-12" in block or
                    "w-11" in block or  # w-11 = 44px
                    "h-11" in block
                )
                if not has_min_touch:
                    violations.append(HIGViolation(
                        file=rel_path, line=i,
                        rule="HIG-TOUCH-TARGET",
                        severity="critical",
                        detail="TouchableOpacity/Pressable에 44pt 최소 터치 영역 미확보. "
                               "className에 min-w-[44px] min-h-[44px] 또는 hitSlop 추가 필요.",
                    ))

            # Rule 2: 스크린 파일에 SafeAreaView 확인
            if filepath.parent.name == "app" or "screen" in rel_path.lower():
                if i == 1:  # 파일당 1번만 체크
                    has_safe_area = (
                        "SafeAreaView" in content or
                        "SafeAreaProvider" in content or
                        "useSafeAreaInsets" in content
                    )
                    if not has_safe_area:
                        violations.append(HIGViolation(
                            file=rel_path, line=1,
                            rule="HIG-SAFE-AREA",
                            severity="critical",
                            detail="스크린 파일에 SafeAreaView/useSafeAreaInsets 미사용. "
                                   "노치/Dynamic Island 침범 위험.",
                        ))

            # Rule 3: 하드코딩된 색상 감지 (매직 넘버)
            hex_match = re.search(r'["\']#[0-9a-fA-F]{3,8}["\']', line)
            if hex_match:
                # theme.ts 자체는 허용
                if "theme" not in rel_path.lower() and "tailwind" not in rel_path.lower():
                    violations.append(HIGViolation(
                        file=rel_path, line=i,
                        rule="VIBE-MAGIC-COLOR",
                        severity="warning",
                        detail=f"하드코딩된 색상 {hex_match.group()} 감지. "
                               "theme.ts 토큰 사용 권장.",
                    ))

            # Rule 4: StyleSheet.create 사용 감지 (NativeWind 위반)
            if "StyleSheet.create" in line:
                violations.append(HIGViolation(
                    file=rel_path, line=i,
                    rule="VIBE-NATIVEWIND",
                    severity="warning",
                    detail="StyleSheet.create 사용. NativeWind className으로 마이그레이션 권장.",
                ))

            # Rule 5: useState 남용 감지 (store 파일이 아닌 곳)
            if "useState" in line and "store" not in rel_path.lower():
                # import문은 건너뛰기
                if "import" not in line:
                    violations.append(HIGViolation(
                        file=rel_path, line=i,
                        rule="VIBE-STATE-MGMT",
                        severity="warning",
                        detail="컴포넌트에서 useState 직접 사용. "
                               "Zustand store 사용이 권장됨 (완전 로컬 상태인 경우에만 허용).",
                    ))

            # Rule 6: 다크 모드 미지원 감지
            if i == 1 and filepath.suffix == ".tsx":
                if ("screen" in rel_path.lower() or filepath.parent.name == "app"):
                    has_dark_mode = (
                        "useColorScheme" in content or
                        "dark:" in content or
                        "colorScheme" in content
                    )
                    if not has_dark_mode:
                        violations.append(HIGViolation(
                            file=rel_path, line=1,
                            rule="HIG-DARK-MODE",
                            severity="warning",
                            detail="스크린에서 다크 모드 미지원. "
                                   "useColorScheme() 또는 NativeWind dark: 프리픽스 사용 필요.",
                        ))

    return violations


def format_report(violations: list[HIGViolation]) -> str:
    """위반 목록을 마크다운 보고서로 포맷."""
    if not violations:
        return "# HIG Check Report\n\nNo violations found. HIG_PASS\n"

    critical = [v for v in violations if v.severity == "critical"]
    warnings = [v for v in violations if v.severity == "warning"]

    lines = ["# HIG Check Report\n"]

    if critical:
        lines.append(f"## Critical Violations ({len(critical)})\n")
        for v in critical:
            lines.append(f"- **{v.rule}** `{v.file}:{v.line}` — {v.detail}")
        lines.append("")

    if warnings:
        lines.append(f"## Warnings ({len(warnings)})\n")
        for v in warnings:
            lines.append(f"- **{v.rule}** `{v.file}:{v.line}` — {v.detail}")
        lines.append("")

    if critical:
        lines.append(f"\n**Verdict: HIG_FAIL** ({len(critical)} critical violations)")
    else:
        lines.append(f"\n**Verdict: HIG_PASS** ({len(warnings)} warnings)")

    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    workspace = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent.parent.parent / "workspace"
    violations = check_hig(workspace)
    report = format_report(violations)
    print(report)

    # 종료 코드: critical이 있으면 1
    sys.exit(1 if any(v.severity == "critical" for v in violations) else 0)
