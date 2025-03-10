import Foundation

class NewsService {
    private let supabaseUrl = "https://xhjsundjajtfukpqpjxp.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoanN1bmRqYWp0ZnVrcHFwanhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NTU2NjcsImV4cCI6MjA1NjIzMTY2N30.jLpgsTIgHcqyj8oKspCnGh1_O7UOuHhJMxU3WxNGc-0"

    func fetchArticles(page: Int = 1, pageSize: Int = 10, completion: @escaping ([Article]?, Bool) -> Void) {
        let endpoint = "\(supabaseUrl)/rest/v1/ai_articles?select=*&order=created_at.desc&limit=\(pageSize)&offset=\((page-1)*pageSize)"
        
        print("Fetching articles from endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL")
            completion(nil, false)
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")

        print("Starting network request...")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil, false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(nil, false)
                return
            }
            
            print("Received data size: \(data.count) bytes")
            
            do {
                let decodedArticles = try JSONDecoder().decode([Article].self, from: data)
                print("Successfully decoded \(decodedArticles.count) articles")
                
                let hasMore = decodedArticles.count >= pageSize
                completion(decodedArticles, hasMore)
            } catch {
                print("Decoding error: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(dataString)")
                }
                completion(nil, false)
            }
        }

        task.resume()
    }
    
    private func filterDuplicateArticles(_ articles: [Article]) -> [Article] {
        var seenTitles = Set<String>()
        var uniqueArticles = [Article]()
        
        for article in articles {
            let normalizedTitle = article.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !seenTitles.contains(normalizedTitle) {
                seenTitles.insert(normalizedTitle)
                uniqueArticles.append(article)
            } else {
                print("Filtered out duplicate article: \(article.title)")
            }
        }
        
        return uniqueArticles
    }
}
