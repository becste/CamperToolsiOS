import StoreKit
import Combine

class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var errorMessage: String? = nil
    
    enum PurchaseState {
        case idle
        case purchasing
        case purchased
        case failed(Error)
        case cancelled
    }
    
    private let productIds = ["donationcoffee"] // Corrected Product ID from App Store Connect
    
    @MainActor
    func loadProducts() async {
        errorMessage = nil
        do {
            products = try await Product.products(for: productIds)
            if products.isEmpty {
                errorMessage = "No products found. Check ID."
            }
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    purchaseState = .purchased
                    await transaction.finish()
                case .unverified:
                    purchaseState = .failed(StoreError.verificationFailed)
                }
            case .userCancelled:
                purchaseState = .cancelled
            case .pending:
                purchaseState = .purchasing // Pending approval
            @unknown default:
                purchaseState = .failed(StoreError.unknown)
            }
        } catch {
            purchaseState = .failed(error)
        }
    }
    
    enum StoreError: Error {
        case verificationFailed
        case unknown
    }
}