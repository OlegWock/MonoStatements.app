//
//  MonoStatementsTable.swift
//  MonoStatements
//
//  Created by Oleh Korniienko on 06.05.2021.
//

import Cocoa

protocol MonoStatementsTableDelegate {
    func convertCurrency(amount: LowestCurrencyDenomination, from: CurrencyCode, to: CurrencyCode) -> LowestCurrencyDenomination
}


class MonoStatementsTable: NSView & NSTabViewDelegate & NSTableViewDataSource & NSTableViewDelegate {
    
    @IBOutlet var contentView: NSScrollView!
    @IBOutlet weak var table: NSTableView!
    @IBOutlet weak var convertedAmountColumn: NSTableColumn!
    @IBOutlet weak var balanceColumn: NSTableColumn!
    var delegate: MonoStatementsTableDelegate? = nil
    var statements: [Statement] = []
    var accountCurrency: CurrencyCode = .UAH
    var convertTo: CurrencyCode = .USD
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        let newNib = NSNib(nibNamed: "StatementsTable", bundle: Bundle(for: type(of: self)))
        newNib!.instantiate(withOwner: self, topLevelObjects: nil)
    
        addSubview(contentView)
        table.delegate = self
        table.dataSource = self
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.height, .width]
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func displayStatements(stats: [Statement], currency: CurrencyCode, convertTo: CurrencyCode) {
        self.statements = stats
        self.accountCurrency = currency
        self.convertTo = convertTo
        print("displayStatements originalCurrency: \(currency), convertTo: \(convertTo)")
        convertedAmountColumn.title = "Amount \(convertTo)"
        balanceColumn.title = "Balance \(convertTo)"
        self.table.reloadData()
    }
    
    func convertCurrency(amount: LowestCurrencyDenomination, from: CurrencyCode, to: CurrencyCode) -> LowestCurrencyDenomination {
        if self.delegate != nil {
            return self.delegate!.convertCurrency(amount: amount, from: from, to: to)
        }
        return amount
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.statements.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(22.0)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView: NSTableCellView = NSTableCellView()
        let statement = self.statements[row]
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
                let uahAmount = String(Double(self.convertCurrency(amount: statement.amount, from: accountCurrency, to: .UAH)) / 100.0)
                cellView.textField?.stringValue = uahAmount
                
            case NSUserInterfaceItemIdentifier(rawValue: "amountUsdColumn"):
                cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "amountUsdCellView"),
                                                        owner: self) as! NSTableCellView
                let amountInCents = self.convertCurrency(amount: statement.amount, from: self.accountCurrency, to: self.convertTo)
                let usdAmount = String(Double(amountInCents) / 100.0)
                cellView.textField?.stringValue = usdAmount
                
            case NSUserInterfaceItemIdentifier(rawValue: "balanceColumn"):
                cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "balanceCellView"),
                                                        owner: self) as! NSTableCellView
                let amountInCents = self.convertCurrency(amount: statement.balance, from: self.accountCurrency, to: self.convertTo)
                let usdAmount = String(Double(amountInCents) / 100.0)
                cellView.textField?.stringValue = usdAmount
                
            default:
                break;
        }
    
        return cellView
    }
    
    
}
