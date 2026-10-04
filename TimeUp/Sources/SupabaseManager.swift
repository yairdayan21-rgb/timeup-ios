import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {

        let supabaseURL = URL(
            string: "https://fnwncwzexqfajcmchpsd.supabase.co"
        )!

        let supabasePublishableKey =
            "sb_publishable_fBKgyN0MSFzao29xidBUPQ_bvUke2E_"

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabasePublishableKey
        )
    }
}
