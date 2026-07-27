#if canImport(ActivityKit)
import ActivityKit
#endif
import UIKit
import CleverTapSDK

// Declared in the app target (which links CleverTapSDK) so the shared
// FoodOrderActivityAttributes.swift — also compiled into the widget extension — does not
// need to import CleverTapSDK. Required for the Push-to-Start flow.
@available(iOS 16.2, *)
extension FoodOrderActivityAttributes: CleverTapLiveActivityAttributes {}

/// Demonstrates the full CleverTap Live Activities SDK integration using a
/// food-order tracking scenario. Tapping each row calls the real SDK API and
/// shows the result in the log view below the table.
@available(iOS 13.0, *)
class LiveActivitiesViewController: UIViewController {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(SubtitleCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private lazy var logTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.backgroundColor = UIColor.systemGray6
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        tv.text = "Tap a row to call the SDK. Output appears here.\n"
        return tv
    }()

    // MARK: - Table model

    private struct Row {
        let title: String
        let subtitle: String?
        let action: () -> Void
        init(_ title: String, subtitle: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.subtitle = subtitle
            self.action = action
        }
    }
    private struct Section {
        let header: String
        let footer: String
        var rows: [Row]
    }
    private var sections: [Section] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Activities"
        view.backgroundColor = .systemBackground
        setupLayout()
        buildSections()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(logTextView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.58),

            logTextView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Section building

    private func buildSections() {
        // ── 1. Push-to-Start token ────────────────────────────────────────────────
        // Activities are started by the CleverTap backend (Push-to-Start); the app does not
        // start them locally. registerPushToStart is called in AppDelegate at launch.
        let ptsSection = Section(
            header: "Push-to-Start Token (iOS 17.2+)",
            footer: "iOS generates a push-to-start token that lets the server launch a Live Activity without the app being open. registerPushToStart is called in AppDelegate at launch.",
            rows: [
                Row("📲 Show Push-to-Start Token",
                    subtitle: "Reads the current PTS token from ActivityKit") { [weak self] in
                    self?.showPushToStartToken()
                }
            ]
        )

        // ── 2. Client-side event APIs (impression & click) ────────────────────────
        let eventsSection = Section(
            header: "Client-side Events (impression / click)",
            footer: "Impression and click are opt-in APIs the app calls when appropriate — e.g. impression when the activity is shown, click from the widget deep-link handler in AppDelegate.",
            rows: [
                Row("👁️ Record Impression",
                    subtitle: "recordLiveActivityImpression(wzrk:) → Notification Viewed") { [weak self] in
                    self?.recordImpression()
                },
                Row("👆 Record Click",
                    subtitle: "recordLiveActivityClicked(wzrk:) → Notification Clicked") { [weak self] in
                    self?.recordClick()
                }
            ]
        )

        sections = [ptsSection, eventsSection]
        tableView.reloadData()
    }

    // MARK: - Client-side event APIs

    private func recordImpression() {
        let wzrk = demoWzrk()
        CleverTap.sharedInstance()?.recordLiveActivityImpression(wzrk: wzrk)
        log("👁️ Recorded impression (Notification Viewed) with wzrk: \(wzrk)")
    }

    private func recordClick() {
        let wzrk = demoWzrk()
        CleverTap.sharedInstance()?.recordLiveActivityClicked(wzrk: wzrk)
        log("👆 Recorded click (Notification Clicked) with wzrk: \(wzrk)")
    }

    /// In production the `wzrk` dictionary comes from the `wzrk` object in the activity payload
    /// injected by the CleverTap backend, e.g.:
    /// `{ "activityId": "<id>", "activityType": 0, "milestoneId": "<id>", "campaignId": 12345 }`
    /// Here we build a representative one for the local demo.
    private func demoWzrk() -> [AnyHashable: Any] {
        return [
            "activityId": "demo-activity",
            "activityType": 0,
            "milestoneId": "orderPacked",
            "campaignId": 12345
        ]
    }

    // MARK: - Push-to-Start token

    private func showPushToStartToken() {
        if #available(iOS 17.2, *) {
            Task {
                // pushToStartTokenUpdates is a continuous async stream; grab the first value.
                var tokenHex = "<not yet available>"
                for await tokenData in Activity<FoodOrderActivityAttributes>.pushToStartTokenUpdates {
                    tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                    break
                }
                log("""
                    📲 Push-to-Start Token
                       \(tokenHex)
                    → Pass this token to your server to start a Live Activity
                       remotely without the app being in the foreground.
                    """)
            }
        } else {
            log("⚠️ Push-to-Start tokens require iOS 17.2+.")
        }
    }

    // MARK: - Log helper

    private func log(_ message: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        DispatchQueue.main.async {
            let prev = self.logTextView.text ?? ""
            self.logTextView.text = "[\(ts)]\n\(message)\n\n" + prev
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

@available(iOS 13.0, *)
extension LiveActivitiesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.subtitle
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].rows[indexPath.row].action()
    }
}

// MARK: - Subtitle cell (UITableViewCell.CellStyle.subtitle without iOS 14 APIs)

private class SubtitleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
