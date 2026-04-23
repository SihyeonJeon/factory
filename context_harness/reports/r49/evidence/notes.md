## Notes

- R49 사진 export 는 true ZIP 대신 폴더 공유(옵션 A)로 구현했다. iOS 기본 SDK 에 안정적인 native ZIP 작성 API 가 없어 SPM 추가 없이 가장 단순하고 유지보수 가능한 경로다.
- 구현은 `DataExporter.exportPhotos` 에서 signed URL 다운로드 후 `FileWrapper(directoryWithFileWrappers:)` 로 임시 폴더를 만들고, `UIActivityViewController` 로 해당 폴더 URL 을 공유한다.
- 향후 ZIP 이 반드시 필요하면 옵션 C 로 `ZIPFoundation` SPM 추가를 검토할 수 있다. 그 경우 현재 다운로드/파일명 정리 단계는 재사용하고, 마지막 패키징 단계만 ZIP writer 로 교체하면 된다.
