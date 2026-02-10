//
//  CamperToolsApp.swift
//  CamperTools
//
//  Created by Stephan Becker on 1/31/26.
//

import SwiftUI
import StoreKit

@main
struct CamperToolsApp: App {
    
    init() {
        // Listen for transaction updates (e.g. if a purchase completes in the background)
        Task {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // For a donation/consumable, we just acknowledge and finish it
                    await transaction.finish()
                    print("Transaction finished: \(transaction.productID)")
                case .unverified:
                    // Ignore unverified transactions
                    break
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}