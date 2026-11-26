import SwiftUI

/// Panel konfigurace pojmenování (§6.2) s trvale viditelným náhledem.
struct ConfigPanel: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("config.title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(L("config.baseName"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                TextField(L("config.baseName.placeholder"), text: $vm.config.baseName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13).monospaced())
                    .foregroundStyle(theme.textPrimary)
                    .padding(8)
                    .background(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            // §9.2: nevyplněný název blokuje přejmenování a je zvýrazněn.
                            .stroke(vm.config.isValid ? theme.border : theme.danger, lineWidth: vm.config.isValid ? 1 : 2)
                    )
                if vm.config.isBaseNameModified {
                    // §9.3: nepovolené znaky „/“ a „:“ se automaticky nahradí podtržítkem.
                    Text(L("config.sanitized"))
                        .font(.system(size: 11))
                        .foregroundStyle(theme.danger)
                }
            }

            configRow(title: L("config.position")) {
                AppSegmentedControl(selection: $vm.config.position, options: [
                    (.numberFirst, L("config.position.numberFirst")),
                    (.nameFirst, L("config.position.nameFirst")),
                ])
            }

            configRow(title: L("config.numberFormat")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    AppSegmentedControl(
                        selection: $vm.config.numberFormat,
                        options: NumberFormat.allCases.map { ($0, $0.label) }
                    )
                }
            }

            configRow(title: L("config.separator")) {
                AppSegmentedControl(
                    selection: $vm.config.separator,
                    options: NameSeparator.allCases.map { ($0, $0.label) }
                )
            }

            configRow(title: L("config.startNumber")) {
                HStack(spacing: 8) {
                    TextField("1", value: $vm.config.startNumber, format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13).monospaced())
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: 72)
                        .padding(6)
                        .background(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    Stepper("", value: $vm.config.startNumber, in: 0...99999)
                        .labelsHidden()
                }
            }

            HStack(spacing: 8) {
                Text(L("config.preview"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(vm.config.sampleName())
                    .font(.system(size: 13).monospaced())
                    .foregroundStyle(vm.config.isValid ? theme.textPrimary : theme.danger)
            }
        }
        .padding(16)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func configRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            content()
        }
    }
}
