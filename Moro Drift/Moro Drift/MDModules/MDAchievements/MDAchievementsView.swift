//
//  MDAchievementsView.swift
//  Moro Drift
//
//

import SwiftUI

struct MDAchievementsView: View {
    @StateObject var user = ZZUser.shared
       @Environment(\.presentationMode) var presentationMode
       
       @StateObject var viewModel = ZZAchievementsViewModel()
       @State private var index = 0
       var body: some View {
           ZStack {
               
               VStack {
                   ZStack {
                       
                       HStack {
                           Image(.achievementsIconMD)
                               .resizable()
                               .scaledToFit()
                               .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:80)
                       }
                       
                       HStack(alignment: .top) {
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
                       }.padding(.horizontal)
                   }.padding([.top])
                   
                   Spacer()
                   ScrollView(.horizontal) {
                       HStack(spacing: 20) {
                           ForEach(viewModel.achievements, id: \.self) { item in
                               ZStack {
                                   Image(item.image)
                                       .resizable()
                                       .scaledToFit()
                                       .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:230)
                                   
                                   VStack {
                                       Spacer()
                                       
                                       Button {
                                           if !item.isAchieved {
                                               user.updateUserMoney(for: 10)
                                           }
                                           viewModel.achieveToggle(item)
                                       } label: {
                                           Image(item.isAchieved ? .collectedBtnMD : .collectBtnMD)
                                               .resizable()
                                               .scaledToFit()
                                               .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:52)
                                       }
                                   }
                                   
                               }
                           }
                           
                       }
                   }
                   Spacer()
               }
           }.background(
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
    MDAchievementsView()
}
