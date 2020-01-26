//
//  InvestorshubMessagesExtMainVC.swift
//  Stock Trailer
//
//  Created by תום ברכל on /0215/2018.
//  Copyright © 2018 Tom Brachel. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import SWXMLHash


extension StockUpdatesVC {
    
    func getMessagesFromInvestorshub(stockSymbol: String) {
        
        let investorshubUrl = getInvestorshubURL(stockName: stockSymbol)
        let stockNum = investorshubUrl.components(separatedBy: "-")
        let rssInvestorshubUrl = "https://investorshub.advfn.com/boards/rss.aspx?board_id=\(stockNum[stockNum.count - 1])"
        
        Alamofire.request(rssInvestorshubUrl).responseData
                {
                    response in
                    if response.result.isSuccess {
                        
                        let xml = SWXMLHash.parse(response.result.value!)
                        
                        for elem in xml["rss"]["channel"]["item"].all {
                            
                            var title = elem["title"].element!.text
                            title = title.components(separatedBy: ":")[1]
                            let link = elem["link"].element!.text
                            let date = self.dateConvertor(dateString: elem["pubDate"].element!.text)
                            
                            let message = Message(site: "InvestorsHub", type: "", text: title, link: link, time: date)
                            self.self.messages.append(message)
                            self.messages.sort(by: { $0.time.compare($1.time) == .orderedDescending})
                            self.tableView.reloadData()
                        }
                        
                    }
            }
        
    }
    
    func getMessagesFromYahoo(stockSymbol: String) {
        
        let rssYahooUrl = "http://finance.yahoo.com/rss/headline?s=\(stockSymbol)"
        
        Alamofire.request(rssYahooUrl).responseData
            {
                response in
                if response.result.isSuccess {
                    
                    let xml = SWXMLHash.parse(response.result.value!)
                    
                    for elem in xml["rss"]["channel"]["item"].all {
                        
                        let title = elem["title"].element!.text
                        let link = elem["link"].element!.text
                        let date = self.dateConvertor(dateString: elem["pubDate"].element!.text)
                        
                        let message = Message(site: "Yahoo", type: "", text: title, link: link, time: date)
                        self.self.messages.append(message)
                        self.messages.sort(by: { $0.time.compare($1.time) == .orderedDescending})
                        self.tableView.reloadData()
                    }
                    
                    
                }
        }
        
    }
    
    func getMessagesFromStockTwits(stockSymbol: String) {
        
        let stockTwitsJson = "https://api.stocktwits.com/api/2/streams/symbol/\(stockSymbol.uppercased()).json?filter=top&max"
        let stockTwitsUrl = "https://stocktwits.com/symbol/\(stockSymbol.uppercased())"
        
        Alamofire.request(stockTwitsJson).responseJSON
                {
                    response in
                    if response.result.isSuccess {
                        let dataJSON: JSON = JSON(response.result.value!)
//                        print(dataJSON)
//                        print("============")
//                        print(dataJSON.rawValue)
                        if let stockTwitsMessages = dataJSON["messages"].array {
                           
                            for msg in stockTwitsMessages {
                                var title = msg["body"].stringValue
                                title = title.html2String
                                let link = stockTwitsUrl
                                let date = self.dateConvertor(dateString: msg["created_at"].stringValue)
                                let type = msg["entities"]["sentiment"]["basic"].stringValue
                                
                                let message = Message(site: "StockTwits", type: type, text: title, link: link, time: date)
                                self.self.messages.append(message)
                                self.messages.sort(by: { $0.time.compare($1.time) == .orderedDescending})
                                self.tableView.reloadData()
                        }
                        
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


extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
