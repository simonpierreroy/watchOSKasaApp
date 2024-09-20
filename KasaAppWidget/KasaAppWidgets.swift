//
//  KasaAppWidget.swift
//  KasaAppWidget
//
//  Created by Simon-Pierre Roy on 10/3/20.
//  Copyright © 2020 Simon. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct KasaAppWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        KasaAppWidgetWithAppIntent()
        KasaAppWidgetStatic()
        KasaAppStaticControl()
        KasaAppWithAppIntentControl()
    }
}
