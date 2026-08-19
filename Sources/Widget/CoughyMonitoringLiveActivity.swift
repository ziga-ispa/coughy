//
//  CoughyMonitoringLiveActivity.swift
//  CoughyPhone
//
//  Created by Brian Chang on 19/08/26.
//


import ActivityKit
import WidgetKit
import SwiftUI

struct CoughyMonitoringLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MonitoringActivityAttributes.self) { context in
            LockScreenBanner(context: context)
                .activityBackgroundTint(Color(red: 0.65, green: 0.55, blue: 0.62).opacity(0.55))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (ditekan lama) ──
                DynamicIslandExpandedRegion(.leading) {
                    coughyIcon(size: 30)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "waveform")
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.84))
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("Coughie Monitoring")
                            .font(.caption).foregroundStyle(.white.opacity(0.8))
                        Text(context.state.startDate, style: .timer)
                            .font(.title2.monospacedDigit().bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: StopMonitoringIntent()) {
                        Label("Stop Session", systemImage: "stop.fill")
                            .font(.subheadline.bold())
                    }
                    .tint(Color(red: 1.0, green: 0.82, blue: 0.84))
                }
            } compactLeading: {
                coughyIcon(size: 20)
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
                    .foregroundStyle(.white)
            } minimal: {
                coughyIcon(size: 18)
            }
            .keylineTint(Color(red: 1.0, green: 0.82, blue: 0.84))
        }
    }

    // Ganti Image("coughy") begitu asset bulan+bintang sudah kamu masukkan
    // ke asset catalog milik target WIDGET. Sementara pakai SF Symbol dulu.
    @ViewBuilder
    private func coughyIcon(size: CGFloat) -> some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: size))
            .foregroundStyle(.white)
        // Kalau asset sudah ada, ganti dua baris di atas dengan:
        // Image("coughy").resizable().scaledToFit().frame(width: size, height: size)
    }
}

private struct LockScreenBanner: View {
    let context: ActivityViewContext<MonitoringActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.stars.fill")   // ⬅️ ganti Image("coughy") nanti
                .font(.system(size: 40))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title)
                    .font(.headline).foregroundStyle(.white)
                Text(context.state.startDate, style: .timer)
                    .font(.title.monospacedDigit().bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(intent: StopMonitoringIntent()) {
                VStack(spacing: 2) {
                    Image(systemName: "stop.fill")
                    Text("Stop\nSession").font(.caption2.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(10)
                .background(Color(red: 1.0, green: 0.82, blue: 0.84))
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
    }
}
