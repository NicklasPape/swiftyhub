import SwiftUI
import Foundation

struct SwiftieChatbotView: View {
    @State private var userInput: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    
    let chatService = SwiftieChatService()
    
    // Intro messages are now handled by the backend endpoint
    @State private var hasShownIntroMessages = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages.indices, id: \.self) { index in
                                let message = messages[index]
                                ChatBubble(message: message, shouldShowAvatar: shouldShowAvatar(for: index))
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
                    TextField("Message", text: $userInput)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.vertical)

                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                            .padding(.trailing)
                    }
                    .disabled(isTyping)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("taylor_swift")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        
                        Text("Taylor Swift")
                            .font(.headline)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !hasShownIntroMessages {
                    showIntroMessages()
                }
            }
        }
    }
    
    func shouldShowAvatar(for index: Int) -> Bool {
        // Get the current message
        let currentMessage = messages[index]
        
        // No avatar for user messages
        if currentMessage.isUser {
            return false
        }
        
        // If this is the last message in the list, show avatar
        if index == messages.count - 1 {
            return true
        }
        
        // Get the next message
        let nextMessage = messages[index + 1]
        
        // If the current message is from Taylor and the next one is from the user
        // or if the next message is from Taylor but the current one is the last in a sequence,
        // show the avatar
        if !nextMessage.isUser {
            return false // Not the last message in a sequence
        } else {
            return true // This is the last Taylor message before a user message
        }
    }
    
    func showIntroMessages() {
        hasShownIntroMessages = true
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTyping = false
            var firstMessage = ChatMessage(text: "Hello, Swiftie!", isUser: false)
            firstMessage.imageName = "taylor_selfie"
            messages.append(firstMessage)
            
            isTyping = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...2.5)) {
                isTyping = false
                messages.append(ChatMessage(text: "I'm so excited to chat with you!", isUser: false))
                
                isTyping = true
                
                let randomQuestion = "What would you like to talk about today?"
                
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
    func getChatResponse(for userInput: String, completion: @escaping (String) -> Void) {
        sendMessageToTaylorSwift(userMessage: userInput) { response in
            if let response = response {
                completion(response)
            } else {
                completion("Oops! Something went wrong. Try again, Swiftie! ")
            }
        }
    }
    
    private func sendMessageToTaylorSwift(userMessage: String, completion: @escaping (String?) -> Void) {
        // URL for the Supabase Edge Function endpoint
        guard let url = URL(string: "https://xhjsundjajtfukpqpjxp.supabase.co/functions/v1/chat_taylor") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Updated request body to match the expected format in the new index file
        // Changed from "userMessage" to "message" to match the endpoint
        let requestBody: [String: Any] = ["message": userMessage]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reply = jsonResponse["reply"] as? String {
                DispatchQueue.main.async {
                    completion(reply)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

// The following structures remain unchanged
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var imageName: String? = nil
}

struct ChatBubble: View {
    let message: ChatMessage
    let shouldShowAvatar: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                // Taylor's message - show avatar or placeholder with fixed width
                if shouldShowAvatar {
                    Image("taylor_swift")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .background(Circle().fill(Color(UIColor.systemBackground)))
                } else {
                    // Empty space with fixed width to align all Taylor messages
                    Spacer()
                        .frame(width: 40)
                }
                
                // Check if there's an image - if so, just show the image without the text and grey box
                if let imageName = message.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .frame(maxWidth: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 210, alignment: .leading)
                } else {
                    // Text bubble for Taylor's messages without images
                    Text(message.text)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(12)
                        .foregroundColor(Color(UIColor.label))
                        .frame(maxWidth: 210, alignment: .leading)
                }
                
                Spacer() // Push Taylor's messages to the left
            } else {
                // User message - pushed to the right
                Spacer() // Push user messages to the right
                
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .frame(maxWidth: 250, alignment: .trailing)
            }
        }
        .padding(.horizontal, 4)
    }
}
