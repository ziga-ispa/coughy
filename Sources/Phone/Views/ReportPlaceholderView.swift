import SwiftUI

struct ReportPlaceholderView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel
    @Environment(\.dismiss) private var dismiss

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

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.brand)

                Text("Report Coming Soon")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Detailed session reports will be available in a future update.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Results")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
