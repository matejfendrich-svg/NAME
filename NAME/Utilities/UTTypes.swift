import UniformTypeIdentifiers

extension UTType {
    // Vlastní typ pro interní drag-to-reorder na timeline.
    static let photoItem = UTType("cz.matejfendrich-svg.NAME.photoItem") ?? .data

    // RAW typy deklarované v Info.plist (UTExportedTypeDeclarations) — uživatel zvolil podporu RAW (spec §11, ot. 2).
    static let rawCR2 = UTType("com.matejfendrich-svg.raw.cr2") ?? .data
    static let rawCR3 = UTType("com.matejfendrich-svg.raw.cr3") ?? .data
    static let rawARW = UTType("com.matejfendrich-svg.raw.arw") ?? .data
    static let rawNEF = UTType("com.matejfendrich-svg.raw.nef") ?? .data
    static let rawDNG = UTType("com.matejfendrich-svg.raw.dng") ?? .data
    static let rawORF = UTType("com.matejfendrich-svg.raw.orf") ?? .data
    static let rawRW2 = UTType("com.matejfendrich-svg.raw.rw2") ?? .data
    static let rawRAF = UTType("com.matejfendrich-svg.raw.raf") ?? .data
    static let rawPEF = UTType("com.matejfendrich-svg.raw.pef") ?? .data

    // UTType.webp nemá statický člen ve starších SDK — použijeme deklarovaný identifikátor.
    static let webP = UTType("org.webmproject.webp") ?? .data

    static let supportedImageTypes: [UTType] = [
        .jpeg, .png, .tiff, .heic, .heif, .webP,
        .rawCR2, .rawCR3, .rawARW, .rawNEF, .rawDNG, .rawORF, .rawRW2, .rawRAF, .rawPEF,
    ]

    static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "webp",
        "cr2", "cr3", "arw", "nef", "dng", "orf", "rw2", "raf", "pef",
    ]
}
