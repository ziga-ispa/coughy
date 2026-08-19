import SwiftUI
import UIKit

struct ActiveMonitorView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header

                    HStack {
                        Text("Monitor")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.brand)
                                    .frame(width: 28, height: 28)
                                Text(String(deviceFirstName.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.deepNavy)
                            }
                            Text(deviceFirstName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())

                        Image(systemName: "moon.zzz.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brand)
                            .padding(.leading, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Session label
                    Text("SESSION \(String(format: "%03d", viewModel.sessionNumber))")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    // Elapsed timer
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(spacing: 4) {
                            Text(elapsedString(at: context.date))
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.deepNavy)
                            Text("ELAPSED TIME")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(2)
                                .foregroundStyle(Color.deepNavy.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Acoustic feed + floating avatar
                    ZStack(alignment: .bottomTrailing) {
                        AcousticFeedView(eventCount: viewModel.events.count)

                        ZStack {
                            Circle()
                                .fill(Color.brand)
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
                            Text(String(deviceFirstName.prefix(1)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.deepNavy)
                        }
                        .offset(x: -20, y: 16)
                    }

                    // Recent Detections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Detections")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)

                        if viewModel.events.isEmpty {
                            Text("No detections yet...")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.events.prefix(10)) { event in
                                    ActiveEventRowView(event: event, viewModel: viewModel)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                    }

                    // Space so content doesn't hide behind the pinned stop button
                    Spacer(minLength: 120)
                }
            }

            // Stop button pinned above tab bar
            VStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.stopSession()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "E36775"))
                            .frame(width: 104, height: 104)
                            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brand)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func elapsedString(at date: Date) -> String {
        let start = viewModel.currentSession?.startDate ?? date
        let interval = max(0, Int(date.timeIntervalSince(start)))
        let h = interval / 3600
        let m = (interval % 3600) / 60
        let s = interval % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var deviceFirstName: String {
        var name = UIDevice.current.name
        for suffix in ["'s iPhone", "'s iPad", "'s iPod", "s iPhone", "s iPad"] {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        return name.isEmpty ? "User" : name
    }
}
