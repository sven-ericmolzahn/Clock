//
//  ClockApp.swift
//  Clock
//
//  Created by Sven-Eric Molzahn on 14.02.26.
//

import SwiftUI
import CoreData

@main
struct ClockApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
