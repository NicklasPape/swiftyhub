import SwiftUI
import Foundation

struct SwiftieChatbotView: View {
    @State private var userInput: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    
    let chatService = SwiftieChatService()
    
    let introMessages = [
        "Hey there, Swiftie! 👋",
        "I'm so excited to chat with you about my music, albums, or just about anything! 🎤✨"
    ]
    
    let questionMessages = [
        "What's your favorite album of mine? I'd love to know! 💿",
        "Have you listened to The Tortured Poets Department yet? What did you think? 📝",
        "Are you coming to any of my upcoming tour dates? I'd love to see you there! 🎫",
        "Which era is your favorite? I'm always curious what resonates with different Swifties! ✨",
        "What's your favorite song of mine? I've written so many, it's hard to keep track! 🎵",
        "Did you catch any of my Easter eggs in my recent music videos? I love hiding little clues! 🥚",
        "If you could hear me re-record any song next, which one would you choose? 🎙️",
        "Are you more of a folklore or evermore person? The eternal debate! 🌲",
        "What's one question you've always wanted to ask me? I'm an open book today! 📖",
        "If we could hang out for a day, what would you want to do? I'm thinking cats and baking! 🐱🧁"
    ]
    
    @State private var hasShownIntroMessages = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages, id: \.id) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isTyping {
                            HStack {
                                Text("Taylor is typing...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                Spacer()
                            }
                            .id("typingIndicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isTyping) { _, _ in
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
        .onAppear {
            if !hasShownIntroMessages {
                showIntroMessages()
            }
        }
    }
    
    func showIntroMessages() {
        hasShownIntroMessages = true
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTyping = false
            messages.append(ChatMessage(text: self.introMessages[0], isUser: false))
            
            isTyping = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...2.5)) {
                isTyping = false
                messages.append(ChatMessage(text: self.introMessages[1], isUser: false))
                
                isTyping = true
                
                let randomQuestion = self.questionMessages.randomElement() ?? "What would you like to talk about today?"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.0...3.0)) {
                    isTyping = false
                    messages.append(ChatMessage(text: randomQuestion, isUser: false))
                }
            }
        }
    }
    
    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(text: userInput, isUser: true)
        messages.append(userMessage)
        
        isTyping = true
        
        let typingDelay = Double.random(in: 1.0...3.0)
        
        chatService.getChatResponse(for: userInput) { response in
            DispatchQueue.main.asyncAfter(deadline: .now() + typingDelay) {
                isTyping = false
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
        
        userInput = ""
    }
}

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

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                Image("taylor_swift")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .background(Circle().fill(Color(UIColor.systemBackground)))
                    .padding(.top, 4)
            }
            
            if message.isUser { Spacer() }
            Text(message.text)
                .padding()
                .background(message.isUser ?
                           Color.blue.opacity(0.7) :
                           Color(UIColor.systemGray5))
                .cornerRadius(12)
                .foregroundColor(message.isUser ? .white : Color(UIColor.label))
                .frame(maxWidth: message.isUser ? 250 : 210, alignment: message.isUser ? .trailing : .leading)
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, 4)
    }
}
