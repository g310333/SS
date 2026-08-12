//
//  SecuritiesSimulationApp.swift
//  SecuritiesSimulation
//
//  Created by Wendy on 2026-08-12.
//

import SwiftUI
import CoreData

@main
struct SecuritiesSimulationApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
