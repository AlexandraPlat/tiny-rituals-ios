//
//  ContentView.swift
//  TinyRituals
//
//  Created by Alex Plat on 14.09.26.
//

import SwiftUI

// MARK: - Палитра

enum RitualPalette {
    static let names = ["teal", "mint", "red", "purple", "orange", "pink", "blue"]

    static func color(named name: String) -> Color {
        switch name {
        case "teal": return .teal
        case "mint": return .mint
        case "red": return .red
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Модель

struct Ritual: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var icon: String
    var title: String
    var colorName: String

    var color: Color {
        RitualPalette.color(named: colorName)
    }
}

// MARK: - Работа с датами

enum DateKey {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static var today: String {
        string(from: Date())
    }
}

// MARK: - Хранилище

final class RitualStore: ObservableObject {
    @Published var rituals: [Ritual] = [] {
        didSet { saveRituals() }
    }

    @Published var completedDates: [String: Set<String>] = [:] {
        didSet { saveCompleted() }
    }

    private let ritualsKey = "rituals.v1"
    private let completedKey = "completedDates.v1"
    private var isLoading = false

    init() {
        load()
    }

    // MARK: Действия

    func toggleToday(for ritual: Ritual) {
        let key = ritual.id.uuidString
        var days = completedDates[key] ?? []

        if days.contains(DateKey.today) {
            days.remove(DateKey.today)
        } else {
            days.insert(DateKey.today)
        }

        completedDates[key] = days
    }

    func days(for ritual: Ritual) -> Set<String> {
        completedDates[ritual.id.uuidString] ?? []
    }

    func add(_ ritual: Ritual) {
        rituals.append(ritual)
    }

    func delete(_ ritual: Ritual) {
        completedDates[ritual.id.uuidString] = nil
        rituals.removeAll { $0.id == ritual.id }
    }

    // MARK: Сохранение и загрузка

    private func saveRituals() {
        guard !isLoading else { return }
        if let data = try? JSONEncoder().encode(rituals) {
            UserDefaults.standard.set(data, forKey: ritualsKey)
        }
    }

    private func saveCompleted() {
        guard !isLoading else { return }
        if let data = try? JSONEncoder().encode(completedDates) {
            UserDefaults.standard.set(data, forKey: completedKey)
        }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }

        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: ritualsKey),
           let saved = try? JSONDecoder().decode([Ritual].self, from: data) {
            rituals = saved
        } else {
            rituals = RitualStore.defaultRituals
        }

        if let data = defaults.data(forKey: completedKey),
           let saved = try? JSONDecoder().decode([String: Set<String>].self, from: data) {
            completedDates = saved
        }
    }

    private static let defaultRituals: [Ritual] = [
        Ritual(icon: "drop.fill", title: "Выпить воды", colorName: "teal"),
        Ritual(icon: "figure.walk", title: "Прогулка", colorName: "red"),
        Ritual(icon: "book.fill", title: "Почитать вместе", colorName: "purple")
    ]
}

// MARK: - Главный экран

struct ContentView: View {
    @StateObject private var store = RitualStore()
    @State private var showingAddRitual = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.93, blue: 0.91)
                    .ignoresSafeArea()

                List {
                    ForEach(store.rituals) { ritual in
                        RitualHistoryCard(
                            ritual: ritual,
                            completedDays: store.days(for: ritual)
                        ) {
                            store.toggleToday(for: ritual)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                store.delete(ritual)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Все ритуалы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRitual = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddRitual) {
                AddRitualView { newRitual in
                    store.add(newRitual)
                }
            }
        }
    }
}

// MARK: - Добавление ритуала

struct AddRitualView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedIcon = "heart.fill"
    @State private var selectedColor = "purple"

    let icons = [
        "heart.fill",
        "sun.max.fill",
        "moon.fill",
        "figure.walk",
        "book.fill",
        "drop.fill",
        "leaf.fill",
        "house.fill"
    ]

    var onAdd: (Ritual) -> Void

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Сон ребёнка", text: $title)
                }

                Section("Иконка") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 4)
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(
                                        selectedIcon == icon
                                        ? RitualPalette.color(named: selectedColor)
                                        : .gray
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        selectedIcon == icon
                                        ? RitualPalette.color(named: selectedColor).opacity(0.15)
                                        : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Цвет") {
                    HStack(spacing: 14) {
                        ForEach(RitualPalette.names, id: \.self) { name in
                            Button {
                                selectedColor = name
                            } label: {
                                Circle()
                                    .fill(RitualPalette.color(named: name))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if selectedColor == name {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Добавить ритуал") {
                        onAdd(
                            Ritual(
                                icon: selectedIcon,
                                title: trimmedTitle,
                                colorName: selectedColor
                            )
                        )
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .navigationTitle("Новый ритуал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Карточка ритуала

struct RitualHistoryCard: View {
    let ritual: Ritual
    let completedDays: Set<String>
    let action: () -> Void

    private var isDoneToday: Bool {
        completedDays.contains(DateKey.today)
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())

        while completedDays.contains(DateKey.string(from: date)) {
            streak += 1

            guard let previousDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: date
            ) else {
                break
            }

            date = previousDate
        }

        return streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(ritual.color.opacity(0.18))
                        .frame(width: 58, height: 58)
                        .overlay {
                            Image(systemName: ritual.icon)
                                .font(.title2)
                                .foregroundStyle(ritual.color)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ritual.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        HStack(spacing: 8) {
                            StatisticBadge(
                                icon: "flame.fill",
                                text: "\(currentStreak)",
                                color: ritual.color
                            )

                            StatisticBadge(
                                icon: "calendar",
                                text: "\(completedDays.count)",
                                color: ritual.color
                            )
                        }
                    }
                }

                Spacer()

                Button(action: action) {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(isDoneToday ? .white : .gray)
                        .frame(width: 58, height: 58)
                        .background(
                            isDoneToday ? ritual.color : Color.gray.opacity(0.16)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            MonthLabels()

            HabitGrid(color: ritual.color, completedDays: completedDays)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Подписи месяцев

struct MonthLabels: View {
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.setLocalizedDateFormatFromTemplate("LLL")
        return formatter
    }()

    private var months: [String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dates = (0..<100).compactMap {
            calendar.date(byAdding: .day, value: $0 - 99, to: today)
        }

        var result: [String] = []
        var seenMonth: Int?

        for date in dates {
            let month = calendar.component(.month, from: date)
            if month != seenMonth {
                seenMonth = month
                result.append(MonthLabels.monthFormatter.string(from: date))
            }
        }

        return result
    }

    var body: some View {
        HStack {
            ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                Text(month)
                if index < months.count - 1 {
                    Spacer()
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Сетка истории

struct HabitGrid: View {
    let color: Color
    let completedDays: Set<String>

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 5),
        count: 20
    )

    private var last100Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<100).compactMap { index in
            calendar.date(byAdding: .day, value: index - 99, to: today)
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(last100Days, id: \.self) { date in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        completedDays.contains(DateKey.string(from: date))
                        ? color
                        : color.opacity(0.16)
                    )
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - Вспомогательное

struct StatisticBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
