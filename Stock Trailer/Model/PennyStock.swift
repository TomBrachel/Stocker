//
//  PennyStock.swift
//  Stock Trailer
//
//  Created by תום ברכל on /0311/2018.
//  Copyright © 2018 Tom Brachel. All rights reserved.
//

import Foundation
import Cocoa
import Alamofire
import SWXMLHash
import SwiftyJSON

class PennyStock {
    var symbol: String
    var price: Double?
    var message: Message?
    var isMsgCompleted: Bool = false
    var isPriceCompleted: Bool = false
    
    
    
    init(symbol: String) {
        self.symbol = symbol
        getLastMessageFromYahoo(stockSymbol: symbol, completion: gotMessageFromYahooCompleted)
        getStockPriceFromYahoo(stockSymbol: symbol, completion: gotPriceFromYahooCompleted)
    }
    
    
    
    func gotPriceFromYahooCompleted(price: Double) {
        self.price = price
        self.isPriceCompleted = true
        
    }
    
    func getStockPriceFromYahoo(stockSymbol: String, completion: @escaping (Double) -> Void) {
        
        let priceUrl = "https://query1.finance.yahoo.com/v8/finance/chart/\(stockSymbol)?range=1d&includePrePost=false&interval=2m&corsDomain=finance.yahoo.com&.tsrc=finance"
        Alamofire.request(priceUrl).responseJSON
            {
                response in
                if response.result.isSuccess {
                    
                    let dataJSON: JSON = JSON(response.result.value!)
                    let stockPriceStr = String(describing: dataJSON["chart"]["result"][0]["meta"]["chartPreviousClose"])
                    let stockPrice = Double(stockPriceStr) ?? -1.0
                    completion(stockPrice)
                    
                } else {
                    print("Error Alamo")
                }
        }
    }
    
    func gotMessageFromYahooCompleted(message: Message) {
        self.message = message
        self.isMsgCompleted = true
    }
    
    func getLastMessageFromYahoo(stockSymbol: String, completion: @escaping (Message) -> Void) {
        
        let rssYahooUrl = "https://feeds.finance.yahoo.com/rss/2.0/headline?s=\(stockSymbol)&region=US&lang=en-US"
        
        Alamofire.request(rssYahooUrl).responseData
            {
                response in
                if response.result.isSuccess {
                    
                    let xml = SWXMLHash.parse(response.result.value!)
                    //print(xml)
                    let items = xml["rss"]["channel"]["item"].all
                    if items.count == 0 {
                        let message = Message(site: "", type: "", text: "noMessages", link: "", time: Date())
                        completion(message)
                    } else if items[0]["title"].element?.text != nil {
                        let title = items[0]["title"].element!.text
                        let date = self.dateConvertor(dateString: items[0]["pubDate"].element!.text)
                        let message = Message(site: "", type: "", text: title, link: "", time: date)
                        completion(message)
                    }
                    
                }
        }
    }
    
    func dateConvertor(dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let secondDate = dateFormatter.date(from: dateString) {
                return secondDate
            } else {
                print("ERROR: Date conversion failed due to mismatched format.")
            }
        }
        return Date()
    }
}
