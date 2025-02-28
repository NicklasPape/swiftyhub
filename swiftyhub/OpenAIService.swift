import Foundation

struct OpenAIRequest: Codable {
    let model: String
    let messages: [[String: String]]
    let max_tokens: Int
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

class OpenAIService {
    private let apiKey = "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"

    func generateArticle(headline: String, snippet: String, completion: @escaping (String?) -> Void) {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        let prompt = "Write a very short and entertaining news article based on this headline: '\(headline)'. The snippet is: '\(snippet)'. Expand this into a brief but well-structured article."

        let body = OpenAIRequest(
            model: "gpt-4",
            messages: [
                ["role": "system", "content": "You are a professional news journalist writing entertaining news online."],
                ["role": "user", "content": prompt]
            ],
            max_tokens: 350
        )

        guard let jsonData = try? JSONEncoder().encode(body) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil,
                  let decodedResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data) else {
                completion(nil)
                return
            }
            completion(decodedResponse.choices.first?.message.content)
        }

        task.resume()
    }
}
