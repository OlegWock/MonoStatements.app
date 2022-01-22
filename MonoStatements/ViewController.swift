//
//  ViewController.swift
//  MonoStatements
//
//  Created by Oleh Korniienko on 02.05.2021.
//

import Cocoa

class ViewController: NSViewController & NSTabViewDelegate & MonoStatementsTableDelegate {

    @IBOutlet weak var apiKeyField: NSTextField!
    @IBOutlet weak var fromDatePicker: NSDatePicker!
    @IBOutlet weak var pullButton: NSButton!
    @IBOutlet weak var tabs: NSTabView!
    @IBOutlet weak var convertToSelect: NSPopUpButton!
    // @IBOutlet weak var statementsTable: NSTableView!
    
    var api: MonoAPI?
    
    var statementsTable: MonoStatementsTable?
    
    var userInfo: UserInfo?
    var statements: [String: [Statement]] = [:]
    var lastStatementsLoadingTime:[String: Date] = [:]
    var loadingController: NSViewController?
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let savedApiKey = UserDefaults.standard.string(forKey: "apiKey") {
            apiKeyField.stringValue = savedApiKey
        }
        
        fromDatePicker.dateValue = Date() - TimeInterval.init(60 * 60 * 24 * 30)
        
        tabs.delegate = self
        
        statementsTable = MonoStatementsTable(frame: NSRect())
        statementsTable!.delegate = self
        
        for currency in [CurrencyCode.USD, .EUR, .RUB, .UAH] {
            convertToSelect.addItem(withTitle: "\(currency)")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateAccountsTabs() {
        DispatchQueue.main.async() {
            let typeMap = [
                AccountType.black: "Black",
                AccountType.white: "White",
                AccountType.platinum: "Platinum",
                AccountType.yellow: "Yellow",
                AccountType.fop: "FOP",
                AccountType.iron: "Iron",
                AccountType.eAid: "eAid"
            ]
            for tab in self.tabs.tabViewItems {
                self.tabs.removeTabViewItem(tab)
            }
            for account in self.userInfo!.accounts {
                let tab = NSTabViewItem(identifier: account.id)
                tab.label = "\(typeMap[account.type]!) \(account.currencyCode)"
                tab.view = self.statementsTable
                self.tabs.addTabViewItem(tab)
            }
        }
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("Selected tab \(String(describing: tabViewItem?.identifier))")
        if tabViewItem?.identifier != nil {
            self.checkAndPullCurrentAccount()
        }
    }
    
    func checkAndPullCurrentAccount() {
        let currentTabId = tabs.selectedTabViewItem?.identifier as! String
        if lastStatementsLoadingTime[currentTabId] == nil {
            lastStatementsLoadingTime[currentTabId] = Date.distantPast
        }
        let fromDate = self.fromDatePicker.dateValue
        if Date().distance(to: lastStatementsLoadingTime[currentTabId]!) < -60 * 10 || self.statements[currentTabId] == nil {
            print("Making request to API")
            showLoading()
            self.api!.getStatements(account: currentTabId, from: fromDate) {(stats: [Statement]?, error: Bool) in
                self.hideLoading()
                if error {
                    self.showError()
                    return
                }
                self.lastStatementsLoadingTime[currentTabId] = Date()
                self.statements[currentTabId] = stats!
                self.updateTable()
                
            }
        } else {
            self.updateTable()
        }
    }
    
    func showLoading() {
        DispatchQueue.main.async() {
            let loadingView = NSView.init(frame: NSMakeRect(0, 0, 60, 60))
            loadingView.wantsLayer = true
            
            let indicator = NSProgressIndicator.init(frame: NSMakeRect(10, 10, 40, 40))
            indicator.isIndeterminate = true
            indicator.style = .spinning
            loadingView.addSubview(indicator)
            self.loadingController = NSViewController.init()
            self.loadingController!.view = loadingView
            self.loadingController!.preferredContentSize = loadingView.frame.size
            self.presentAsSheet(self.loadingController!)
            indicator.startAnimation(nil)
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async() {
            if self.presentedViewControllers?.contains(self.loadingController!) ?? false {
                self.dismiss(self.loadingController!)
            }
        }
    }
    
    func showError(_ text: String) {
        DispatchQueue.main.async() {
            let alert = NSAlert.init()
            alert.messageText = text
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = .critical
            alert.beginSheetModal(for: NSApplication.shared.mainWindow!)
        }
    }
    
    func showError() {
        self.showError("Error happened :(")
    }
    
    func updateTable() {
        DispatchQueue.main.async() {
            if self.userInfo == nil {
                return
            }
            let currentTabId = self.tabs.selectedTabViewItem?.identifier as! String
            let account = self.userInfo!.accounts.first(where: {$0.id == currentTabId})!
            let convertTo = CurrencyStrToCode[self.convertToSelect.selectedItem!.title]!
            self.statementsTable?.displayStatements(stats: self.statements[currentTabId]!, currency: account.currencyCode, convertTo: convertTo)
        }
    }
    
    func convertCurrency(amount: LowestCurrencyDenomination, from: CurrencyCode, to: CurrencyCode) -> LowestCurrencyDenomination {
        if from == to {
            return amount
        }
        return self.api?.convertCurrency(amount: amount, from: from, to: to) ?? amount
    }

    @IBAction func updateConvertTo(_ sender: Any) {
        self.updateTable()
    }
    
    @IBAction func pullData(_ sender: Any) {
        let apiKey = apiKeyField.stringValue
        if apiKey.count == 0 {
            self.showError("Please enter API key")
            return
        }
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        api = MonoAPI(apiKey: apiKey)
        
        showLoading()
        api!.getExchangeRates() {(rates: [ExchangeRate]?, error: Bool) in
            self.api!.getUserInfo() {(info: UserInfo?, error: Bool)  in
                self.hideLoading()
                if error {
                    self.showError()
                    return
                }
                self.userInfo = info!
                self.updateAccountsTabs()
            }
        }
        
    }
    
}

