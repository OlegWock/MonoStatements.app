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


class MonoStatementsTable: NSView & NSTableViewDataSource & NSTableViewDelegate {
    
    @IBOutlet var contentView: NSScrollView!
    @IBOutlet weak var table: NSTableView!
    @IBOutlet weak var convertedAmountColumn: NSTableColumn!
    @IBOutlet weak var balanceColumn: NSTableColumn!
    var _delegate: MonoStatementsTableDelegate? = nil
    var delegate: MonoStatementsTableDelegate? {
        get {
            return self._delegate
        }
        set(newDelegate) {
            self._delegate = newDelegate
            self.statementDetails?.delegate = newDelegate
        }
    }
    var statements: [Statement] = []
    var accountCurrency: CurrencyCode = .UAH
    var convertTo: CurrencyCode = .USD
    var popoverController: NSViewController? = nil
    var statementDetails: StatementDetailsView? = nil
    
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
        
        table.target = self
        table.doubleAction = #selector(showStatementPopover)
        
        
        popoverController = NSViewController.init()
        statementDetails = StatementDetailsView(frame: NSRect())
        popoverController!.view = statementDetails!
        popoverController!.preferredContentSize = NSMakeSize(popoverController!.view.frame.size.width,
                                                             popoverController!.view.frame.size.height);
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
    
    @objc func showStatementPopover() {
        let row = table.clickedRow
        if row == -1 {
            return
        }
        let statement = statements[row]
        if let rowView = table.rowView(atRow: row, makeIfNecessary: true) {
            let popover = NSPopover()
            popover.contentViewController = popoverController!
            popover.behavior = .transient
            popover.contentSize = NSSize(width: 355, height: 450)
            statementDetails!.fillData(statement: statement, accountCurrency: accountCurrency)
            popover.show(relativeTo: rowView.bounds, of: rowView, preferredEdge: .minX)
        }
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
