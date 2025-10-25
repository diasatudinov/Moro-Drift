//
//  ContentView.swift
//  Moro Drift
//
//


// ContentView.swift
import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var state = GameState()
    @State private var scene: GameScene?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Градиент
                Image(.gameBgMD)
                    .resizable()
                    .ignoresSafeArea()
                    
               
                // Прозрачная SpriteKit сцена
                if let scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                        .background(Color.clear)
                }
                
                // HUD
                VStack {
                    HStack {
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        
                        Button {
                            state.reset(); scene?.resetWorld()
                            
                        } label: {
                            Image(.restartBtnMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Text("SCORE: \(state.score)")
                                .bold()
                            HStack(spacing: 0) {
                                Image(.heartImgMD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 20)
                                
                                Text(": \(state.lives)")
                            }.bold()
                        }.padding()
                    }
                    .padding(.horizontal, 16).padding(.top, 10)
                    Spacer()
                    
                    // Пульт
                    HStack(spacing: 24) {
                        
                        HStack(spacing: 52) {
                            PressHold(label: "backIconMD") { press in
                                press ? scene?.startMoveLeft() : scene?.stopMoveLeft()
                            }
                            .frame(height: 30)
                            PressHold(label: "backIconMD1") { press in
                                press ? scene?.startMoveRight() : scene?.stopMoveRight()
                            }
                            .frame(height: 30)
                        }.offset(y: 0)
                        
                        
                        Spacer()
                        HStack(spacing: 12) {
                            Button {
                                scene?.playerShoot()
                            } label: {
                                Image(.shootBtnMD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 30)
                            }
                        }
                        
                    }
                }
                
                
                // Баннер Game Over
                if state.isGameOver {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ZStack {
                        Image(.gameOverBgMD)
                            .resizable()
                            .scaledToFit()
                        
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 10) {
                                HStack {
                                    Image(.survivedTextMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:20)
                                    
                                    Spacer()
                                    
                                    ZStack {
                                        Image(.timeBgMD)
                                            .resizable()
                                            .scaledToFit()
                                        
                                        Text("\(TimeFormatter.mmss(state.elapsedTime))")
                                            .foregroundStyle(.white)
                                            .bold()
                                        
                                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:25)
                                }.padding(.horizontal)
                                
                                HStack {
                                    Image(.killsTextMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:20)
                                    Spacer()
                                    ZStack {
                                        Image(.timeBgMD)
                                            .resizable()
                                            .scaledToFit()
                                        
                                        Text("\(state.kills)")
                                            .foregroundStyle(.white)
                                            .bold()
                                        
                                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:25)
                                }.padding(.horizontal)
                                
                                HStack {
                                    Image(.scoreTextMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:20)
                                    Spacer()
                                    ZStack {
                                        Image(.timeBgMD)
                                            .resizable()
                                            .scaledToFit()
                                        
                                        Text("\(TimeFormatter.mmss(state.bestTime))")
                                            .foregroundStyle(.white)
                                            .bold()
                                        
                                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:25)
                                }.padding(.horizontal)
                                
                            }.padding()
                            Spacer()
                            HStack {
                                Button {
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Image(.menuBtnMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                                }
                                
                                Button {
                                    state.reset(); scene?.resetWorld()
                                } label: {
                                    Image(.retryBtnMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                                }
                            }
                        }
                        
                    }.frame(width: 270, height: 290)
                    
                    
                }
            }
            .onAppear {
                let s = GameScene(size: geo.size, state: state)
                s.scaleMode = .resizeFill
                s.backgroundColor = .clear
                scene = s
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - UI Helpers

struct HUDCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FatCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .padding(.horizontal, 22).padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

struct PressHold: View {
    let label: String
    let action: (Bool) -> Void
    var body: some View {
        Image(label)
            .resizable()
            .scaledToFit()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in action(true) }
                    .onEnded { _ in action(false) }
            )
    }
}
#Preview {
    GameView()
}

final class GameState: ObservableObject {
    // HUD
    @Published var score: Int = 0
    @Published var kills: Int = 0
    @Published var lives: Int = 3
    @Published var missesLeft: Int = 5
    @Published var isGameOver: Bool = false
    
    // Время
    @Published var elapsedTime: TimeInterval = 0
    @Published var bestTime: TimeInterval = UserDefaults.standard.double(forKey: "bestTime_v2")
    
    // Бонус
    struct ActiveBonus {
        let kind: BonusKind
        var timeLeft: TimeInterval
        var label: String { kind.label }
    }
    enum BonusKind {
        case rapidFire, shield
        var label: String { switch self { case .rapidFire: return "Rapid Fire"; case .shield: return "Shield" } }
        var duration: TimeInterval { 8 }
    }
    @Published var activeBonus: ActiveBonus?
    
    // Внутри
    private var runStartTime: TimeInterval = 0
    private var running: Bool = false
    
    // MARK: - API
    func startRun(at now: TimeInterval) {
        runStartTime = now
        elapsedTime = 0
        running = true
    }
    
    func tick(now: TimeInterval) {
        guard running else { return }
        elapsedTime = max(0, now - runStartTime)
    }
    
    func finishRun() {
        running = false
        if elapsedTime > bestTime {
            bestTime = elapsedTime
            UserDefaults.standard.set(bestTime, forKey: "bestTime_v2")
        }
    }
    
    func reset() {
        score = 0
        kills = 0
        lives = 3
        missesLeft = 5
        isGameOver = false
        activeBonus = nil
        elapsedTime = 0
        // bestTime оставляем
    }
}

enum TimeFormatter {
    private static let mmss: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .positional          // "M:S"
        f.zeroFormattingBehavior = [.pad]   // => "MM:SS"
        return f
    }()
    
    static func mmss(_ seconds: TimeInterval) -> String {
        // Используем floor, чтобы 59.9 не превращалось в 01:00
        let floored = floor(max(0, seconds))
        return mmss.string(from: floored) ?? "00:00"
    }
}
