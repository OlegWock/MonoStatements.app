//
//  ViewController.swift
//  MonoStatements
//
//  Created by Oleh Korniienko on 02.05.2021.
//

import Cocoa

class ViewController: NSViewController & NSTableViewDataSource & NSTableViewDelegate {

    @IBOutlet weak var apiKeyField: NSTextField!
    @IBOutlet weak var fromDatePicker: NSDatePicker!
    @IBOutlet weak var pullButton: NSButton!
    @IBOutlet weak var statementsTable: NSTableView!
    
    var api: MonoAPI?
    
    var statements: [Statement] = []
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        statementsTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let savedApiKey = UserDefaults.standard.string(forKey: "apiKey") {
            apiKeyField.stringValue = savedApiKey
        }
        
        fromDatePicker.dateValue = Date() - TimeInterval.init(60 * 60 * 24 * 30)
        
        statementsTable.delegate = self
        statementsTable.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return statements.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let statement = self.statements[row]
        var cellView: NSTableCellView = NSTableCellView()
        switch tableColumn!.identifier {
        case NSUserInterfaceItemIdentifier(rawValue: "dateColumn"):
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dateCellView"),
                                                      owner: self) as! NSTableCellView
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm dd MMM"
            cellView.textField?.stringValue = dateFormatter.string(from: statement.time)
            
        case NSUserInterfaceItemIdentifier(rawValue: "descriptionColumn"):
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "descriptionCellView"),
                                                      owner: self) as! NSTableCellView
            cellView.textField?.stringValue = statement.description
            
        case NSUserInterfaceItemIdentifier(rawValue: "amountUahColumn"):
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "amountUahCellView"),
                                                      owner: self) as! NSTableCellView
            let uahAmount = String(Double(statement.amount) / 100.0)
            cellView.textField?.stringValue = uahAmount
            
        case NSUserInterfaceItemIdentifier(rawValue: "amountUsdColumn"):
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "amountUsdCellView"),
                                                      owner: self) as! NSTableCellView
            let amountInCents = self.api!.convertCurrency(amount: statement.amount, from: .UAH, to: .USD)
            let usdAmount = String(Double(amountInCents) / 100.0)
            cellView.textField?.stringValue = usdAmount
            
        case NSUserInterfaceItemIdentifier(rawValue: "balanceColumn"):
            cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "balanceCellView"),
                                                      owner: self) as! NSTableCellView
            let amountInCents = self.api!.convertCurrency(amount: statement.balance, from: .UAH, to: .USD)
            let usdAmount = String(Double(amountInCents) / 100.0)
            cellView.textField?.stringValue = usdAmount
            
        default:
            break;
        }
        
        return cellView
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
            self.statementsTable.reloadData()
        }
    }

    @IBAction func pullData(_ sender: Any) {
        let apiKey = apiKeyField.stringValue
        if apiKey.count == 0 {
            self.showError("Please enter API key")
            return
        }
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        api = MonoAPI(apiKey: apiKey)
        
        let loadingView = NSView.init(frame: NSMakeRect(0, 0, 60, 60))
        loadingView.wantsLayer = true
        
        let indicator = NSProgressIndicator.init(frame: NSMakeRect(10, 10, 40, 40))
        indicator.isIndeterminate = true
        indicator.style = .spinning
        loadingView.addSubview(indicator)
        let loadingController = NSViewController.init()
        loadingController.view = loadingView
        self.presentAsSheet(loadingController)
        indicator.startAnimation(nil)
        
        let fromDate = self.fromDatePicker.dateValue
        
        api!.getExchangeRates() {(rates: [ExchangeRate]?, error: Bool) in
            self.api!.getStatements(account: "0", from: fromDate) {(stats: [Statement]?, error: Bool) in
                DispatchQueue.main.async() {
                    self.dismiss(loadingController)
                }
                
                if !error {
                    self.statements = stats!
                    self.updateTable()
                } else {
                    self.showError()
                }
            }
        }
        
    }
    
}

