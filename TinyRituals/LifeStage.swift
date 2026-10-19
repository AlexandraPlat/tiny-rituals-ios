//
//  LifeStage.swift
//  TinyRituals
//
//  Created by Alex Plat on 19.10.26.
//

import SwiftUI

// MARK: - Life stage

/// The stage of life the user is in. It decides which rituals the app suggests.
enum LifeStage: String, Codable, CaseIterable, Identifiable {
    case pregnancy
    case infant       // up to 1 year
    case toddler      // 1-3 years
    case preschooler  // 3+ years

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .pregnancy: return "Pregnancy"
        case .infant: return "Baby, up to 1 year"
        case .toddler: return "Toddler, 1–3 years"
        case .preschooler: return "Child, 3+ years"
        }
    }

    /// A short starter set of rituals for this stage.
    /// Titles are localized when the rituals are created.
    func suggestedRituals() -> [Ritual] {
        switch self {
        case .pregnancy:
            return [
                Ritual(icon: "leaf.fill", title: String(localized: "Prenatal vitamins"), colorName: "orange"),
                Ritual(icon: "drop.fill", title: String(localized: "Drink water"), colorName: "teal"),
                Ritual(icon: "figure.walk", title: String(localized: "Walk"), colorName: "mint"),
                Ritual(icon: "moon.fill", title: String(localized: "Rest"), colorName: "purple")
            ]
        case .infant:
            return [
                Ritual(icon: "moon.fill", title: String(localized: "Bedtime routine"), colorName: "purple"),
                Ritual(icon: "figure.walk", title: String(localized: "Walk outside"), colorName: "mint"),
                Ritual(icon: "sun.max.fill", title: String(localized: "Tummy time"), colorName: "orange"),
                Ritual(icon: "heart.fill", title: String(localized: "Cuddle time"), colorName: "pink")
            ]
        case .toddler:
            return [
                Ritual(icon: "book.fill", title: String(localized: "Read together"), colorName: "purple"),
                Ritual(icon: "sun.max.fill", title: String(localized: "Play together"), colorName: "orange"),
                Ritual(icon: "figure.walk", title: String(localized: "Walk outside"), colorName: "mint"),
                Ritual(icon: "moon.fill", title: String(localized: "Bedtime routine"), colorName: "blue")
            ]
        case .preschooler:
            return [
                Ritual(icon: "book.fill", title: String(localized: "Read together"), colorName: "purple"),
                Ritual(icon: "house.fill", title: String(localized: "Tidy up together"), colorName: "teal"),
                Ritual(icon: "leaf.fill", title: String(localized: "Outdoor play"), colorName: "mint"),
                Ritual(icon: "moon.fill", title: String(localized: "Bedtime routine"), colorName: "blue")
            ]
        }
    }
}

// MARK: - Profile store

/// Keeps the chosen life stage and saves it on the device.
final class ProfileStore: ObservableObject {
    @Published var stage: LifeStage? {
        didSet { save() }
    }

    private let key = "lifeStage.v1"

    init() {
        if let raw = UserDefaults.standard.string(forKey: key) {
            stage = LifeStage(rawValue: raw)
        }
    }

    private func save() {
        if let stage {
            UserDefaults.standard.set(stage.rawValue, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
