////
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 02/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Stripe

class OrderManager {
    
    private struct Constants {
        static let savedCostKey = "ly.kite.sdk.OrderManager.cost"
        static let savedOrderDetailsKey = "ly.kite.sdk.OrderManager.orderDetails"
        static let savedShippingMethodKey = "ly.kite.sdk.OrderManager.shippingMethod"
        static let savedPaymentTokenKey = "ly.kite.sdk.OrderManager.paymentToken"
    }
    
    // TODO: Get the supported currencies from the server and make sure the currency of the locale is supported. Otherwise fall back to USD, GBP, EUR, first supported, in that order of preference
    let currencyCode = Locale.current.currencyCode ?? "USD" //USD if locale unavailable
    var deliveryDetails: DeliveryDetails?
    var shippingMethod: Int?
    var paymentMethod: PaymentMethod?
    var itemCount: Int = 1
    var promoCode: String?
    var photobookId: String?
    var orderId: String?
    
    var cachedCost: Cost?
    var validCost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    
    func updateCost(forceUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        
        // TODO: REMOVEME. Mock cost & shipping methods
        let lineItem = LineItem(id: 0, name: "Clown Costume 🤡", cost: Decimal(integerLiteral: 10), formattedCost: "$10")
        let shippingMethod = ShippingMethod(id: 1, name: "Fiesta Deliveries 🎉🚚", shippingCostFormatted: "$5", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$15", maxDeliveryTime: 150, minDeliveryTime: 100)
        let shippingMethod2 = ShippingMethod(id: 2, name: "Magic Unicorn ✨🦄✨", shippingCostFormatted: "$5000", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$5010", maxDeliveryTime: 1, minDeliveryTime: 0)
        
        let validPromoCode = "kite"
        let promoDiscount = validPromoCode == promoCode ? "-£5.00" : nil
        var promoCodeInvalidReason:String?
        if promoCode != nil && promoDiscount == nil {
            promoCodeInvalidReason = "Invalid code 🤷"
        }
        
        self.cachedCost = Cost(hash: orderHash, lineItems: [lineItem], shippingMethods: [shippingMethod, shippingMethod2], promoDiscount: promoDiscount, promoCodeInvalidReason: promoCodeInvalidReason)
        if self.shippingMethod == nil { self.shippingMethod = 1 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(nil)
        }
    }
    
    var orderHash: Int {
        
        var stringHash = ""
        if let deliveryDetails = deliveryDetails { stringHash += "ad:\(deliveryDetails.hashValue)," }
        if let promoCode = promoCode { stringHash += "pc:\(promoCode)," }
        if let productName = ProductManager.shared.product?.name { stringHash += "jb:\(productName)," }
        stringHash += "qt:\(ProductManager.shared.productLayouts.count),"
        
        stringHash += "up:("
        for upsell in OrderSummaryManager.shared.selectedUpsellOptions {
            stringHash += "\(upsell.hashValue),"
        }
        stringHash += ")"
        
        return stringHash.hashValue
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == orderHash
    }
    var paymentToken: String?
    
    static let shared = OrderManager()
    
    init() {
        reset()
    }
    
    var orderIsFree: Bool {
        var orderIsFree = false
        if let cost = OrderManager.shared.validCost, let selectedMethod = OrderManager.shared.shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod){
            orderIsFree = shippingMethod.totalCost == 0.0
        }
        
        return orderIsFree
    }
    
    func reset() {
        deliveryDetails = nil
        shippingMethod = nil
        paymentMethod = Stripe.deviceSupportsApplePay() ? .applePay : nil
        itemCount = 1
        promoCode = nil
        cachedCost = nil
        photobookId = nil
        orderId = nil
    }
    
    func saveCheckoutDetails() {
        guard let detailsData = try? PropertyListEncoder().encode(deliveryDetails),
            let cost = cachedCost else { return }
        
        UserDefaults.standard.set(detailsData, forKey: Constants.savedOrderDetailsKey)
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: cost), forKey: Constants.savedCostKey)
        UserDefaults.standard.set(paymentToken, forKey: Constants.savedPaymentTokenKey)
        UserDefaults.standard.set(shippingMethod, forKey: Constants.savedShippingMethodKey)
        UserDefaults.standard.synchronize()
    }
    
    func loadCheckoutDetails() {
        guard let detailsData = UserDefaults.standard.object(forKey: Constants.savedOrderDetailsKey) as? Data,
            let costData = UserDefaults.standard.object(forKey: Constants.savedCostKey) as? Data else { return }
        
        deliveryDetails = try? PropertyListDecoder().decode(DeliveryDetails.self, from: detailsData)
        cachedCost = NSKeyedUnarchiver.unarchiveObject(with: costData) as? Cost
        paymentToken = UserDefaults.standard.string(forKey: Constants.savedPaymentTokenKey)
        shippingMethod = UserDefaults.standard.integer(forKey: Constants.savedShippingMethodKey)
    }
    
    func submitOrder(_ urls:[String], completionHandler: @escaping (_ error: ErrorMessage?) -> Void) {
    
        Analytics.shared.trackAction(.orderSubmitted, [Analytics.PropertyNames.secondsSinceAppOpen: Analytics.shared.secondsSinceAppOpen(),
                                                       Analytics.PropertyNames.secondsInBackground: Int(Analytics.shared.secondsSpentInBackground)
            ])
        
        //TODO: change to accept two pdf urls
        KiteAPIClient.shared.submitOrder(parameters: orderParameters(), completionHandler: { [weak welf = self] orderId, error in
            welf?.orderId = orderId
            completionHandler(error)
        })
    }
    
    private func orderParameters() -> [String: Any] {
        var shippingAddress = deliveryDetails?.address?.jsonRepresentation()
        shippingAddress?["recipient_first_name"] = deliveryDetails?.firstName
        shippingAddress?["recipient_last_name"] = deliveryDetails?.lastName
        shippingAddress?["recipient_name"] = deliveryDetails?.fullName
        
        var parameters = [String: Any]()
        parameters["payment_charge_token"] = paymentToken
        parameters["shipping_address"] = shippingAddress
        parameters["customer_email"] = deliveryDetails?.email
        parameters["customer_phone"] = deliveryDetails?.phone
        parameters["promo_code"] = promoCode
        parameters["shipping_method"] = shippingMethod
        parameters["jobs"] = [[
            "template_id" : ProductManager.shared.product?.productTemplateId ?? "",
            "multiples" : itemCount,
            "assets": [["inside_pdf" : photobookId ?? ""]]
            ]]
        
        return parameters
    }
    
}

