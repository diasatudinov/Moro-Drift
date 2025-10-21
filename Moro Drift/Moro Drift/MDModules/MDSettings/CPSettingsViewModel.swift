//
//  CPSettingsViewModel.swift
//  Moro Drift
//
//


import SwiftUI

class CPSettingsViewModel: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
}
