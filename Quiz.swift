import Foundation

struct Quiz: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let difficulty: String
    let no_questions: Int
    let heroImagePath: String
    let questions: [Question]?
    
    private static let completedQuizzesKey = "completedQuizzes"
    
    var isCompleted: Bool {
        let completedQuizzes = UserDefaults.standard.dictionary(forKey: Quiz.completedQuizzesKey) as? [String: Double] ?? [:]
        return completedQuizzes[id] != nil
    }
    
    var scorePercentage: Double {
        let completedQuizzes = UserDefaults.standard.dictionary(forKey: Quiz.completedQuizzesKey) as? [String: Double] ?? [:]
        return completedQuizzes[id] ?? 0.0
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case difficulty
        case no_questions
        case heroImagePath = "hero_image_path"
        case questions
    }
    
    init(title: String, description: String, heroImagePath: String, difficulty: String, no_questions: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.heroImagePath = heroImagePath
        self.difficulty = difficulty
        self.no_questions = no_questions
        self.questions = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        heroImagePath = try container.decodeIfPresent(String.self, forKey: .heroImagePath) ?? ""
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "Medium"
        no_questions = try container.decodeIfPresent(Int.self, forKey: .no_questions) ?? 0
        questions = try container.decodeIfPresent([Question].self, forKey: .questions)
        
        print("Decoded quiz: \(title), image path: \(heroImagePath), difficulty: \(difficulty), no questions: \(no_questions)")
    }
    
    static func markCompleted(_ quizId: String, score: Double) {
        var completedQuizzes = UserDefaults.standard.dictionary(forKey: Quiz.completedQuizzesKey) as? [String: Double] ?? [:]
        completedQuizzes[quizId] = score
        UserDefaults.standard.set(completedQuizzes, forKey: completedQuizzesKey)
        UserDefaults.standard.synchronize()
    }

    static func resetCompletion(_ quizId: String) {
        var completedQuizzes = UserDefaults.standard.dictionary(forKey: Quiz.completedQuizzesKey) as? [String: Double] ?? [:]
        completedQuizzes.removeValue(forKey: quizId)
        UserDefaults.standard.set(completedQuizzes, forKey: completedQuizzesKey)
        UserDefaults.standard.synchronize()
    }
}

struct Question: Identifiable, Codable {
    var id: String
    var text: String
    var options: [String]
    var correctAnswerIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case options
        case correctAnswerIndex
    }
    
    init(text: String, options: [String], correctAnswerIndex: Int) {
        self.id = UUID().uuidString
        self.text = text
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        options = try container.decode([String].self, forKey: .options)
        correctAnswerIndex = try container.decode(Int.self, forKey: .correctAnswerIndex)
        
        print("Successfully decoded question: \(text)")
    }
}
