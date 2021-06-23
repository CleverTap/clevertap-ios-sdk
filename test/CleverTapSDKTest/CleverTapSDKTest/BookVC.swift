import UIKit
import CleverTapSDK

class BookVC: UIViewController {
    
    @IBOutlet var lblBookName: CustomLabel!
    @IBOutlet var lblBookDesc: CustomLabel!
    @IBOutlet var lblBookPrice: CustomLabel!
    
    var products: NSArray = NSArray()
    var vendors: NSArray = NSArray()
    var paymentModes: NSArray = NSArray()
    
    var p: String = ""
    var v: String = ""
    var m: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadData()
        nextItem()
    }
    
    func loadData() {
        products = ["Sauron's Mask", "Ironman Helmet", "Ironman Body", "Frodo's Ring",
                    "The Elixir of life", "Davy Jone's Heart", "Loki's Sceptre", "Thor's Mallet"]
        vendors = ["ComicCon", "The White House", "The Wizard of Oz", "An Asgardian"]
        paymentModes = ["Debit card", "Credit card", "PayPal", "Bit Coins"]
    }
    
    @IBAction func nextItem() {
        
        p = products[Int(arc4random()) % products.count] as! String
        v = vendors[Int(arc4random()) % vendors.count] as! String
        m = paymentModes[Int(arc4random()) % paymentModes.count] as! String
        
        lblBookName.text = p
        lblBookDesc.text = v
        lblBookPrice.text = m
        
        let props = ["Product Name": p, "Vendor": v]
        CleverTap.sharedInstance()?.recordEvent("Product Viewed", withProps: props)
    }
    
    @IBAction func segmentValueChanged(sender: AnyObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            addToCart()
            break
        case 1:
            purchased()
            break
        case 2:
            rated()
            break
        default:
            break
        }
    }
    
    func addToCart() {
        let props = ["Product Name": p, "Vendor": v] as [String : Any]
        CleverTap.sharedInstance()?.recordEvent("Added To Cart", withProps: props)
    }
    func purchased() {
        let props = ["Product Name": p, "Vendor": v] as Any
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: ["Transaction_id": arc4random() % 10000, "Payment Mode": m, "Amount": 300, "Date": NSDate()], andItems: [props])
    }
    func rated() {
        let props = ["Product Name": p, "Vendor": v, "Rating": arc4random() % 10] as [String : Any]
        CleverTap.sharedInstance()?.recordEvent("Product rated", withProps: props)
    }
    
}
