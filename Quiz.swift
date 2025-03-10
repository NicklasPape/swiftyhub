import Foundation

struct Quiz: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var heroImagePath: String = ""
    var createdAt: Date = Date()
    var difficulty: String = "Medium"
    
    // These could be expanded upon when you're ready to implement the actual quiz functionality
    var questions: [Question]?
    var no_questions: Int = 0
    
    // CodingKeys enum to handle Supabase's snake_case format
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case heroImagePath = "hero_image_path"
        case createdAt = "created_at"
        case questions
        case difficulty
        case no_questions
    }
    
    init(title: String, description: String, heroImagePath: String = "", difficulty: String = "Medium", no_questions: Int = 0, createdAt: Date = Date(), questions: [Question]? = nil) {
        self.title = title
        self.description = description
        self.heroImagePath = heroImagePath
        self.difficulty = difficulty
        self.no_questions = no_questions
        self.createdAt = createdAt
        self.questions = questions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        // Optional fields with defaults
        heroImagePath = try container.decodeIfPresent(String.self, forKey: .heroImagePath) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "Medium"
        
        // Handle both cases: when questions is a number or an array
        if let questionsArray = try? container.decodeIfPresent([Question].self, forKey: .questions) {
            questions = questionsArray
            no_questions = questionsArray.count
        } else if let questionsCount = try? container.decodeIfPresent(Int.self, forKey: .questions) {
            // If questions is a number, use it as the count and set questions to nil
            questions = nil
            no_questions = questionsCount
        } else {
            questions = nil
            // Try to get no_questions from its own field if available
            no_questions = try container.decodeIfPresent(Int.self, forKey: .no_questions) ?? 0
        }
        
        print("Decoded quiz: \(title), image path: \(heroImagePath), difficulty: \(difficulty), no questions: \(no_questions)")
    }
}

// This structure would be used when you're ready to implement the actual quiz functionality
struct Question: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var options: [String]
    var correctAnswerIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case options
        case correctAnswerIndex = "correct_answer_index"
    }
    
    init(text: String, options: [String], correctAnswerIndex: Int) {
        self.text = text
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
    }
}
