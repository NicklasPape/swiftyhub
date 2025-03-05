import Foundation

public struct Article: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let ai_content: String
    public let image_path: String?
    public let source_url: String
    public let created_at: String
}
