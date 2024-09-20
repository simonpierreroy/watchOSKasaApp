//
//  KasaWatchWidgets.swift
//  KasaWatchWidgetExtensionExtension
//
//  Created by Simon-Pierre Roy on 9/20/24.
//  Copyright © 2024 Simon. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct KasaWatchWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        KasaWatchWidgetStatic()
    }
}
