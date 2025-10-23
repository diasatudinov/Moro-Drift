//
//  ContentView.swift
//  Moro Drift
//
//


// ContentView.swift
import SwiftUI
import SpriteKit

struct ContentView1: View {
    @State private var scene: GameScene?

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    // Градиентный фон под прозрачной сценой
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.08, green: 0.10, blue: 0.25),
                            Color(red: 0.10, green: 0.25, blue: 0.45)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    if let scene {
                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .ignoresSafeArea()
                            .background(Color.clear)
                    }

                    // HUD
                    VStack {
                        HStack {
                            HUDCard {
                                HStack(spacing: 12) {
                                    Text("Score: \(scene?.score ?? 0)")
                                    Text("Lives: \(scene?.lives ?? 0)")
                                    Text("Misses: \(scene?.missesLeft ?? 0)")
                                }
                            }
                            Spacer()
                            if let bonus = scene?.activeBonus {
                                HUDCard {
                                    HStack(spacing: 8) {
                                        Text("Bonus:")
                                        Text(bonus.kind.label) // <-- вот так, через kind
                                            .bold()
                                        Text("\(max(0, Int(ceil(bonus.timeLeft))))s")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        Spacer()

                        // Пульт управления
                        HStack(spacing: 24) {
                            HStack(spacing: 12) {
                                PressAndHoldButton(label: "◀︎") { pressing in
                                    if pressing { scene?.startMoveLeft() } else { scene?.stopMoveLeft() }
                                }
                                .frame(width: 64, height: 64)
                                PressAndHoldButton(label: "▶︎") { pressing in
                                    if pressing { scene?.startMoveRight() } else { scene?.stopMoveRight() }
                                }
                                .frame(width: 64, height: 64)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Spacer(minLength: 24)

                            HStack(spacing: 12) {
                                Button("Jump")  { scene?.playerJump() }.buttonStyle(FatCapsule())
                                Button("Shoot") { scene?.playerShoot() }.buttonStyle(FatCapsule())
                                Button("Reset") { scene?.resetWorld() }.buttonStyle(FatCapsule())
                            }
                        }
                        .padding(18)
                    }

                    // Экран Game Over
                    if (scene?.isGameOver ?? false) {
                        VStack(spacing: 16) {
                            Text("Game Over")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                            Text("Score: \(scene?.score ?? 0)")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .opacity(0.9)
                            Button("Play Again") { scene?.resetWorld() }
                                .buttonStyle(FatCapsule())
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .onAppear {
                    let s = GameScene(size: geo.size)
                    s.scaleMode = .resizeFill
                    s.backgroundColor = .clear
                    scene = s
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Small UI helpers

    struct HUDCard<Content: View>: View {
        @ViewBuilder var content: Content
        var body: some View {
            content
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
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

    struct PressAndHoldButton: View {
        let label: String
        let onPressChanged: (Bool) -> Void
        var body: some View {
            Text(label)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in onPressChanged(true) }
                        .onEnded { _ in onPressChanged(false) }
                )
        }
    }

#Preview {
    ContentView1()
}
