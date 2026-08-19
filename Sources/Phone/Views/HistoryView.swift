import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var searchText = ""
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "003451"), location: 0.0),
                    .init(color: Color(hex: "000000"), location: 0.44)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text("History")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.6))
                    TextField("Search", text: $searchText)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .tint(.white)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Image(systemName: "mic")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .frame(width: 354, height: 44)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

                if weekSections.isEmpty {
                    Spacer()
                    Text("No sessions recorded yet.\nStart monitoring to track your coughs.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(weekSections) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section.label)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.brand)
                                        .tracking(1.5)
                                        .padding(.horizontal, 24)

                                    ForEach(section.sessions) { session in
                                        NavigationLink(destination: SessionDetailView(session: session)) {
                                            SessionCardView(session: session)
                                                .padding(.horizontal, 24)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            Spacer(minLength: 16)
                        }
                        .padding(.bottom, 24)
                    }
                }

                // Export button
                Button {
                    showingExport = true
                } label: {
                    Text("Export Report")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brand)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .disabled(historyStore.sessions.isEmpty)
                .opacity(historyStore.sessions.isEmpty ? 0.5 : 1)
                .sheet(isPresented: $showingExport) {
                    ExportReportView(sessions: historyStore.sessions)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        } // NavigationStack
    }

    // MARK: - Grouping

    private struct WeekSection: Identifiable {
        var id: String { label }
        let label: String
        var sessions: [CoughSession]
    }

    private var filteredSessions: [CoughSession] {
        let sorted = historyStore.sessions.sorted { $0.startDate > $1.startDate }
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter { session in
            let f = DateFormatter()
            f.dateFormat = "EEE, MMM d"
            return f.string(from: session.startDate).lowercased().contains(query)
        }
    }

    private var weekSections: [WeekSection] {
        let now = Date()
        let thisWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        var thisWeek: [CoughSession] = []
        var lastWeek: [CoughSession] = []
        var older: [String: [CoughSession]] = [:]
        var olderOrder: [String] = []

        for session in filteredSessions {
            if session.startDate >= thisWeekStart {
                thisWeek.append(session)
            } else if session.startDate >= lastWeekStart {
                lastWeek.append(session)
            } else {
                let f = DateFormatter()
                f.dateFormat = "MMMM yyyy"
                let key = f.string(from: session.startDate).uppercased()
                if older[key] == nil {
                    olderOrder.append(key)
                    older[key] = []
                }
                older[key]!.append(session)
            }
        }

        var sections: [WeekSection] = []
        if !thisWeek.isEmpty { sections.append(WeekSection(label: "THIS WEEK", sessions: thisWeek)) }
        if !lastWeek.isEmpty { sections.append(WeekSection(label: "LAST WEEK", sessions: lastWeek)) }
        for key in olderOrder {
            sections.append(WeekSection(label: key, sessions: older[key]!))
        }
        return sections
    }

}
