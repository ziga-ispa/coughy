import Foundation
import UIKit

struct ReportDateRange: Equatable {
    let startDate: Date
    let endDate: Date
    private let calendar: Calendar

    init(startDate: Date, endDate: Date, calendar: Calendar = .current) {
        self.calendar = calendar
        self.startDate = calendar.startOfDay(for: startDate)
        self.endDate = calendar.startOfDay(for: endDate)
    }

    var isValid: Bool {
        startDate <= endDate
    }

    var endExclusive: Date {
        calendar.date(byAdding: .day, value: 1, to: endDate)
            ?? endDate.addingTimeInterval(24 * 60 * 60)
    }

    func contains(_ session: CoughSession) -> Bool {
        guard isValid else { return false }
        return session.startDate >= startDate && session.startDate < endExclusive
    }

    func matchingSessions(from sessions: [CoughSession]) -> [CoughSession] {
        sessions
            .filter(contains)
            .sorted { $0.startDate > $1.startDate }
    }
}

struct ReportPDFGenerator {
    enum GenerationError: LocalizedError {
        case invalidDateRange
        case noSessions
        case invalidPDF

        var errorDescription: String? {
            switch self {
            case .invalidDateRange:
                return "The selected date range is invalid."
            case .noSessions:
                return "There are no sessions in the selected date range."
            case .invalidPDF:
                return "The report could not be opened as a PDF."
            }
        }
    }

    private let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    private let pageMargin: CGFloat = 42
    private let navy = UIColor(red: 0.00, green: 0.204, blue: 0.318, alpha: 1)
    private let accent = UIColor(red: 1.00, green: 0.824, blue: 0.843, alpha: 1)
    private let bodyColor = UIColor(red: 0.12, green: 0.15, blue: 0.17, alpha: 1)
    private let secondaryColor = UIColor(red: 0.35, green: 0.39, blue: 0.42, alpha: 1)

    func makePDFData(
        sessions: [CoughSession],
        symptoms: [SymptomRecord] = [],
        dateRange: ReportDateRange,
        generatedAt: Date = Date()
    ) throws -> Data {
        guard dateRange.isValid else { throw GenerationError.invalidDateRange }

        let reportSessions = dateRange.matchingSessions(from: sessions)
        guard !reportSessions.isEmpty else { throw GenerationError.noSessions }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let rangeDateFormatter = DateFormatter()
        rangeDateFormatter.dateStyle = .medium
        rangeDateFormatter.timeStyle = .none

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            var canvas = PDFCanvas(
                context: context,
                pageRect: pageRect,
                margin: pageMargin,
                title: "Coughy - Session Report",
                period: "Period: \(rangeDateFormatter.string(from: dateRange.startDate)) - \(rangeDateFormatter.string(from: dateRange.endDate))",
                generated: "Generated: \(dateFormatter.string(from: generatedAt))",
                titleColor: navy,
                accentColor: accent,
                bodyColor: bodyColor,
                secondaryColor: secondaryColor
            )

            canvas.beginPage()

            let sessionCount = reportSessions.count
            let sessionLabel = sessionCount == 1 ? "1 session" : "\(sessionCount) sessions"
            canvas.drawText(
                "\(sessionLabel) included",
                font: .systemFont(ofSize: 11, weight: .medium),
                color: secondaryColor,
                spacingAfter: 18
            )

            for (index, session) in reportSessions.enumerated() {
                canvas.drawSession(
                    session,
                    number: index + 1,
                    dateFormatter: dateFormatter,
                    durationFormatter: durationString,
                    titleColor: navy,
                    bodyColor: bodyColor,
                    accentColor: accent
                )
            }
            
            canvas.drawSymptoms(
                symptoms,
                dateFormatter: dateFormatter,
                titleColor: navy,
                bodyColor: bodyColor,
                secondaryColor: secondaryColor,
                accentColor: accent
            )
            
            canvas.finishPage()
        }
    }

    func temporaryURL(for dateRange: ReportDateRange) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"

        let filename = "Coughy-Report-\(formatter.string(from: dateRange.startDate))-to-\(formatter.string(from: dateRange.endDate)).pdf"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

private struct PDFCanvas {
    let context: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    let title: String
    let period: String
    let generated: String
    let titleColor: UIColor
    let accentColor: UIColor
    let bodyColor: UIColor
    let secondaryColor: UIColor

    private(set) var pageNumber = 0
    private(set) var y: CGFloat = 0

    private var contentWidth: CGFloat {
        pageRect.width - (margin * 2)
    }

    private var contentBottom: CGFloat {
        pageRect.height - margin - 24
    }

    mutating func beginPage() {
        context.beginPage()
        pageNumber += 1
        y = margin

        let pageTitle = pageNumber == 1 ? title : "\(title) (continued)"
        drawText(
            pageTitle,
            font: .systemFont(ofSize: pageNumber == 1 ? 22 : 13, weight: .bold),
            color: titleColor,
            spacingAfter: pageNumber == 1 ? 8 : 6
        )

        if pageNumber == 1 {
            drawText(period, font: .systemFont(ofSize: 11), color: secondaryColor, spacingAfter: 3)
            drawText(generated, font: .systemFont(ofSize: 11), color: secondaryColor, spacingAfter: 16)
        } else {
            y += 2
        }

        drawRule()
        y += 16
    }

    mutating func finishPage() {
        guard pageNumber > 0 else { return }

        let footer = "Page \(pageNumber)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: secondaryColor
        ]
        let size = (footer as NSString).size(withAttributes: attributes)
        footer.draw(
            at: CGPoint(
                x: pageRect.width - margin - size.width,
                y: pageRect.height - margin + 4
            ),
            withAttributes: attributes
        )
    }

    mutating func drawSession(
        _ session: CoughSession,
        number: Int,
        dateFormatter: DateFormatter,
        durationFormatter: (TimeInterval) -> String,
        titleColor: UIColor,
        bodyColor: UIColor,
        accentColor: UIColor
    ) {
        ensureSpace(112)
        drawRule(color: accentColor, thickness: 2)
        y += 11

        drawText(
            "Session \(number)",
            font: .systemFont(ofSize: 14, weight: .bold),
            color: titleColor,
            spacingAfter: 8
        )

        drawLines(
            [
                "Date: \(dateFormatter.string(from: session.startDate))",
                "Duration: \(durationFormatter(session.duration))",
                "Total coughs: \(session.events.count) (dry: \(session.dryCount), wet: \(session.wetCount))"
            ],
            font: .systemFont(ofSize: 11),
            color: bodyColor,
            lineSpacing: 4
        )

        if let notes = session.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawLines(
                wrappedLines(for: "Notes: \(notes)", font: .systemFont(ofSize: 11), width: contentWidth),
                font: .systemFont(ofSize: 11),
                color: bodyColor,
                lineSpacing: 4
            )
        }

        y += 13
    }
    
    mutating func drawSymptoms(
        _ symptoms: [SymptomRecord],
        dateFormatter: DateFormatter,
        titleColor: UIColor,
        bodyColor: UIColor,
        secondaryColor: UIColor,
        accentColor: UIColor
    ) {
        ensureSpace(90)
        y += 6
        drawRule(color: accentColor, thickness: 2)
        y += 11
        
        drawText(
            "Symptoms (from Health app)",
            font: .systemFont(ofSize: 14, weight: .bold),
            color: titleColor,
            spacingAfter: 8
        )
        
        let order = ["Fever", "Runny Nose", "Sore Throat"]
        let grouped = Dictionary(grouping: symptoms, by: { $0.name })
        
        for name in order {
            drawText(
                name,
                font: .systemFont(ofSize: 12, weight: .semibold),
                color: bodyColor,
                spacingAfter: 4
            )
            
            let entries = (grouped[name] ?? []).sorted { $0.date < $1.date }
            if entries.isEmpty {
                drawLines(
                    ["    No entries in this period"],
                    font: .systemFont(ofSize: 11),
                    color: secondaryColor,
                    lineSpacing: 4
                )
            } else {
                drawLines(
                    entries.map { "    \(dateFormatter.string(from: $0.date)) — \($0.severity)" },
                    font: .systemFont(ofSize: 11),
                    color: bodyColor,
                    lineSpacing: 4
                )
            }
            y += 8
        }
    }

    mutating func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        spacingAfter: CGFloat
    ) {
        let lines = wrappedLines(for: text, font: font, width: contentWidth)
        drawLines(lines, font: font, color: color, lineSpacing: 0)
        y += spacingAfter
    }

    mutating func drawLines(
        _ lines: [String],
        font: UIFont,
        color: UIColor,
        lineSpacing: CGFloat
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let lineHeight = ceil(font.lineHeight)

        for line in lines {
            if y + lineHeight > contentBottom {
                finishPage()
                beginPage()
            }

            (line as NSString).draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: attributes
            )
            y += lineHeight + lineSpacing
        }
    }

    mutating func ensureSpace(_ requiredHeight: CGFloat) {
        if y + requiredHeight > contentBottom {
            finishPage()
            beginPage()
        }
    }

    mutating func drawRule(
        color: UIColor = UIColor(white: 0.86, alpha: 1),
        thickness: CGFloat = 1
    ) {
        color.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: margin, y: y, width: contentWidth, height: thickness),
            cornerRadius: thickness / 2
        ).fill()
    }

    private func wrappedLines(for text: String, font: UIFont, width: CGFloat) -> [String] {
        let paragraphs = text.components(separatedBy: .newlines)
        var result: [String] = []
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        for paragraph in paragraphs {
            if paragraph.isEmpty {
                result.append("")
                continue
            }

            var currentLine = ""
            for word in paragraph.split(separator: " ", omittingEmptySubsequences: true) {
                let wordString = String(word)
                let candidate = currentLine.isEmpty ? wordString : "\(currentLine) \(wordString)"
                let candidateWidth = (candidate as NSString).size(withAttributes: attributes).width

                if candidateWidth <= width {
                    currentLine = candidate
                } else if currentLine.isEmpty {
                    result.append(contentsOf: splitLongWord(wordString, font: font, width: width))
                } else {
                    result.append(currentLine)
                    currentLine = wordString
                }
            }

            if !currentLine.isEmpty {
                result.append(currentLine)
            }
        }

        return result.isEmpty ? [""] : result
    }

    private func splitLongWord(_ word: String, font: UIFont, width: CGFloat) -> [String] {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        var result: [String] = []
        var current = ""

        for character in word {
            let candidate = current + String(character)
            if !current.isEmpty && (candidate as NSString).size(withAttributes: attributes).width > width {
                result.append(current)
                current = String(character)
            } else {
                current = candidate
            }
        }

        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
