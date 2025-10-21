//
//  MDSettingsView.swift
//  Moro Drift
//
//

import SwiftUI

struct MDSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
        @StateObject var settingsVM = CPSettingsViewModel()
        var body: some View {
            ZStack {
                
                VStack {
                    
                    
                    ZStack {
                        
                        Image(.settingsBgMD)
                            .resizable()
                            .scaledToFit()
                        
                        
                        VStack(spacing: 0) {
                            
                            VStack {
                                
                                Image(.soundsTextMD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:24)
                                
                                Button {
                                    withAnimation {
                                        settingsVM.soundEnabled.toggle()
                                    }
                                } label: {
                                    Image(settingsVM.soundEnabled ? .onMD:.offMD)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:35)
                                }
                            }
                            
                            Image(.languageTextMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:100)
                            
                            
                        }
                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:250)
                    
                }.padding(.top, 50)
                
                VStack {
                    ZStack {
                        
                        HStack {
                            Image(.settingsIconMD)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:50)
                        }
                        
                        HStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                                
                            } label: {
                                Image(.backIconMD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                            }
                            
                            Spacer()
                            
                            ZZCoinBg()
                            
                        }.padding()
                    }
                    Spacer()
                    
                }
            }.frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        Image(.appBgMD)
                            .resizable()
                            .ignoresSafeArea()
                            .scaledToFill()
                    }
                )
        }
    }

#Preview {
    MDSettingsView()
}
