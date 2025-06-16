import UIKit
import CleverTapSDK

class CustomAppInboxScreen: UIViewController, CleverTapInboxViewControllerDelegate {
    
    @IBOutlet var tblView: UITableView!
    var eventList: [AppInboxModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadData()
        registerAppInbox()
        initializeAppInbox()
        tblView.register(UINib(nibName: "AppInboxTableViewCell", bundle: nil), forCellReuseIdentifier: "AppInboxTableViewCell")
        
        tblView.tableFooterView = UIView()
    }
    
    func messageDidSelect(_ message: CleverTapInboxMessage, at index: Int32, withButtonIndex buttonIndex: Int32) {
        //  This is called when an inbox message is clicked(tapped or call to action)
    }
}

extension CustomAppInboxScreen {
    
    func loadData() {
        eventList.removeAll()
        eventList.append(AppInboxModel(type: .summary("Open App Inbox")))
        for inboxMessage in CleverTap.sharedInstance()?.getAllInboxMessages() ?? [] {
            let model = AppInboxModel(type: .inbox(inboxMessage))
            eventList.append(model)
        }
        self.tblView.reloadData()
    }
    
    func registerAppInbox() {
        CleverTap.sharedInstance()?.registerInboxUpdatedBlock({
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        })
    }
    
    func initializeAppInbox() {
        CleverTap.sharedInstance()?.initializeInbox(callback: ({ (success) in
            let messageCount = CleverTap.sharedInstance()?.getInboxMessageCount()
            let unreadCount = CleverTap.sharedInstance()?.getInboxMessageUnreadCount()
            print("Inbox Message:\(String(describing: messageCount))/\(String(describing: unreadCount)) unread")
        }))
    }
}
extension CustomAppInboxScreen: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = eventList[indexPath.row]
        
        switch item.type {
        case .summary(let titleString):
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            cell.textLabel?.text = titleString
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
            return cell
            
        case .inbox(let ctInboxMsg):
            let cell: AppInboxTableViewCell = tableView.dequeueReusableCell(withIdentifier: "AppInboxTableViewCell") as! AppInboxTableViewCell
            cell.inboxMessage = ctInboxMsg
            cell.configure()
            cell.onDeleteTapped = { [weak self] inboxMessage in
                guard let self = self else { return }
                self.updateAppInboxMessages(deletedMessage: inboxMessage)
            }
            cell.onMarkAsRead = { [weak self] inboxMessage in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.updateAppInboxMessages(message: inboxMessage)
                }
            }
            return cell
        }
    }
    
    func updateAppInboxMessages(deletedMessage: CleverTapInboxMessage?) {
        for (index, item) in eventList.enumerated() {
            switch item.type {
            case .inbox(let msg) where msg?.messageId == deletedMessage?.messageId:
                eventList.remove(at: index)
                tblView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                return
            default:
                continue
            }
        }
    }
    
    func updateAppInboxMessages(message: CleverTapInboxMessage?) {
        for (index, item) in eventList.enumerated() {
            switch item.type {
            case .inbox(let msg) where msg?.messageId == message?.messageId:
                let updatedMsg = CleverTap.sharedInstance()?.getInboxMessage(forId: msg?.messageId ?? "")
                eventList[index] = .init(type: .inbox(updatedMsg))
                DispatchQueue.main.async {
                    self.tblView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
                return
            default:
                continue
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\(indexPath.row)!")
        let item = eventList[indexPath.row]
        
        switch(item.type) {
        case .summary(_):
            showAppInbox()
        default: break;
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showAppInbox() {
        // config the style of App Inbox Controller
        let style = CleverTapInboxStyleConfig.init()
        style.title = "App Inbox"
        style.navigationTintColor = .black
        
        if let inboxController = CleverTap.sharedInstance()?.newInboxViewController(with: style, andDelegate: self) {
            let navigationController = UINavigationController.init(rootViewController: inboxController)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
}

