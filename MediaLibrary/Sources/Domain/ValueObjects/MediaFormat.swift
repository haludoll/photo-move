import Foundation

/// メディアファイルの形式を表現する値オブジェクト
enum MediaFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
}
