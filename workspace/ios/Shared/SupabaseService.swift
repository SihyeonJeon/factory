import Foundation
import Supabase

/// Unfading의 Supabase 클라이언트 단일 진입점. Info.plist의 SupabaseURL/SupabasePublishableKey를 로드해
/// 앱 수명 동안 하나의 `SupabaseClient` 인스턴스를 재사용한다. Auth 세션은 SDK 내부 Keychain 저장소로
/// 자동 지속된다 (supabase-swift 2.x 기본 동작).
///
/// vibe-limit-checked: 4 단일 책임 (클라이언트 로드), 6 강타입 config 실패 시 fatalError (개발-타임 감지),
/// 11 Info.plist 키 네이밍을 상수로 고정하여 호출부 오타 방지.
struct SupabaseConfig {
    let url: URL
    let publishableKey: String

    static func fromBundle(_ bundle: Bundle = .main) -> SupabaseConfig {
        guard
            let urlString = bundle.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: urlString),
            let key = bundle.object(forInfoDictionaryKey: "SupabasePublishableKey") as? String,
            !key.isEmpty
        else {
            fatalError("SupabaseURL / SupabasePublishableKey missing in Info.plist")
        }
        return SupabaseConfig(url: url, publishableKey: key)
    }
}

final class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient
    let url: URL
    let publishableKey: String

    private init(config: SupabaseConfig = .fromBundle()) {
        self.client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.publishableKey)
        self.url = config.url
        self.publishableKey = config.publishableKey
    }

    var auth: AuthClient { client.auth }
    var database: PostgrestClient { client.schema("public") }
    var storage: SupabaseStorageClient { client.storage }
    var realtime: RealtimeClientV2 { client.realtimeV2 }
}
