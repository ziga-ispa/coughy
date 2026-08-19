import SwiftUI
import Charts

struct NightlyActivityChart: View {
    let session: CoughSession

    private struct HourBucket: Identifiable {
        let id: Int // index 0, 1, 2...
        let hour: Int
        let label: String
        let dry: Int
        let wet: Int
        var total: Int { dry + wet }
        var maxCount: Int { max(dry, wet) }
    }

    private var buckets: [HourBucket] {
        guard !session.events.isEmpty else { return [] }

        // Group by hour
        var dryCounts: [Int: Int] = [:]
        var wetCounts: [Int: Int] = [:]
        for event in session.events {
            let hour = Calendar.current.component(.hour, from: event.timestamp)
            if event.type == .dry {
                dryCounts[hour, default: 0] += 1
            } else {
                wetCounts[hour, default: 0] += 1
            }
        }

        // Find hours with events plus adjacent hours
        let eventHours = Set(dryCounts.keys).union(Set(wetCounts.keys))
        var includedHours = Set<Int>()
        for h in eventHours {
            includedHours.insert((h - 1 + 24) % 24)
            includedHours.insert(h)
            includedHours.insert((h + 1) % 24)
        }

        // Sort chronologically (assuming night session from ~noon to ~noon)
        let sortedHours = includedHours.sorted { 
            let k1 = ($0 + 12) % 24
            let k2 = ($1 + 12) % 24
            return k1 < k2
        }

        return sortedHours.enumerated().map { index, hour in
            HourBucket(
                id: index,
                hour: hour,
                label: hourLabel(hour),
                dry: dryCounts[hour] ?? 0,
                wet: wetCounts[hour] ?? 0
            )
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:  return "12a"
        case 12: return "12p"
        case 1..<12: return "\(hour)a"
        default: return "\(hour - 12)p"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title and Legend
            HStack {
                Text("NIGHTLY ACTIVITY")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.brand)
                
                Spacer()
                
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "4A90D9"))
                            .frame(width: 8, height: 8)
                        Text("Dry")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "7BAE7F"))
                            .frame(width: 8, height: 8)
                        Text("Wet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }

            if buckets.isEmpty {
                Text("No data")
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(buckets) { b in
                        if b.dry > 0 {
                            BarMark(
                                x: .value("Time", Double(b.id) - 0.15),
                                y: .value("Count", b.dry),
                                width: .fixed(6)
                            )
                            .foregroundStyle(Color(hex: "4A90D9"))
                            .cornerRadius(3)
                        }

                        if b.wet > 0 {
                            BarMark(
                                x: .value("Time", Double(b.id) + 0.15),
                                y: .value("Count", b.wet),
                                width: .fixed(6)
                            )
                            .foregroundStyle(Color(hex: "7BAE7F"))
                            .cornerRadius(3)
                        }
                    }

                    let linePoints: [(x: Double, y: Int)] = buckets.flatMap { b -> [(Double, Int)] in
                        var pts: [(Double, Int)] = []
                        if b.dry > 0 && b.wet > 0 {
                            pts.append((Double(b.id) - 0.15, b.dry))
                            pts.append((Double(b.id) + 0.15, b.wet))
                        } else if b.dry > 0 {
                            pts.append((Double(b.id) - 0.15, b.dry))
                        } else if b.wet > 0 {
                            pts.append((Double(b.id) + 0.15, b.wet))
                        } else {
                            pts.append((Double(b.id), 0))
                        }
                        return pts
                    }
                    
                    ForEach(linePoints.indices, id: \.self) { i in
                        LineMark(
                            x: .value("Time", linePoints[i].x),
                            y: .value("Count", linePoints[i].y)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.white)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: buckets.map { Double($0.id) }) { value in
                        if let x = value.as(Double.self),
                           let bucket = buckets.first(where: { Double($0.id) == x }) {
                            AxisValueLabel {
                                Text(bucket.label)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color(hex: "D9D9D9").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
