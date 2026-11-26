import SwiftUI

/// Potvrzení po dokončení přejmenování (§6.4) + undo + seznam selhání (§9.5).
struct CompletionView: View {
    @ObservedObject var vm: AppViewModel
    let outcome: RenameOutcome
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(doneTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            if !outcome.failures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("done.failures"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.danger)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(outcome.failures) { failure in
                                Text("\(failure.fileName) — \(failure.message)")
                                    .font(.system(size: 12).monospaced())
                                    .foregroundStyle(theme.danger)
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                }
                .padding(12)
                .background(theme.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if let notice = vm.notice {
                Text(notice)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }

            HStack(spacing: 12) {
                if outcome.mode == .inPlace && !outcome.renamed.isEmpty {
                    Button(L("done.undo")) {
                        Task { await vm.undoLastRename() }
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
                Button(L("done.back")) {
                    vm.backToTimeline()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var doneTitle: String {
        let key = outcome.mode == .inPlace ? "done.count.renamed" : "done.count.copied"
        return String(format: NSLocalizedString(key, comment: ""), outcome.renamed.count)
    }
}
