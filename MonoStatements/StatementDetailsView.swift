//
//  StatementDetailsView.swift
//  MonoStatements
//
//  Created by Oleh Korniienko on 08.05.2021.
//

import Cocoa


class StatementDetailsView: NSView {
    @IBOutlet weak var contentView: NSScrollView!
    @IBOutlet weak var idLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var mccLabel: NSTextField!
    @IBOutlet weak var holdLabel: NSTextField!
    @IBOutlet weak var opAmountLabel: NSTextField!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var commisionLabel: NSTextField!
    @IBOutlet weak var cashbackLabel: NSTextField!
    @IBOutlet weak var balanceLabel: NSTextField!
    @IBOutlet weak var commentLabel: NSTextField!
    @IBOutlet weak var receiptLabel: NSTextField!
    @IBOutlet weak var edrpouLabel: NSTextField!
    @IBOutlet weak var ibanLabel: NSTextField!
    
    var delegate: MonoStatementsTableDelegate? = nil
    var statement: Statement? = nil
    var accountCurrency: CurrencyCode = .UAH
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        let newNib = NSNib(nibNamed: "StatementDetailsView", bundle: Bundle(for: type(of: self)))
        newNib!.instantiate(withOwner: self, topLevelObjects: nil)
        
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.height, .width]
    
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func fillData(statement: Statement, accountCurrency: CurrencyCode) {
        let currecny = statement.currencyCode
        self.accountCurrency = accountCurrency
        self.statement = statement
        let currencyStr = "\(currecny)"
        let accCurrencyStr = "\(accountCurrency)"
        
        idLabel.stringValue = statement.id
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd MMM YYYY"
        timeLabel.stringValue = dateFormatter.string(from: statement.time)
        descriptionLabel.stringValue = statement.description
        mccLabel.stringValue = String(statement.mcc)
        holdLabel.stringValue = statement.hold ? "yes" : "no"
        opAmountLabel.stringValue = "\(convertToMainCurrencyDenomination(amount: statement.operationAmount)) \(currencyStr)"
        amountLabel.stringValue = "\(convertToMainCurrencyDenomination(amount: statement.amount)) \(accCurrencyStr)"
        commisionLabel.stringValue = "\(convertToMainCurrencyDenomination(amount: statement.commissionRate)) \(currencyStr)"
        cashbackLabel.stringValue = "\(convertToMainCurrencyDenomination(amount: statement.cashbackAmount)) \(currencyStr)"
        balanceLabel.stringValue = "\(convertToMainCurrencyDenomination(amount: statement.balance)) \(accCurrencyStr)"
        commentLabel.stringValue = statement.comment ?? ""
        receiptLabel.stringValue = statement.receiptId ?? ""
        edrpouLabel.stringValue = statement.counterEdrpou ?? ""
        ibanLabel.stringValue = statement.counterIban ?? ""
        
        
    }
    
    func convertToMainCurrencyDenomination(amount: LowestCurrencyDenomination) -> Double {
        return Double(amount) / 100
    }
    
    @IBAction func copyAsText(_ sender: Any) {
        var str = ""
        let currecny = statement!.currencyCode
        let currencyStr = "\(currecny)"
        let accCurrencyStr = "\(accountCurrency)"
        
        str += "ID: \(statement!.id)\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd MMM YYYY"
        str += "Time: \(dateFormatter.string(from: statement!.time))\n"
        str += "Description: \(statement!.description)\n"
        str += "MCC: \(statement!.mcc)\n"
        str += "Hold: \(statement!.hold ? "yes" : "no")\n"
        str += "Operation amount: \(convertToMainCurrencyDenomination(amount: statement!.operationAmount)) \(currencyStr)\n"
        str += "In account currency: \(convertToMainCurrencyDenomination(amount: statement!.amount)) \(accCurrencyStr)\n"
        str += "Commision: \(convertToMainCurrencyDenomination(amount: statement!.commissionRate)) \(currencyStr)\n"
        str += "Cashback: \(convertToMainCurrencyDenomination(amount: statement!.cashbackAmount)) \(currencyStr)\n"
        str += "Balance: \(convertToMainCurrencyDenomination(amount: statement!.balance)) \(accCurrencyStr)\n"
        str += "Comment: \(statement!.comment ?? "")\n"
        str += "Receipt ID: \(statement!.receiptId ?? "")\n"
        str += "Agent EDRPOU: \(statement!.counterEdrpou ?? "")\n"
        str += "Agent IBAN: \(statement!.counterIban ?? "")"
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(str, forType: .string)
    }
    
}
