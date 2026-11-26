import SwiftUI

/// Tabulka přejmenování (§6.3); kolize jsou zvýrazněny červeně (jediná povolená barva).
struct RenameTable: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L("table.title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 8)

            if vm.rows.contains(where: { $0.collides }) {
                Text(L("table.collision"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.danger)
                    .padding(.bottom, 8)
            }

            Grid(horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    headerCell(L("table.order"))
                        .frame(width: 56, alignment: .leading)
                    headerCell(L("table.current"))
                    headerCell(L("table.new"))
                }
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
                    .gridCellColumns(3)
                ForEach(vm.rows) { row in
                    GridRow {
                        Text(String(format: "%02d", row.index + 1))
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(row.collides ? theme.danger : theme.textSecondary)
                            .frame(width: 56, alignment: .leading)
                        Text(row.currentName)
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(row.collides ? theme.danger : theme.textPrimary)
                            .lineLimit(1)
                        Text(row.proposedName)
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(row.collides ? theme.danger : theme.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                    .background(row.collides ? theme.danger.opacity(0.12) : Color.clear)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func headerCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(theme.textSecondary)
            .padding(.bottom, 2)
    }
}
