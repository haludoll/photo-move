import Foundation

/// メディアファイルの形式を表現する値オブジェクト
public enum MediaFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
}
