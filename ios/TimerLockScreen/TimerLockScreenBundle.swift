//
//  TimerLockScreenBundle.swift
//  TimerLockScreen
//
//  Created by Mohamed Atef on 25/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct TimerLockScreenBundle: WidgetBundle {
    var body: some Widget {
        TimerLockScreen()
        TimerLockScreenControl()
        TimerLockScreenLiveActivity()
    }
}
