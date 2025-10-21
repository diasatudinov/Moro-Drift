//
//  MDDailyView.swift
//  Moro Drift
//
//

import SwiftUI

struct MDDailyView: View {
    @Environment(\.presentationMode) var presentationMode
        @State private var isReceived = false
        var body: some View {
            ZStack {
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Image(.person2ImgMD)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:300)
                            .offset(y: 30)
                        Spacer()
                    }.ignoresSafeArea()
                }
                VStack {
                    
                    Image(.dailyIconMD)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 80:50)
                        .opacity(0)
                    
                    ZStack {
                        
                        Image(.dailyBgMD)
                            .resizable()
                            .scaledToFit()
                        
                        VStack {
                            Spacer()
                            
                            Button {
                                if !isReceived {
                                    ZZUser.shared.updateUserMoney(for: 20)
                                }
                                isReceived.toggle()
                            } label: {
                                Image(isReceived ? .collectedBtnMD : .collectBtnMD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:52)
                            }
                            
                        }.offset(y: 15)
                        
                    }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:240)
                    
                }
                
                VStack {
                    ZStack {
                        
                        HStack {
                            Image(.dailyIconMD)
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
    MDDailyView()
}
