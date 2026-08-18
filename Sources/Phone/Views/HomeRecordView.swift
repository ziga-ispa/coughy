import SwiftUI
import UIKit

struct HomeRecordView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel
    @State private var now = Date()
    @State private var showTip = true
    @State private var pulse = false
    @State private var sensitivity = 1
    @Environment(\.openURL) private var openURL
    @State private var showHealthAlert = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if viewModel.isMonitoring {
                ActiveMonitorView()
                    .transition(.opacity)
            } else if let session = viewModel.completedSession {
                ResultView(session: session)
                    .transition(.opacity)
            } else {
                preRecordContent
                    .transition(.opacity)
            }
        }
        .onReceive(timer) { now = $0 }
        .onAppear { pulse = viewModel.isMonitoring }
    }

    private var preRecordContent: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "7CABC5"), Color(hex: "3A6B85")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Greeting row
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 2) {
                            Text(greeting)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(formattedDate)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.deepNavy)
                                .frame(maxWidth: .infinity, alignment: .center)
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 18, weight: .heavy))
                                Text(formattedTime)
                                    .font(.system(size: 20, weight: .heavy))
                            }
                            .foregroundStyle(Color.deepNavy)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        Image(systemName: "moon.zzz.fill")
                            .font(.title)
                            .foregroundStyle(Color.brand)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Big monitor button
                    ZStack(alignment: .center) {
                        // Inner circle + mic (shifted up) + label at bottom
                        // all inside the glass container so glass renders behind them
                        ZStack {
                            // Dark tint layer so glass material renders darker
                            Circle()
                                .fill(Color(hex: "2A5A78").opacity(0.45))

                            Circle()
                                .fill(Color.brand)
                                .frame(width: 104, height: 104)
                                .shadow(color: .black.opacity(0.25), radius: 23, x: 0, y: 4)
                                .scaleEffect(pulse ? 1.08 : 1.0)
                                .animation(
                                    viewModel.isMonitoring
                                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                        : .default,
                                    value: pulse
                                )
                                .offset(y: -28)

                            Image(systemName: "mic.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 37, height: 55)
                                .foregroundStyle(Color(hex: "321613"))
                                .offset(y: -28)

                            VStack(spacing: 1) {
                                Text(viewModel.isMonitoring ? "Stop" : "Start")
                                    .font(.system(size: 22, weight: .bold))
                                Text("Monitoring")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .offset(y: 58)
                        }
                        .frame(width: 202, height: 202)
                        .glassEffect(in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .shadow(color: .black.opacity(0.25), radius: 23, x: 0, y: 4)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 8)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if viewModel.isMonitoring {
                                viewModel.stopSession()
                                pulse = false
                            } else {
                                viewModel.startSession()
                                pulse = true
                            }
                        }
                    }

                    // Moon status — outside card, centered
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(Color.brand)
                        Text(viewModel.isMonitoring ? "Session active..." : "Ready for tonight's session")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.brand)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Mic sensitivity segmented control
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                        Text("Mic Sensitivity")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Log Symptoms button
                    Button {
                        showHealthAlert = true
                    } label: {
                        ZStack {
                            Text("Log Symptoms")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Image(systemName: "pencil.line")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brand)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Pro tip card
                    if showTip {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "2A5A78").opacity(0.45))
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
                                    Text("PRO TIP")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.brand)
                                    Text("Place your phone face down on your bedside table for best results.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                                Button {
                                    withAnimation { showTip = false }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(16)
                        }
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 32)
                }
            }
        }
        .alert("Log Symptoms in Apple Health to Sync with Coughie", isPresented: $showHealthAlert) {
            Button("Cancel", role: .destructive) { }
            Button("Open Health", role: .cancel) {
                if let url = URL(string: "x-apple-health://") {
                    openURL(url)
                }
            }
            .tint(.blue)
        } message: {
            Text("Symptoms will be synced for the report.")
        }
        .tint(.blue)
    }

    private func statusRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(icon.contains("moon") ? Color.brand : .white)
            Text(label)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
}
