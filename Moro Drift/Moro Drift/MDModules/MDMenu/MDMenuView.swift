//
//  MDMenuView.swift
//  Moro Drift
//
//

import SwiftUI

struct MDMenuView: View {
    @State private var showGame = false
    @State private var showAchievement = false
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showDailyReward = false
    
    var body: some View {
        
        ZStack {
            
            
            VStack(spacing: 0) {
                
                HStack {
                    
                    Spacer()
                    
                    ZZCoinBg()
                    
                    
                }.padding(20).padding(.bottom, 5)
                Spacer()
            }
            
            HStack {
                Image(.personImgMD)
                    .resizable()
                    .scaledToFit()
                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:322)
                
                Spacer()
                
            }.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Image(.loaderViewLogoMD)
                    .resizable()
                    .scaledToFit()
                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:140)
                    .cornerRadius(12)
                    .padding(.top, 20)
                Spacer()
                HStack(spacing: 10) {
                    VStack(spacing: 10) {
                        
                        Button {
                            showGame = true
                        } label: {
                            Image(.playIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:75)
                        }
                        
                        Button {
                            showDailyReward = true
                        } label: {
                            Image(.dailyIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:75)
                        }
                        
                        
                    }
                    
                    VStack(spacing: 10) {
                        
                        Button {
                            showAchievement = true
                        } label: {
                            Image(.achievementsIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:75)
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(.settingsIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:75)
                        }
                    }
                }
                Spacer()
            }
            
            
            
        }.frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Image(.appBgMD)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFill()
                }
            )
            .fullScreenCover(isPresented: $showGame) {
                //                    GameRootView()
            }
            .fullScreenCover(isPresented: $showAchievement) {
                MDAchievementsView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                MDSettingsView()
            }
            .fullScreenCover(isPresented: $showDailyReward) {
                MDDailyView()
            }
    }
}


#Preview {
    MDMenuView()
}
