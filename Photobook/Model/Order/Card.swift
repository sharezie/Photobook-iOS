//
//  Card.swift
//  Shopify
//
//  Created by Jaime Landazuri on 12/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Stripe

enum StripeAPIError : Error {
    case error(message: String)
}

struct Card {

    private struct Constants {
        static let stripeEndpoint = "https://api.stripe.com/v1/tokens"
    }
    
    static var currentCard: Card? = nil
    
    var clientId: String? {
        didSet {
            guard let key = clientId else { return }
            Stripe.setDefaultPublishableKey(key)
        }
    }
    
    var number: String
    var numberMasked: String {
        return String(number[number.index(number.endIndex, offsetBy: -5)...]).trimmingCharacters(in: .whitespaces)
    }
    var expireMonth: Int
    var expireYear: Int
    var cvv2: String
    
    init(number: String, expireMonth: Int, expireYear: Int, cvv2: String) {
        self.number = number
        self.expireMonth = expireMonth
        self.expireYear = expireYear
        self.cvv2 = cvv2
    }
    
    
    func authorise(completionHandler:@escaping (Error?, String?) -> ()) {
        let cardParams = STPCardParams()
        cardParams.number = number
        cardParams.expMonth = UInt(expireMonth)
        cardParams.expYear = UInt(expireYear)
        cardParams.cvc = cvv2
        
        STPAPIClient.shared().createToken(withCard: cardParams) { (token, error) in
            if let error = error {
                completionHandler(error, nil)
                return
            }
            completionHandler(nil, token!.tokenId)
        }
    }
}

extension Card {
    
    var cardIcon: UIImage {
        guard let cardType = number.cardType() else {
            return UIImage(namedInPhotobookBundle: "generic-card")!
        }
        
        switch cardType {
        case .amex:
            return UIImage(namedInPhotobookBundle: "amex-logo")!
        case .visa:
            return UIImage(namedInPhotobookBundle: "visa-logo")!
        case .mastercard:
            return UIImage(namedInPhotobookBundle: "mastercard-logo")!
        default:
            return UIImage()
        }
    }
    
    var isAmex: Bool {
        return number.cardType() == .amex
    }
    
}
