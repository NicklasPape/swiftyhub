import Foundation

class QuizService {
    private let supabaseUrl = "https://xhjsundjajtfukpqpjxp.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoanN1bmRqYWp0ZnVrcHFwanhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NTU2NjcsImV4cCI6MjA1NjIzMTY2N30.jLpgsTIgHcqyj8oKspCnGh1_O7UOuHhJMxU3WxNGc-0"
    
    func fetchQuizzes(completion: @escaping ([Quiz]) -> Void) {
        print("Starting to fetch quizzes from Supabase...")
        
        fetchQuizzesFromSupabase { quizzes, error in
            if let error = error {
                print("Error fetching quizzes: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let quizzes = quizzes {
                print("Successfully fetched \(quizzes.count) quizzes from Supabase")
                self.verifyImagePaths(for: quizzes)
                completion(quizzes)
            } else {
                print("No quizzes returned from Supabase")
                completion([])
            }
        }
    }
    
    func fetchQuizzesFromSupabase(completion: @escaping ([Quiz]?, Error?) -> Void) {
        let endpoint = "\(supabaseUrl)/rest/v1/quizzes?select=*&order=created_at.desc"
        print("Fetching quizzes from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            completion(nil, NSError(domain: "QuizService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(nil, NSError(domain: "QuizService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            print("Received data size: \(data.count) bytes")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("FULL JSON RESPONSE:")
                print(jsonString)
                
                if jsonString.contains("hero_image_path") {
                    print("Response contains hero_image_path field")
                }
                
                if jsonString.contains("questions") {
                    print("Response contains questions field")
                } else {
                    print("questions field NOT found in response")
                }
            }
            
            do {
                let decoder = JSONDecoder()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let quizzes = try decoder.decode([Quiz].self, from: data)
                print("Successfully decoded \(quizzes.count) quizzes")
                
                for (i, quiz) in quizzes.enumerated() {
                    print("Quiz #\(i+1): \(quiz.title) - image path: '\(quiz.heroImagePath)'")
                    if let questions = quiz.questions {
                        print("  - Quiz has \(questions.count) questions")
                    } else {
                        print("  - Quiz has no questions decoded")
                    }
                }
                
                completion(quizzes, nil)
            } catch {
                print("Decoding error: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Raw response causing error: \(dataString)")
                }
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    func fetchQuizDetails(quizId: String, completion: @escaping (Quiz?) -> Void) {
        let endpoint = "\(supabaseUrl)/rest/v1/quizzes?id=eq.\(quizId)&select=*"
        print("Fetching quiz details from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL for quiz details")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching quiz details: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Quiz details HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No quiz details data received")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("QUIZ DETAILS JSON:")
                print(jsonString)
            }
            
            do {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let quizzes = try decoder.decode([Quiz].self, from: data)
                if let quiz = quizzes.first {
                    print("Successfully decoded quiz details: \(quiz.title)")
                    if let questions = quiz.questions {
                        print("Found \(questions.count) questions")
                        for (i, question) in questions.enumerated() {
                            print("  Question \(i+1): \(question.text)")
                        }
                    } else {
                        print("No questions found in the quiz")
                    }
                    DispatchQueue.main.async { completion(quiz) }
                } else {
                    print("Quiz with ID \(quizId) not found")
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                print("Error decoding quiz details: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Raw JSON causing error: \(dataString)")
                }
                DispatchQueue.main.async { completion(nil) }
            }
        }
        
        task.resume()
    }
    
    func verifyImagePaths(for quizzes: [Quiz]) {
        print("\n🔍 QUIZ IMAGE PATH VERIFICATION:")
        let storageBaseUrl = "https://xhjsundjajtfukpqpjxp.supabase.co/storage/v1/object/public/"
        
        for (index, quiz) in quizzes.enumerated() {
            let originalPath = quiz.heroImagePath
            print("Quiz #\(index+1): \(quiz.title)")
            print("  - Original path from db: '\(originalPath)'")
            
            if originalPath.isEmpty {
                print("  - ⚠️ Image path is empty, using fallback image")
                continue
            }
            
            let encodedPath = originalPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? originalPath
            let fullUrl = storageBaseUrl + encodedPath
            
            print("  - Encoded path: '\(encodedPath)'")
            print("  - Full URL: '\(fullUrl)'")
            print("")
            
            if let url = URL(string: fullUrl) {
                print("  - URL is valid")
                
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("  - HTTP status code for \(quiz.title): \(httpResponse.statusCode)")
                    }
                    if error != nil {
                        print("  - Error accessing URL for \(quiz.title): \(error?.localizedDescription ?? "unknown")")
                    } else if let data = data, !data.isEmpty {
                        print("  - Successfully retrieved data for \(quiz.title) (\(data.count) bytes)")
                    }
                }
                task.resume()
            } else {
                print("  - ⚠️ URL is invalid!")
            }
        }
        print("✅ End of verification\n")
    }
}
