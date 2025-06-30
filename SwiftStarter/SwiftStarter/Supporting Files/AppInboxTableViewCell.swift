import UIKit
import CleverTapSDK

enum AppInboxCellType {
    case inbox(CleverTapInboxMessage?)
    case summary(String)
}

struct AppInboxModel {
    var type: AppInboxCellType
}

class AppInboxTableViewCell: UITableViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var isRead: UILabel!
    var inboxMessage: CleverTapInboxMessage?
    var onDeleteTapped: ((CleverTapInboxMessage?) -> Void)?
    var onMarkAsRead: ((CleverTapInboxMessage?) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure() {
        title.text = "Title: \(inboxMessage?.content?.first?.title ?? "")"
        message.text = "Message: \(inboxMessage?.content?.first?.message ?? "")"
        isRead.text = "Read: \(inboxMessage?.isRead.description ?? "false")"
    }
    
    @IBAction func actionClicked(_ sender: Any) {
        CleverTap.sharedInstance()?.recordInboxNotificationClickedEvent(forID: inboxMessage?.messageId ?? "")
    }
    @IBAction func actionViewed(_ sender: Any) {
        CleverTap.sharedInstance()?.recordInboxNotificationViewedEvent(forID: inboxMessage?.messageId ?? "")
    }
    
    @IBAction func actionMarkAsRead(_ sender: Any) {
        CleverTap.sharedInstance()?.markReadInboxMessage(forID: inboxMessage?.messageId ?? "")
        onMarkAsRead?(inboxMessage)
    }
    
    @IBAction func actionDelete(_ sender: Any) {
        CleverTap.sharedInstance()?.deleteInboxMessage(forID: inboxMessage?.messageId ?? "")
        onDeleteTapped?(inboxMessage) 
    }
}
