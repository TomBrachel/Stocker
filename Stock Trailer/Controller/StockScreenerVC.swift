//
//  StockScreenerVC.swift
//  Stock Trailer
//
//  Created by תום ברכל on /0311/2018.
//  Copyright © 2018 Tom Brachel. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire
import SWXMLHash

class StockScreenerVC: NSViewController {

//MARK: --> Vars
    //IBOutlets
    @IBOutlet weak var statusLbl: NSTextField!
    @IBOutlet weak var priceTxt: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progIndicator: NSProgressIndicator!
    @IBOutlet weak var findStopBtn: NSButton!
    @IBOutlet weak var trendsCheckBtn: NSButton!
    
    
    //Regulars
    
    //Main List of Stocks
    var pennyStocksCompleted = [PennyStock]()
    
    var currentAPI = "https://www.otcmarkets.com/research/stock-screener/api?market=6,5,2,1,-1,10,20,21,22&country=USA&pageSize=20&priceMax=1&priceMin=0.000001"
    var pennyStocksUnCompleted = [PennyStock]()
    var stockList = [String]()
    var timer: Timer?
    
    let yahooURLSByPrice: [Int:String] = [0: "https://finance.yahoo.com/screener/ebf59c3d-f61c-4a84-a696-1ce8a91cf80f", 1:"https://finance.yahoo.com/screener/unsaved/011444de-e1f5-476a-aa11-650247e5845c", 2:"https://finance.yahoo.com/screener/unsaved/0f54e07f-7c18-4d01-b4b1-adcbbb93c4d8", 3: "https://finance.yahoo.com/screener/unsaved/1ce2d621-9fa5-4986-bdeb-a636087d962f", 4: "https://finance.yahoo.com/screener/unsaved/289251b2-edb4-4215-b82d-2d7d77c5aa80", 5: "https://finance.yahoo.com/screener/unsaved/58f96348-8d38-42a1-9e42-d1a91339c8f7", 6: "https://finance.yahoo.com/screener/unsaved/54de6077-b36c-4fef-a0d8-8fbf6bf9df86", 7: "https://finance.yahoo.com/screener/unsaved/64ba080e-b096-4ee1-af14-63e223ec0002", 8: "https://finance.yahoo.com/screener/unsaved/896defbd-cc95-46bf-a8b5-35a8dffdd716", 9: "https://finance.yahoo.com/screener/unsaved/8c94b22d-8f38-46d9-8a00-82f2ab9e24e6", 10: "https://finance.yahoo.com/screener/unsaved/ba7b0dbc-c59e-4262-9f17-a076a83c8f9f"]
    
    
    //viewDidLoad Func
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //table view settings
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        trendsCheckBtn.isHidden = true
        
        
        //double tap setup
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
        statusLbl.stringValue = ""
        statusLbl.textColor = NSColor.black
    }
    
    
    //Passing stockSymbol to StockUpdatesVC when segue
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? StockUpdatesVC {
            vc.symbol = pennyStocksCompleted[tableView.selectedRow].symbol
        }
    }
    
    //open StocksUpdatesVC on proper Stock by doubleClick
    @objc func tableViewDoubleClick(_ sender:AnyObject) {

        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "toStockUpdates"), sender: self)
        
    }
    
    func startFindStockNews() {
        statusLbl.stringValue = "Getting Stock List"
        self.findStopBtn.title = "Stop"
        statusLbl.textColor = NSColor.black
        pennyStocksCompleted.removeAll()
        pennyStocksUnCompleted.removeAll()
        stockList.removeAll()
        trendsCheckBtn.isHidden = true
        self.tableView.reloadData()
        if let maxPrice = Double(priceTxt.stringValue) {
            getOTCStockList(maxPrice: maxPrice, completion: getStocksFromYahoo(maxPrice:setOff:completion:))
        }
        self.view.window?.title = "Stocker - Under \(priceTxt.stringValue)$"
        self.progIndicator.doubleValue = 0.0
    }
    
    func stopFindStockNews() {
        self.statusLbl.stringValue = "Stopped! \(pennyStocksCompleted.count) Stocks Found So Far"
        self.findStopBtn.title = "Find"
        self.trendsCheckBtn.isHidden = false
        stopCompleteStocksTimer()
        
    }
    
    //Find Stocks Btn Pressed - Strat Searching
    @IBAction func findBtnPressed(_ sender: NSButton) {
        
        if findStopBtn.title == "Find" {
            startFindStockNews()
        } else {
            stopFindStockNews()
        }
        
    }
    
    //Pressing Enter on priceTxt - Start Searching
    @IBAction func pressEnterOnPriceTxt(_ sender: NSTextField) {
        
        if findStopBtn.title == "Find" {
            startFindStockNews()
        } else {
            stopFindStockNews()
        }
        
    }
    
    
    //Completion Handler For getStockList, Strat Creating pennyStocks entities
    func finishStockList() {
        print("before set - \(self.stockList.count)")
        self.stockList = Array(Set(self.stockList))
        print("After set - \(self.stockList.count)")
        print("getStockList Compelted! num of Stocks - \(self.stockList.count)")
        self.statusLbl.stringValue = "Stock List Completed! Finding news"
        self.createPennyStocks()
    }
    
    
    //Getting All Stocks From Yahoo
    func getStocksFromYahoo(maxPrice: Double, setOff: Int, completion: @escaping (Bool, Int, Double) -> ()) {
        
        var yahooScreenerURL = ""
        switch Int(maxPrice) {
            case 1: yahooScreenerURL = yahooURLSByPrice[1]!
            case 2: yahooScreenerURL = yahooURLSByPrice[2]!
            case 3: yahooScreenerURL = yahooURLSByPrice[3]!
            case 4: yahooScreenerURL = yahooURLSByPrice[4]!
            case 5: yahooScreenerURL = yahooURLSByPrice[5]!
            case 6: yahooScreenerURL = yahooURLSByPrice[6]!
            case 7: yahooScreenerURL = yahooURLSByPrice[7]!
            case 8: yahooScreenerURL = yahooURLSByPrice[8]!
            case 9: yahooScreenerURL = yahooURLSByPrice[9]!
            case 10: yahooScreenerURL = yahooURLSByPrice[10]!
            
        default:
            yahooScreenerURL = yahooURLSByPrice[10]!
        }
        yahooScreenerURL = yahooURLSByPrice[0]!
        yahooScreenerURL = "\(yahooScreenerURL)?offset=\(setOff)&count=100"
        
        
        if let URL = URL(string: yahooScreenerURL) {
            do {
                let yahooScreenerHtml = try String(contentsOf: URL, encoding: .ascii)
                if yahooScreenerHtml.contains("\"results\":{\"rows\":") {
                    //var stockList = [String]()
                    var stockString = yahooScreenerHtml.components(separatedBy: "\"results\":{\"rows\":")
                    stockString = stockString[1].components(separatedBy: ",\"columns\":[{")
    
                    if let dataFromString = stockString[0].data(using: .utf8, allowLossyConversion: false) {
                        do {
                            let json = try JSON(data: dataFromString)
                            if let stocksInfo = json.array {
                                for stock in stocksInfo {
                                    let symbol = stock["symbol"].stringValue
                                    self.stockList.append(symbol)
                                }
                                completion(true, setOff, maxPrice)
                            }
                        }
                        catch {
                            print("ERROR - Unable to wrap JSON - Yahoo")
                        }
                    }
                    //Bad URL
                } else {
                    print("End Of Yahoo Data")
                    completion(false, setOff, maxPrice)
                }
//
            } catch let error {
                print("Error: \(error)")
                
            }
            
        } else {
            print("Error: \(yahooScreenerURL) doesn't seem to be a valid URL")
            completion(false, setOff, maxPrice)
        }
    }
    
    
    func didFinishGettingStocksFromYahoo(goodPage: Bool, setOff: Int, maxPrice: Double) {
        //print("\(nextPage - 1) pages done, \(pagesLeft) to go")
        
        if goodPage {
            let newSetOff = setOff + 100
            getStocksFromYahoo(maxPrice: maxPrice, setOff: newSetOff, completion: didFinishGettingStocksFromYahoo(goodPage:setOff:maxPrice:))
        } else {
            finishStockList()
        }
    }
    
    
    //Getting StockList From OTC Exchanges & puts them in stockList
    func getOTCStockList(maxPrice: Double, completion: @escaping (Double, Int, @escaping (Bool, Int, Double) -> ()) -> ()) {
        let apiUrl = "https://www.otcmarkets.com/research/stock-screener/api?market=6,5,2,1,-1,10,20,21,22&country=USA&pageSize=10000&priceMax=\(maxPrice)&priceMin=0.000001"
        Alamofire.request(apiUrl).responseJSON
            {
                (response) in
                if response.result.isSuccess {
                    
                    let dataStr = response.result.value! as! String
                    if let dataFromString = dataStr.data(using: .utf8, allowLossyConversion: false) {
                        do {
                        let json = try JSON(data: dataFromString)
                            if let stocks = json["stocks"].array {
                                
                                for stock in stocks {
                                    let symbol = stock["symbol"].stringValue
                                    self.stockList.append(symbol)
                                }
                            }
                            
                            //gotStockList Func
                            completion(maxPrice, 0, self.didFinishGettingStocksFromYahoo(goodPage:setOff:maxPrice:))
                        }
                        catch {
                            print("ERROR - Unable to wrap JSON")
                        }
                    }
                }
        }
    }
    
    func didFinishGettingStocksFromNasdAndNY(pagesLeft: Int, nextPage: Int, maxPrice: Double) {
        print("\(nextPage - 1) pages done, \(pagesLeft) to go")
        if pagesLeft == 0 {
            print("finish all stocks to list")
            finishStockList()
        } else {
            getStockListFromNasdAndNY(pageNumber: nextPage, maxPrice: maxPrice, completion: didFinishGettingStocksFromNasdAndNY(pagesLeft:nextPage:maxPrice:))
        }
    }
    
    func getStockListFromNasdAndNY(pageNumber: Int, maxPrice: Double, completion: @escaping (Int, Int, Double) -> ()) {
        let nasdAndNYURL = "https://api.intrinio.com/securities/search?conditions=close_price~lt~\(maxPrice)&page_number=\(pageNumber)"
        let username = "904e753b8e1fa383efe6949b9b363d16"
        let password = "d98ffdb280bb2da43dca83c59014d1ba"
        Alamofire.request(nasdAndNYURL, parameters: nil)
            .authenticate(user: username, password: password)
            .responseJSON { (response) in
                
                let dataJSON: JSON = JSON(response.result.value!)
                let totalPagesStr = String(describing: dataJSON["total_pages"])
                let totalPages = Int(totalPagesStr) ?? 0
                let currentPageStr = String(describing: dataJSON["current_page"])
                let currentPage = Int(currentPageStr) ?? 0
                
                if let stocks = dataJSON["data"].array {
                    for stock in stocks {
                        let symbol = stock["ticker"].stringValue
                        self.stockList.append(symbol)
                    }
                    let pagesLeft = totalPages - currentPage
                    let nextPage = currentPage + 1
                    completion(pagesLeft, nextPage, maxPrice)
                }
                completion(0, 0, maxPrice)
                
        }
    }
    
    
    
    
    
    
    //Creating pennyStocks & puts them in pennyStocksUnCompleted List
    func createPennyStocks() {
        
        for stockSymbol in self.stockList {
            let pennyStock = PennyStock(symbol: stockSymbol)
            pennyStocksUnCompleted.append(pennyStock)
        }
        //fire updateCompletedStocks every 5 seconds
        startCompleteStocksTimer()
    }
    
    //Fire every 5 seconds By Timer.
    //add to pennyStocksCompleted every stock that has Msg & Price
    func updateCompletedStocks() {
        print("----update table view----")
        for stock in self.pennyStocksUnCompleted {
            if stock.isMsgCompleted && stock.message?.text == "noMessages" {
                removeStockFromPennyStocksUnCompleted(stock: stock, msg: "has no messages")
               
            } else if stock.isMsgCompleted && stock.isPriceCompleted {
                pennyStocksCompleted.append(stock)
                removeStockFromPennyStocksUnCompleted(stock: stock, msg: "added to main storage")
                
            }
        }
        
        let progNumber = 100 - Double(self.pennyStocksUnCompleted.count) / Double(self.stockList.count) * 100
        self.progIndicator.doubleValue = progNumber
        self.statusLbl.stringValue = "\(self.stockList.count - self.pennyStocksUnCompleted.count)\\\(self.stockList.count)"
        
        
        if pennyStocksUnCompleted.count == 0 {
            print("no more stocks - \(pennyStocksCompleted.count) stocks found")
            self.statusLbl.stringValue = "Done! \(pennyStocksCompleted.count) Stocks Found"
            self.findStopBtn.title = "Find"
            self.trendsCheckBtn.isHidden = false
            self.statusLbl.textColor = NSColor(calibratedRed: 55/255, green: 145/255, blue: 64/255, alpha: 1.0)
            stopCompleteStocksTimer()
        }
        self.pennyStocksCompleted.sort(by: { $0.message?.time.compare(($1.message?.time)!) == .orderedDescending})
        self.tableView.reloadData()
    }
    
    //removing from pennyStocksUnCompleted every stock that has been added to pennyStocksCopmleted
    func removeStockFromPennyStocksUnCompleted(stock: PennyStock, msg: String) {
        
        var stockIndex = -1
        for count in 0...self.pennyStocksUnCompleted.count - 1 {
            if stock.symbol == self.pennyStocksUnCompleted[count].symbol {
                stockIndex = count
            }
        }
        if stockIndex != -1 {
            self.pennyStocksUnCompleted.remove(at: stockIndex)
            print("\(stock.symbol) was removed, reason - \(msg)")
        }
    }
    
    func startCompleteStocksTimer() {
        timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateCompletedStocks()
        }
    }
    
    func stopCompleteStocksTimer() {
        timer?.invalidate()
    }
    
    @IBAction func trendChkBtnPressed(_ sender: Any) {
        if trendsCheckBtn.state == .on {
            print("turned on")
            checkForTrends()
        } else {
            print("turned off")
        }
        
    }
    
    
    func checkForTrends() {
        print(self.pennyStocksCompleted.count)
        print(self.pennyStocksCompleted)
        
    }
    
    

}

// MARK: --> TableView Setup

extension StockScreenerVC: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pennyStocksCompleted.count
    }
    
}

//Set TableView Cells
extension StockScreenerVC: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let symbolCell = "SymbolCell"
        static let priceCell = "PriceCell"
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
            text = pennyStocksCompleted[row].symbol
            cellIdentifier = CellIdentifiers.symbolCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = "\(pennyStocksCompleted[row].price ?? 0.0)"
            cellIdentifier = CellIdentifiers.priceCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = pennyStocksCompleted[row].message?.text ?? "no title"
            cellIdentifier = CellIdentifiers.msgCell
        } else if tableColumn == tableView.tableColumns[3] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
            text = dateFormatter.string(from: pennyStocksCompleted[row].message?.time ?? Date())
            cellIdentifier = CellIdentifiers.timeCell
        }
        
        // 3
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.textField?.maximumNumberOfLines = 0
            
            
            return cell
        }
        return nil
    }
    
}







//MARK:-- Extras

//init data for testing
//    func initMsgData() -> [Message] {
//        let currentDateTime = Date()
//        var messages = [Message]()
//
//        messages.append(Message(site: "Yahoo", type: "info", text: "Big Something", link: "none", time: currentDateTime))
//        messages.append(Message(site: "InvestorsHub", type: "Bullish", text: "This sould go up", link: "none", time: currentDateTime))
//        messages.append(Message(site: "StockTwits", type: "Bearish", text: "It's going to crash", link: "none", time: currentDateTime))
//
//        return messages
//    }

//    func initPSData() -> [PennyStock] {
//        var pennyStocks = [PennyStock]()
//
//        pennyStocks.append(PennyStock(symbol: "AAPL", price: 167.3, messages: self.messages))
//        pennyStocks.append(PennyStock(symbol: "GOOG", price: 1044.0, messages: self.messages))
//        pennyStocks.append(PennyStock(symbol: "AMZN", price: 965.8, messages: self.messages))
//
//        return pennyStocks
//    }

