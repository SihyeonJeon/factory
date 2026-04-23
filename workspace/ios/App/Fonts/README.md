# Bundled Fonts (R26)

이 디렉터리의 폰트는 앱 번들에 임베드되어 `UnfadingTheme.Font` 가 `.custom(...)` 으로 참조합니다. **시스템 폰트 폴백 금지** — Sprint 8-B 톤이 완전히 달라집니다.

## Files

| File | PostScript name | Weight | Source |
|---|---|---|---|
| `GowunDodum-Regular.ttf` | `GowunDodum-Regular` | Regular (400) | google/fonts OFL (`ofl/gowundodum/`) — 원본 그대로 |
| `Nunito-Regular.ttf` | `Nunito-Regular` | Regular (400) | googlefonts/nunito variable (`Nunito[wght].ttf`) 에서 `fontTools.varLib.instancer` 로 정적 인스턴스 생성 |
| `Nunito-SemiBold.ttf` | `Nunito-SemiBold` | SemiBold (600) | 동일 |
| `Nunito-Bold.ttf` | `Nunito-Bold` | Bold (700) | 동일 |
| `Nunito-Black.ttf` | `Nunito-Black` | Black (900) | 동일 |

## Licenses

- `GowunDodum-OFL.txt` — SIL Open Font License 1.1, Gowun Dodum Project Authors
- `Nunito-OFL.txt` — SIL Open Font License 1.1, Vernon Adams, Cyreal, Jacques Le Bailly

원본 저장소:
- https://github.com/google/fonts/tree/main/ofl/gowundodum
- https://github.com/googlefonts/nunito

## Regeneration

정적 인스턴스는 다음 스크립트로 재생성 가능:

```bash
pip3 install fonttools
cd workspace/ios/App/Fonts
curl -sSL -o Nunito-VF.ttf "https://cdn.jsdelivr.net/gh/googlefonts/nunito@main/fonts/variable/Nunito%5Bwght%5D.ttf"
python3 - <<'PY'
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
for weight, style in [(400,'Regular'),(600,'SemiBold'),(700,'Bold'),(900,'Black')]:
    tt = TTFont('Nunito-VF.ttf')
    tt = instantiateVariableFont(tt, {'wght': weight})
    ps = f'Nunito-{style}'
    for r in tt['name'].names:
        if r.nameID == 1: r.string = 'Nunito'.encode(r.getEncoding())
        elif r.nameID == 2: r.string = style.encode(r.getEncoding())
        elif r.nameID == 4: r.string = f'Nunito {style}'.encode(r.getEncoding())
        elif r.nameID == 6: r.string = ps.encode(r.getEncoding())
        elif r.nameID == 16: r.string = 'Nunito'.encode(r.getEncoding())
        elif r.nameID == 17: r.string = style.encode(r.getEncoding())
    tt.save(f'Nunito-{style}.ttf')
PY
rm Nunito-VF.ttf
```

## Integration

- `project.yml` → `targets.MemoryMap.resources` 에 `App/Fonts` 디렉터리 추가.
- `App/Info.plist` (또는 project.yml `info.properties`) 의 `UIAppFonts` 배열에 각 `.ttf` 파일명 등록.
- `UnfadingTheme.Font.*` 가 전부 위 PostScript name 중 하나를 `.custom(_:size:)` 으로 참조.
- `UnfadingFontLoadingTests` 가 `UIFont(name: "GowunDodum-Regular", size: 14)` 및 Nunito 4 weight 모두 nil 아님을 assert.
