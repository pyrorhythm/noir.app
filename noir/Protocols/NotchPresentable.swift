import SwiftUI

protocol NotchPresentable: NoirWidget {
    associatedtype NotchContent: View
    var notchPriority: NotchPriority { get }
    var notchDuration: TimeInterval { get }
    @ViewBuilder var notchContent: NotchContent { get }
}
