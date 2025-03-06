import SwiftUI
import Foundation

struct SwiftieChatbotView: View {
    @State private var userInput: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hey there, Swiftie! Ask me anything about my music, albums, or life! 🎤✨", isUser: false)
    ]
    @State private var isTyping = false
    
    let chatService = SwiftieChatService()
    
    var body: some View {
        // No NavigationView wrapper here since it's now in the App
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages, id: \.id) { message in
                            ChatBubble(message: message)
                                .id(message.id) // For scrolling to bottom
                        }
                        
                        // Add typing indicator
                        if isTyping {
                            HStack {
                                Text("Taylor is typing...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                Spacer()
                            }
                            .id("typingIndicator") // For scrolling to bottom
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    // Scroll to the bottom when a new message is added
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isTyping) { _, _ in
                    // Scroll to the bottom when typing indicator appears
                    if isTyping {
                        withAnimation {
                            scrollProxy.scrollTo("typingIndicator", anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Ask me anything...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding()
                }
                .disabled(isTyping)
            }
        }
        .navigationTitle("Chat with Taylor 🎶")
        
    }
    
    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(text: userInput, isUser: true)
        messages.append(userMessage)
        
        // Enable typing indicator
        isTyping = true
        
        // Random delay between 1-3 seconds to simulate typing
        let typingDelay = Double.random(in: 1.0...3.0)
        
        chatService.getChatResponse(for: userInput) { response in
            // Simulate typing delay
            DispatchQueue.main.asyncAfter(deadline: .now() + typingDelay) {
                isTyping = false
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
        
        userInput = ""
    }
}

// MARK: - Swiftie Chat Service
class SwiftieChatService {
    private let apiKey = "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"
    
    func getChatResponse(for userInput: String, completion: @escaping (String) -> Void) {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are Taylor Swift. Answer questions about your music, career, and life with fun Swiftie references. Keep answers short like you would normally in a chat interface. Ask the user questions to make them feel connected and seen"],
                ["role": "user", "content": userInput]
            ],
            "max_tokens": 300
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion("Oops! Something went wrong. Try again, Swiftie! 🎶")
            return
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion("I can't answer that right now, but keep shining! ✨")
                }
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
                DispatchQueue.main.async {
                    if let reply = decodedResponse.choices.first?.message.content {
                        completion(reply)
                    } else {
                        completion("Oops! Something went wrong. Try again, Swiftie! 🎶")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion("I can't answer that right now, but keep shining! ✨")
                }
            }
        }
        
        task.resume()
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
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - Chat Bubble UI
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) { 
            // Show Taylor's image for non-user messages
            if !message.isUser {
                Image("taylor_swift")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.white))
                    .padding(.top, 4)
            }
            
            if message.isUser { Spacer() }
            Text(message.text)
                .padding()
                .background(message.isUser ?
                           Color.blue.opacity(0.7) :
                           Color(.lightGray).opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(message.isUser ? .white : Color(.darkGray))
                .frame(maxWidth: message.isUser ? 250 : 210, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, 4)
    }
}
