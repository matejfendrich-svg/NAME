import Foundation

func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

func photoCountText(_ count: Int) -> String {
    switch count {
    case 1:
        return NSLocalizedString("count.one", comment: "")
    case 2...4:
        return String(format: NSLocalizedString("count.few", comment: ""), count)
    default:
        return String(format: NSLocalizedString("count.many", comment: ""), count)
    }
}
