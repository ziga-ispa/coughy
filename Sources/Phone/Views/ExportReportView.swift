import SwiftUI
import PDFKit
import UIKit

struct ExportReportView: View {
    @Environment(\.dismiss) private var dismiss

    let sessions: [CoughSession]

    private let calendar: Calendar
    private let today: Date
    private let minimumDate: Date

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var previewURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(sessions: [CoughSession], now: Date = Date(), calendar: Calendar = .current) {
        self.sessions = sessions
        self.calendar = calendar

        let startOfToday = calendar.startOfDay(for: now)
        let lastSevenDaysStart = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let retainedHistoryStart = calendar.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday

        today = startOfToday
        minimumDate = retainedHistoryStart
        _startDate = State(initialValue: lastSevenDaysStart)
        _endDate = State(initialValue: startOfToday)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let previewURL {
                    PDFPreviewView(url: previewURL)
                } else {
                    dateRangeContent
                }
            }
            .navigationTitle(previewURL == nil ? "Export Report" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if previewURL == nil {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .accessibilityLabel("Cancel")
                    } else {
                        Button {
                            removePreviewFile()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }

                if previewURL != nil {
                    ToolbarItem(placement: .principal) {
                        Text("Report Preview")
                            .font(.headline)
                    }
                }
            }
        }
        .tint(Color.deepNavy)
        .alert("Could Not Create Report", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .onDisappear {
            removePreviewFile()
        }
    }

    private var dateRangeContent: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "7CABC5"), Color(hex: "3A6B85")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose a date range")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Select which recorded sessions should be included in your report.")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    VStack(spacing: 0) {
                        DatePicker(
                            "From",
                            selection: $startDate,
                            in: startPickerRange,
                            displayedComponents: .date
                        )
                        .padding(.vertical, 14)

                        Divider()
                            .overlay(Color.deepNavy.opacity(0.15))

                        DatePicker(
                            "To",
                            selection: $endDate,
                            in: endPickerRange,
                            displayedComponents: .date
                        )
                        .padding(.vertical, 14)
                    }
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: matchingSessions.isEmpty ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                            Text(sessionCountText)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(matchingSessions.isEmpty ? Color.yellow : Color.brand)

                        if matchingSessions.isEmpty {
                            Text("Choose different dates to preview a report.")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Button {
                        generatePreview()
                    } label: {
                        HStack(spacing: 10) {
                            if isGenerating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "doc.text.magnifyingglass")
                            }
                            Text(isGenerating ? "Preparing Report..." : "Preview Report")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brand)
                        .clipShape(Capsule())
                    }
                    .disabled(matchingSessions.isEmpty || isGenerating)
                    .opacity(matchingSessions.isEmpty || isGenerating ? 0.55 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var selectedRange: ReportDateRange {
        ReportDateRange(startDate: startDate, endDate: endDate, calendar: calendar)
    }

    private var matchingSessions: [CoughSession] {
        selectedRange.matchingSessions(from: sessions)
    }

    private var sessionCountText: String {
        let count = matchingSessions.count
        return count == 1 ? "1 session will be included" : "\(count) sessions will be included"
    }

    private var startPickerRange: ClosedRange<Date> {
        minimumDate...min(endDate, today)
    }

    private var endPickerRange: ClosedRange<Date> {
        max(startDate, minimumDate)...today
    }

    private func generatePreview() {
        guard !matchingSessions.isEmpty, !isGenerating else { return }

        isGenerating = true
        removePreviewFile()

        let generator = ReportPDFGenerator()
        let range = selectedRange
        let sessionsForReport = matchingSessions

        do {
            let data = try generator.makePDFData(sessions: sessionsForReport, dateRange: range)
            let url = generator.temporaryURL(for: range)
            try data.write(to: url, options: .atomic)

            guard let document = PDFDocument(url: url), document.pageCount > 0 else {
                try? FileManager.default.removeItem(at: url)
                throw ReportPDFGenerator.GenerationError.invalidPDF
            }

            previewURL = url
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isGenerating = false
    }

    private func removePreviewFile() {
        guard let previewURL else { return }
        try? FileManager.default.removeItem(at: previewURL)
        self.previewURL = nil
    }
}

private struct PDFPreviewView: View {
    let url: URL

    @State private var showingShareSheet = false

    var body: some View {
        PDFDocumentView(url: url)
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                PDFShareSheet(activityItems: [url])
            }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemGroupedBackground
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
    }
}

private struct PDFShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
