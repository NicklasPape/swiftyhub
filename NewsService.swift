import Foundation

class NewsService {
    private let supabaseUrl = "https://xhjsundjajtfukpqpjxp.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoanN1bmRqYWp0ZnVrcHFwanhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NTU2NjcsImV4cCI6MjA1NjIzMTY2N30.jLpgsTIgHcqyj8oKspCnGh1_O7UOuHhJMxU3WxNGc-0"

    func fetchArticles(completion: @escaping ([Article]?) -> Void) {
        let endpoint = "\(supabaseUrl)/rest/v1/ai_articles"
        
        print("Fetching articles from endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")

        print("Starting network request...")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(nil)
                return
            }
            
            print("Received data size: \(data.count) bytes")
            
            do {
                let decodedArticles = try JSONDecoder().decode([Article].self, from: data)
                print("Successfully decoded \(decodedArticles.count) articles")
                completion(decodedArticles)
            } catch {
                print("Decoding error: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(dataString)")
                }
                completion(nil)
            }
        }

        task.resume()
    }
}
