import Foundation

/// Photo library access permission status
package enum PhotoLibraryPermissionStatus {
    /// User has granted access to the entire photo library
    case authorized

    /// User has granted limited access to the photo library
    case limited

    /// User has denied access to the photo library
    case denied

    /// Access is restricted (parental controls, etc.)
    case restricted

    /// Permission status has not been determined yet
    case notDetermined
}
