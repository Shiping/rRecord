import SwiftUI

struct LaunchScreenView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isLoading = false
    @State private var fadeInOut = false
    @State private var imageOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image with flowing animation
                if geometry.size.width > geometry.size.height {
                    Image("desert0213_landscape", bundle: nil)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width * 1.1, height: geometry.size.height * 1.1)
                        .offset(x: imageOffset.width, y: imageOffset.height)
                        .animation(
                            Animation.easeInOut(duration: 8)
                                .repeatForever(autoreverses: true),
                            value: imageOffset
                        )
                } else {
                    Image("desert0213_portrait", bundle: nil)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width * 1.1, height: geometry.size.height * 1.1)
                        .offset(x: imageOffset.width, y: imageOffset.height)
                        .animation(
                            Animation.easeInOut(duration: 8)
                                .repeatForever(autoreverses: true),
                            value: imageOffset
                        )
                }

                // Content overlay
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("Mind Ur Meals")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                            .frame(height: 30)
                        
                        Text("Move Ur Feet")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                            .frame(height: 30)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        Text("管住嘴")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("迈开腿")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                    .scaleEffect(fadeInOut ? 1.05 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .cyan.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .padding(5)
                    )
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: fadeInOut
                    )
                    
                    Spacer()
                    HStack(spacing: 20) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .scaleEffect(isLoading ? 1.0 : 0.5)
                            .opacity(fadeInOut ? 0.5 : 1)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(0.0),
                                value: isLoading
                            )
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .scaleEffect(isLoading ? 1.0 : 0.5)
                            .opacity(fadeInOut ? 0.5 : 1)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(0.2),
                                value: isLoading
                            )
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .scaleEffect(isLoading ? 1.0 : 0.5)
                            .opacity(fadeInOut ? 0.5 : 1)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(0.4),
                                value: isLoading
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            isLoading = true
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                fadeInOut.toggle()
            }
            // Start background image flow animation
            withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                imageOffset = CGSize(width: 20, height: 20)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
