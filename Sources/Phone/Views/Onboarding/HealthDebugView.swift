import SwiftUI

struct HealthDebugView: View {
    private let healthKit = HealthKitService()

    @State private var samples: [SymptomSample] = []
    @State private var statusMessage = "Belum ada aksi."
    @State private var isBusy = false
    @State private var didRead = false

    var body: some View {
        NavigationView {
            List {
                Section("Status") {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Langkah Uji") {
                    Button("1. Minta Izin Health") { run { try await healthKit.requestAuthorization() }
                        message: { "Izin diminta. Cek dialog / Settings > Health." } }

                    Button("2. Tulis Sampel Uji (batuk)") { run { try await healthKit.writeTestCough() }
                        message: { "Berhasil menulis 1 sampel batuk ke Apple Health." } }

                    Button("3. Baca Data dari Health") {
                        run { samples = try await healthKit.readCoughSymptoms(); didRead = true }
                        message: { "Berhasil membaca \(samples.count) sampel." }
                    }
                }
                .disabled(isBusy)

                Section("Hasil Baca (\(samples.count))") {
                    if samples.isEmpty {
                        Text(didRead
                             ? "Kosong. Jalankan langkah 2 dulu, lalu baca lagi."
                             : "Belum dibaca.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(samples) { s in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Batuk — \(s.severity)")
                                    Text(s.date, style: .date) + Text(" ") + Text(s.date, style: .time)
                                }
                                .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Health Debug")
        }
    }

    /// Helper kecil: jalankan aksi async, tangani error, update status.
    private func run(_ action: @escaping () async throws -> Void,
                     message: @escaping () -> String) {
        Task {
            isBusy = true
            do {
                try await action()
                statusMessage = "✅ " + message()
            } catch {
                statusMessage = "❌ Error: \(error.localizedDescription)"
            }
            isBusy = false
        }
    }
}