import SwiftUI
import UIKit

struct ResultView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel
    let session: CoughSession

    @State private var now = Date()
    @State private var showReport = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

                VStack(spacing: 0) {
                    // Top-right icons
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundStyle(.white)
                            Image(systemName: "cloud.sun.fill")
                                .font(.title2)
                                .foregroundStyle(Color.brand)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Greeting
                    Text(greeting)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    // Date
                    Text(formattedDate)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.deepNavy)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 18, weight: .heavy))
                        Text(formattedTime)
                            .font(.system(size: 20, weight: .heavy))
                    }
                    .foregroundStyle(Color.deepNavy)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)

                    // Subtitle
                    Text("Last night we detected")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 32)

                    // Total count
                    Text("\(session.events.count)")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundStyle(Color.deepNavy)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    Text("Total Coughs")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.deepNavy)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Dry / Wet / Confidence split
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(session.dryCount)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Color.deepNavy)
                            Text("Dry")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.brand)
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 1, height: 48)

                        VStack(spacing: 4) {
                            Text("\(session.wetCount)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Color.brand)
                            Text("Wet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.brand)
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 1, height: 48)

                        VStack(spacing: 4) {
                            Text("\(averageConfidence)%")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Color.deepNavy)
                            Text("Confidence")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.brand)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)

                    // Duration
                    VStack(spacing: 4) {
                        Text(durationString)
                            .font(.system(size: 36, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.deepNavy)
                        Text("ELAPSED TIME")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.deepNavy)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)

                    Spacer()

                    // View Report button
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        Text("View Report")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brand)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .onReceive(timer) { now = $0 }
        }
    }

    // MARK: - Computed

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        default:      timeOfDay = "evening"
        }
        return "Good \(timeOfDay), \(deviceFirstName)"
    }

    private var deviceFirstName: String {
        var name = UIDevice.current.name
        for suffix in ["'s iPhone", "'s iPad", "'s iPod", "s iPhone", "s iPad"] {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        return name.isEmpty ? "there" : name
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: now).uppercased()
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: now)
    }

    private var durationString: String {
        let total = Int(session.duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var averageConfidence: Int {
        guard !session.events.isEmpty else { return 0 }
        let total = session.events.reduce(0.0) { $0 + $1.confidence }
        return Int((total / Double(session.events.count)) * 100)
    }
}
