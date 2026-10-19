//
//  ContentView.swift
//  TinyRituals
//
//  Created by Alex Plat on 14.09.26.
//


import SwiftUI

struct Ritual: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

struct ContentView: View {
    @State private var rituals = [
        Ritual(
            icon: "drop.fill",
            title: "Выпить воды",
            color: .teal
        ),
        Ritual(
            icon: "figure.walk",
            title: "Прогулка",
            color: .red
        ),
        Ritual(
            icon: "book.fill",
            title: "Почитать вместе",
            color: .purple
        )
    ]

    @State private var completedDates: [UUID: Set<String>] = [:]
    @State private var showingAddRitual = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.93, blue: 0.91)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(rituals) { ritual in
                            RitualHistoryCard(
                                ritual: ritual,
                                completedDays: completedDates[ritual.id] ?? []
                            ) {
                                toggleToday(for: ritual)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
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
                    rituals.append(newRitual)
                }
            }
        }
    }

    private func toggleToday(for ritual: Ritual) {
        let today = dateKey(Date())
        var days = completedDates[ritual.id] ?? []

        if days.contains(today) {
            days.remove(today)
        } else {
            days.insert(today)
        }

        completedDates[ritual.id] = days
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

struct AddRitualView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedIcon = "heart.fill"

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

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Сон ребёнка", text: $title)
                }

                Section("Иконка") {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: 4
                        )
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(
                                        selectedIcon == icon
                                        ? .purple
                                        : .gray
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        minHeight: 44
                                    )
                                    .background(
                                        selectedIcon == icon
                                        ? Color.purple.opacity(0.15)
                                        : Color.clear
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )
                            }
                        }
                    }
                }

                Section {
                    Button("Добавить ритуал") {
                        let newRitual = Ritual(
                            icon: selectedIcon,
                            title: title,
                            color: .orange
                        )

                        onAdd(newRitual)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
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

struct RitualHistoryCard: View {
    let ritual: Ritual
    let completedDays: Set<String>
    let action: () -> Void

    private var today: String {
        dateKey(Date())
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())

        while completedDays.contains(dateKey(date)) {
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
                        .foregroundStyle(
                            completedDays.contains(today)
                            ? .white
                            : .gray
                        )
                        .frame(width: 58, height: 58)
                        .background(
                            completedDays.contains(today)
                            ? ritual.color
                            : Color.gray.opacity(0.16)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text("Сен")
                Spacer()
                Text("Окт")
                Spacer()
                Text("Ноя")
                Spacer()
                Text("Дек")
                Spacer()
                Text("Янв")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HabitGrid(
                color: ritual.color,
                completedDays: completedDays
            )
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

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
            calendar.date(
                byAdding: .day,
                value: index - 99,
                to: today
            )
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(last100Days, id: \.self) { date in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        completedDays.contains(dateKey(date))
                        ? color
                        : color.opacity(0.16)
                    )
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
