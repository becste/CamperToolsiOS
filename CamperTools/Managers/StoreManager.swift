import StoreKit
import Combine

class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    
    enum PurchaseState {
        case idle
        case purchasing
        case purchased
        case failed(Error)
        case cancelled
    }
    
    private let productIds = ["com.campertools.donationcoffee"] // Replace with your actual Product ID
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
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
