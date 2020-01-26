//
//  StockUpdatesVC.swift
//  Stock Trailer
//
//  Created by תום ברכל on /0208/2018.
//  Copyright © 2018 Tom Brachel. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire

class StockUpdatesVC: NSViewController {

    //IBOutlets
    @IBOutlet weak var stockPriceLbl: NSTextField!
    @IBOutlet weak var stockNameTxt: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet weak var stockNamebtn: NSButton!
    
    //vars
    var stockName = ""
    var symbol: String = ""
    var messages = [Message]()
    var timer: Timer?
    
    //viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        
        stockNamebtn.isHidden = true
        stockNamebtn.isHidden = true
        
        //double tap setup
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))

        initFromAnotherVC()

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if symbol != "" {
            self.view.window?.title = symbol.uppercased()
        } else {
           self.view.window?.title = "Details"
        }
        
    }
    
    //Get called from another VC
    func initFromAnotherVC() {
        if symbol != "" {
            self.stockNameTxt.stringValue = self.symbol
            stockName = stockNameTxt.stringValue
            updateStockData()
            stopTimer()
            startTimer()
        }

    }

    //open proper site by doubleClick
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        
        var site = ""
        if tableView.selectedRow != -1 {
            switch messages[tableView.selectedRow].site {
            case "Yahoo":
                site = "https://finance.yahoo.com/quote/\(stockName)?p=\(stockName)"
            case "InvestorsHub":
                site = getInvestorshubURL(stockName: stockName)
            case "StockTwits":
                site = "https://stocktwits.com/symbol/\(stockName)"
            default:
                site = "https://finance.yahoo.com"
            }

            if let url = URL(string: site), NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")
            } else {
            print("worng url")
            }
        }
    }
    
    //extract url for ivestorshub from stock symbol
    func getInvestorshubURL(stockName: String) -> String {
        
        let googleUrl = "https://www.google.co.il/search?newwindow=1&ei=wrl-WtvXCMH4kwWjopjYDw&q=\(stockName)+investorshub&oq=\(stockName)+investorshub&gs_l=psy-ab.3...15200.15200.0.15394.1.1.0.0.0.0.123.123.0j1.1.0....0...1c.1.64.psy-ab..0.0.0....0.JiKW58AERLc"
        
        guard let myURL = URL(string: googleUrl) else {
            print("Error: \(googleUrl) doesn't seem to be a valid URL")
            return ""
        }
        
        do {
            let myHTMLString = try String(contentsOf: myURL, encoding: .ascii)
            var cutHtml = myHTMLString.components(separatedBy: "</h2>")
            //print(cutHtml[1])
            cutHtml = cutHtml[1].components(separatedBy: "url?q=")
            if cutHtml.count == 1 {
                return ""
            }
            let investorshubURL = cutHtml[1].components(separatedBy: "/&amp")[0]
                return investorshubURL
            
        } catch let error {
            print("Error: \(error)")
        }
        
        return ""
    }


    //update Stock Data on Form
    func updateStockData() {
        
        self.messages.removeAll()
        self.stockNamebtn.title = getStockName(stockSymbol: stockName)
        if !self.stockNamebtn.title.contains("Not Found") {
            getMessagesFromInvestorshub(stockSymbol: stockName)
            getMessagesFromYahoo(stockSymbol: stockName)
            getMessagesFromStockTwits(stockSymbol: stockName)
            self.stockNamebtn.bezelColor = NSColor.blue
            self.view.window?.title = stockName.uppercased()
            
        } else {
            self.stopTimer()
            self.view.window?.title = "Stock Not Found"
        }
        self.stockNamebtn.isHidden = false
        print(self.stockNamebtn.title)
        tableView.reloadData()
    }
    
//MARK: Get Stock Data
    
    //get stock name from stock symbol
    func getStockName(stockSymbol: String) -> String {
        var stockTitle = getStockNameTitleByYahoo(stockSymbol: stockSymbol)
        if stockTitle == "" {
            stockTitle = getStockNameTitleByfinviz(stockSymbol: stockSymbol)
            if stockTitle == "" {
                stockTitle = "\(stockSymbol.uppercased()) - Not Found"
                self.stockPriceLbl.stringValue = ""
            }
        }
        
        return stockTitle
    }

   //btn pressed
    @IBAction func btnPressed(_ sender: Any) {
        if stockNameTxt.stringValue != "" {
            stockName = stockNameTxt.stringValue
            updateStockData()
            stopTimer()
            startTimer()
        }
    }
    
    //enter pressed
    @IBAction func stockTxtPressedEnter(_ sender: Any) {
        if stockNameTxt.stringValue != "" {
            stockName = stockNameTxt.stringValue
            updateStockData()
            stopTimer()
            startTimer()
        }
        
    }
    
    //stock name pressed take to Finviz
    @IBAction func stockNameBtnPressed(_ sender: NSButton) {
        let finvizUrl = "https://finviz.com/quote.ashx?t=\(stockName)"
        if let url = URL(string: finvizUrl), NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")
        } else {
            print("worng url")
        }

    }
    

// MARK: Find Stock Name From Yahoo and then From Finviz
    
    //get from yahoo name of stock company
    func getStockNameTitleByYahoo(stockSymbol: String) -> String {
        
        var stockTitle = ""
        var stockPrice = ""
        
        let yahooUrl = "https://finance.yahoo.com/quote/\(stockName)?p=\(stockName)"
        
        guard let URL = URL(string: yahooUrl) else {
            print("Error: \(yahooUrl) doesn't seem to be a valid URL")
            return stockTitle
        }
        
        do {
            let yahooHtml = try String(contentsOf: URL, encoding: .ascii)
            let yahooHtmlSplitNoResults = yahooHtml.components(separatedBy: "Symbols similar to")
            if yahooHtmlSplitNoResults.count == 3 {
                return stockTitle
            }
            
            //find stock title
            var stockName = yahooHtml.components(separatedBy: "<h1 class")
            if stockName.count > 2 {
                stockName = stockName[2].components(separatedBy: ">")
                stockName = stockName[1].components(separatedBy: "<")
                stockTitle = stockName[0]
            } else {
                return stockTitle
            }
            
            
            //find stock price
            let priceUrl = "https://query1.finance.yahoo.com/v8/finance/chart/\(stockSymbol)?range=1d&includePrePost=false&interval=2m&corsDomain=finance.yahoo.com&.tsrc=finance"
            Alamofire.request(priceUrl).responseJSON
                {
                    response in
                    if response.result.isSuccess {
                        
                        let dataJSON: JSON = JSON(response.result.value!)
                        stockPrice = String(describing: dataJSON["chart"]["result"][0]["meta"]["chartPreviousClose"])
                        self.stockPriceLbl.stringValue = "\(stockPrice)$"
                        
                    }
            }
            return stockTitle
            
            
        } catch let error {
            print("Error: \(error)")
            return stockTitle
        }
    }
    
    //get from finviz name of stock company
    func getStockNameTitleByfinviz(stockSymbol: String) -> String {
        
        let finvizUrl = "https://finviz.com/quote.ashx?t=\(stockSymbol)"
        
        guard let URL = URL(string: finvizUrl) else {
            print("Error: \(finvizUrl) doesn't seem to be a valid URL")
            return ""
        }
        
        do {
            let finvizHtml = try String(contentsOf: URL, encoding: .ascii)
            if finvizHtml.contains("not found") {
                return ""
            }
            var stockName = finvizHtml.components(separatedBy: "<title>")
            //print(cutHtml[1])
            stockName = stockName[1].components(separatedBy: "Stock")
            return stockName[0]
            
        } catch let error {
            print("Error: \(error)")
            return ""
        }
        
    }
}


// MARK: Timer Setup
extension StockUpdatesVC {
    
    
    func startTimer() {
        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateStockData()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
}

// MARK: --> TableView Setup

extension StockUpdatesVC: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return messages.count
    }
    
}

extension StockUpdatesVC: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let siteCell = "SiteCell"
        static let msgCell = "MsgCell"
        static let timeCell = "TimeCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        
        var text: String = ""
        var cellIdentifier: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            text = messages[row].site
            cellIdentifier = CellIdentifiers.siteCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = messages[row].text
            cellIdentifier = CellIdentifiers.msgCell
        } else if tableColumn == tableView.tableColumns[2] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
            text = dateFormatter.string(from: messages[row].time)
            cellIdentifier = CellIdentifiers.timeCell
        }
        
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.textField?.maximumNumberOfLines = 0
            
            if text == "StockTwits" {
                if messages[row].type == "Bullish" {
                    cell.textField?.textColor = NSColor(calibratedRed: 55/255, green: 145/255, blue: 64/255, alpha: 1.0)
                } else if messages[row].type == "Bearish" {
                  cell.textField?.textColor = NSColor.red
                }
            }

            return cell
        }
        return nil
    }
    
}








//extra:

////init data for testing
//func initData() -> [Message] {
//
//    let currentDateTime = Date()
//    let formatter = DateFormatter()
//    formatter.timeStyle = .medium
//    formatter.dateStyle = .medium
//    let strDate = formatter.string(from: currentDateTime)
//
//    var messages = [Message]()
//
//    messages.append(Message(site: "Yahoo", type: "info", text: "Big Something", link: "none", time: strDate))
//    messages.append(Message(site: "InvestorsHub", type: "Bullish", text: "This sould go up", link: "none", time: strDate))
//    messages.append(Message(site: "StockTwits", type: "Bearish", text: "It's going to crash", link: "none", time: strDate))
//
//    return messages
//}





