import Foundation

// Compile the production state/service without linking Firebase or SwiftUI navigation.
enum ReportRoute: Hashable { case expense(Int) }
struct SelectedNightDay { let id: Date }
final class AuthService {
    static let shared = AuthService()
    func accessToken() async throws -> String { "test-token" }
}
