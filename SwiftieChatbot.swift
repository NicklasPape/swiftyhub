import SwiftUI
import Foundation
import UIKit

struct SwiftieChatbotView: View {
    @State private var userInput: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var isKeyboardVisible = false
    
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
                                // If we have no messages yet (intro case), use the indented version
                                if messages.isEmpty {
                                    TypingIndicatorView()
                                        .id("typingIndicator")
                                } else {
                                    TypingIndicatorView()
                                        .id("typingIndicator")
                                }
                            }
                        }
                        .padding()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissKeyboard()
                        }
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
                    ZStack(alignment: .leading) {
                        if userInput.isEmpty {
                            Text("Chat with Taylor...")
                                .foregroundColor(Color("LipstickRed").opacity(0.5))
                                .font(.custom("AvenirNext-Regular", size: 16))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                        }
                        TextField("", text: $userInput)
                            .foregroundColor(Color("LipstickRed"))
                            .padding(10)
                            .background(Color("LipstickRed").opacity(0.1))
                            .cornerRadius(20)
                            .accentColor(Color("LipstickRed"))
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                    
                    if userInput.isEmpty && isKeyboardVisible {
                        Button(action: dismissKeyboard) {
                            Image(systemName: "arrow.down")
                                .foregroundColor(Color("LipstickRed"))
                                .padding(10)
                                .background(Color("LipstickRed").opacity(0.1))
                                .clipShape(Circle())
                                .padding(.trailing)
                        }
                        .transition(.scale(scale: 0, anchor: .trailing).combined(with: .opacity))
                    } else if !userInput.isEmpty {
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(Color("LipstickRed"))
                                .padding(10)
                                .background(Color("LipstickRed").opacity(0.1))
                                .clipShape(Circle())
                                .padding(.trailing)
                        }
                        .disabled(isTyping)
                        .transition(.scale(scale: 0, anchor: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: userInput.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
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
                
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = true
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = false
                }
            }
            .onDisappear {
                // Remove observers when view disappears
                NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
                NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
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
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

struct TypingIndicatorView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image("taylor_swift")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .background(Circle().fill(Color(UIColor.systemBackground)))
            
            HStack(spacing: 0) {
                // Only animate the dots
                BouncingDotsView()
                Text(" Taylor is typing")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
                
                
            }
            .padding(.vertical, 4)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct BouncingDotsView: View {
    // Animation properties
    @State private var dot1Animation = false
    @State private var dot2Animation = false
    @State private var dot3Animation = false
    
    private let dotSize: CGFloat = 2
    private let dotColor = Color.gray
    
    var body: some View {
        HStack(spacing: 2) {
            // First dot
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .offset(y: dot1Animation ? -4 : 0)
                .animation(
                    Animation.easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true),
                    value: dot1Animation
                )
            
            // Second dot
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .offset(y: dot2Animation ? -4 : 0)
                .animation(
                    Animation.easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(0.15),
                    value: dot2Animation
                )
            
            // Third dot
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .offset(y: dot3Animation ? -4 : 0)
                .animation(
                    Animation.easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(0.3),
                    value: dot3Animation
                )
        }
        .onAppear {
            // Trigger all animations immediately but their delays will stagger them
            dot1Animation = true
            dot2Animation = true
            dot3Animation = true
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var imageName: String? = nil
}

struct ChatBubble: View {
    let message: ChatMessage
    let shouldShowAvatar: Bool
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 4
    
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
                        .frame(width: 32)
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
                        .font(.custom("AvenirNext-Regular", size: 16))
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
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .padding()
                    .background(Color("LipstickRed").opacity(0.7))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .frame(maxWidth: 250, alignment: .trailing)
            }
        }
        .padding(.horizontal, 4)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
                yOffset = 0
            }
        }
    }
}
