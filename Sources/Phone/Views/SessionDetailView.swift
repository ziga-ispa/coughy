import SwiftUI

struct SessionDetailView: View {
    let session: CoughSession
    @State private var showInsights = true

    var body: some View {
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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row
                        HStack {
                            Text(headerTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "7CABC5"))

                            Spacer()

                            ShareLink(item: shareSummary) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brand)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.body)
                                        .foregroundStyle(Color(hex: "321613"))
                                        .blendMode(.destinationOut)
                                        .offset(y: -2)
                                }
                                .compositingGroup()
                            }
                        }

                        // Total count
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                Text("\(session.events.count)")
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundStyle(Color(hex: "7CABC5"))

                                Text("Total Coughs")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color(hex: "7CABC5"))
                            }

                            Text(timeRangeString)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, -8)
                    }

                    // Hourly activity chart
                    NightlyActivityChart(session: session)

                    // Key Insights card
                    if showInsights {
                        insightsCard
                    }

                    // Detected Events header
                    Text("Detected Events")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.brand)

                    // Event rows
                    VStack(spacing: 8) {
                        ForEach(session.events.sorted { $0.timestamp > $1.timestamp }) { event in
                            DetectedEventRow(event: event)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Key Insights Card

    private var insightsCard: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brand)
                        .frame(width: 44, height: 44)
                    Image(systemName: "bed.double.fill")
                        .font(.body)
                        .foregroundStyle(.black)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.brand)

                    Text(insightsText)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "2A5A78").opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .background {
                Color.clear
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                    .opacity(0.25)
            }
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))

            Button {
                withAnimation { showInsights = false }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                .padding(10)
            }
        }
    }

    // MARK: - Computed strings

    private var headerTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return "\(f.string(from: session.startDate).uppercased()) | SESSION ANALYSIS"
    }

    private var timeRangeString: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        let start = f.string(from: session.startDate)
        let end = f.string(from: session.endDate ?? Date())
        return "\(start) – \(end)"
    }

    private var peakHourString: String {
        guard !session.events.isEmpty else { return "midnight" }
        var counts: [Int: Int] = [:]
        for event in session.events {
            let h = Calendar.current.component(.hour, from: event.timestamp)
            counts[h, default: 0] += 1
        }
        let peakHour = counts.max(by: { $0.value < $1.value })?.key ?? 0
        let f = DateFormatter()
        f.dateFormat = "ha"
        var components = Calendar.current.dateComponents([.year, .month, .day], from: session.startDate)
        components.hour = peakHour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? session.startDate
        return f.string(from: date).lowercased()
    }

    private var wetPct: Int {
        guard !session.events.isEmpty else { return 0 }
        return Int(Double(session.wetCount) / Double(session.events.count) * 100)
    }

    private var insightsText: String {
        "Your coughing peaked around \(peakHourString). The acoustic profile indicates that \(wetPct)% of the events were productive coughs."
    }

    private var shareSummary: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return """
        Coughy Session Report
        Date: \(f.string(from: session.startDate))
        Total Coughs: \(session.events.count)
        Dry: \(session.dryCount) | Wet: \(session.wetCount)
        Peak activity: \(peakHourString)
        """
    }
}
