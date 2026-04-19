//
//  NotchPresentable.swift
//  noir
//
//  Created by Claude on 2026-04-19.
//

import SwiftUI

protocol NotchPresentable: NoirWidget {
    associatedtype NotchContent: View
    var notchPriority: NotchPriority { get }
    var notchDuration: TimeInterval { get }
    @ViewBuilder var notchContent: NotchContent { get }
}