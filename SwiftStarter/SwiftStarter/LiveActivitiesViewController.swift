#if canImport(ActivityKit)
import ActivityKit
#endif
import UIKit
import CleverTapSDK

// NOTE: No CleverTap protocol conformance is needed. The SDK reads the `wzrk` object from the
// activity's attributes + content-state generically (via Codable), so the shared
// FoodOrderActivityAttributes.swift stays free of any CleverTapSDK import (the widget compiles it too).

/// Demonstrates the CleverTap Live Activities client-side event APIs.
///
/// The table lists every **running** Live Activity, one cell per activity. Each cell has two
/// buttons — **Impression** and **Clicked** — that call the public SDK APIs with that activity's
/// real, backend-injected `wzrk` fields (so each call is bound to a specific activity; no guessing).
/// A Push-to-Start token row and a log view are shown for convenience.
@available(iOS 13.0, *)
class LiveActivitiesViewController: UIViewController {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 120
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "basic")
        tv.register(ActivityButtonsCell.self, forCellReuseIdentifier: ActivityButtonsCell.reuseId)
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
        tv.text = "Tap Impression / Clicked on an activity to call the SDK. Output appears here.\n"
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return rc
    }()

    // MARK: - Model

    /// One entry per running Live Activity. Holds the real `wzrk` extracted from the activity.
    private struct ActivityItem {
        let liveActivityId: String
        let title: String                 // wzrk_activityId (falls back to orderId)
        let detail: String                // a compact summary of the wzrk fields
        let wzrk: [AnyHashable: Any]      // the real, backend-injected wzrk for THIS activity
    }
    private var activities: [ActivityItem] = []

    private enum Section: Int, CaseIterable {
        case pushToStart = 0
        case activities = 1
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Activities"
        view.backgroundColor = .systemBackground
        setupLayout()
        tableView.refreshControl = refreshControl
        reloadActivities()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActivities()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(logTextView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.62),

            logTextView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    @objc private func pullToRefresh() {
        reloadActivities()
        refreshControl.endRefreshing()
    }

    // MARK: - Load running activities

    /// Rebuilds the list of running activities and extracts each one's real `wzrk`.
    private func reloadActivities() {
        var items: [ActivityItem] = []
        if #available(iOS 16.2, *) {
            for activity in Activity<FoodOrderActivityAttributes>.activities {
                var wzrk = Self.wzrk(from: activity)
                // Stamp the recording instance's account so multi-instance validation passes
                // (the backend sets this in production).
                if wzrk["wzrk_acct_id"] == nil, let acct = CleverTap.sharedInstance()?.config.accountId {
                    wzrk["wzrk_acct_id"] = acct
                }
                let title = activity.attributes.wzrk?.wzrk_activityId ?? activity.attributes.orderId
                items.append(ActivityItem(liveActivityId: activity.id,
                                          title: title,
                                          detail: Self.summary(of: wzrk),
                                          wzrk: wzrk))
            }
        }
        activities = items
        tableView.reloadData()
    }

    private var activitiesEmptyMessage: String {
        if #available(iOS 16.2, *) {
            return "No active Live Activities. Start one from the CleverTap backend, then pull to refresh."
        } else {
            return "Live Activities require iOS 16.2+."
        }
    }

    // MARK: - Client-side event APIs (public, wzrk-based)

    private func recordImpression(for item: ActivityItem) {
        CleverTap.sharedInstance()?.recordLiveActivityImpression(wzrk: item.wzrk)
        log("👁️ Impression (Notification Viewed) for '\(item.title)'\n   wzrk: \(item.wzrk)")
    }

    private func recordClick(for item: ActivityItem) {
        CleverTap.sharedInstance()?.recordLiveActivityClicked(wzrk: item.wzrk)
        log("👆 Click (Notification Clicked) for '\(item.title)'\n   wzrk: \(item.wzrk)")
    }

    // MARK: - Push-to-Start token

    private func showPushToStartToken() {
        if #available(iOS 17.2, *) {
            Task {
                var tokenHex = "<not yet available>"
                for await tokenData in Activity<FoodOrderActivityAttributes>.pushToStartTokenUpdates {
                    tokenHex = tokenData.map { String(format: "%02x", $0) }.joined()
                    break
                }
                log("📲 Push-to-Start Token\n   \(tokenHex)")
            }
        } else {
            log("⚠️ Push-to-Start tokens require iOS 17.2+.")
        }
    }

    // MARK: - Helpers

    /// Extracts the backend-injected `wzrk` from a running activity (attributes + current
    /// content-state) into a dictionary — the same fields the SDK reads internally.
    @available(iOS 16.2, *)
    private static func wzrk(from activity: Activity<FoodOrderActivityAttributes>) -> [AnyHashable: Any] {
        var w: [AnyHashable: Any] = [:]
        let a = activity.attributes.wzrk
        if let v = a?.wzrk_activityId { w["wzrk_activityId"] = v }
        if let v = a?.wzrk_activityType { w["wzrk_activityType"] = v }
        if let v = a?.wzrk_id { w["wzrk_id"] = v }
        if let v = a?.wzrk_acct_id { w["wzrk_acct_id"] = v }
        if let v = a?.wzrk_rnv { w["wzrk_rnv"] = v }
        let s = activity.content.state
        if let v = s.wzrk_milestoneId { w["wzrk_milestoneId"] = v }
        if let v = s.wzrk_pid { w["wzrk_pid"] = v }
        return w
    }

    private static func summary(of wzrk: [AnyHashable: Any]) -> String {
        let order = ["wzrk_activityId", "wzrk_activityType", "wzrk_id", "wzrk_acct_id",
                     "wzrk_milestoneId", "wzrk_pid", "wzrk_rnv"]
        return order.compactMap { key in
            wzrk[key].map { "\(key): \($0)" }
        }.joined(separator: "\n")
    }

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

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .pushToStart: return 1
        case .activities:  return activities.isEmpty ? 1 : activities.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .pushToStart: return "Push-to-Start Token (iOS 17.2+)"
        case .activities:  return "Active Live Activities"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .pushToStart:
            return "Activities are started by the CleverTap backend. registerPushToStart is called in AppDelegate at launch."
        case .activities:
            return "One row per running activity. Each button calls the public API with that activity's real wzrk: recordLiveActivityImpression(wzrk:) / recordLiveActivityClicked(wzrk:)."
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .pushToStart:
            let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
            cell.textLabel?.text = "📲 Show Push-to-Start Token"
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell

        case .activities:
            guard !activities.isEmpty else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
                cell.textLabel?.text = activitiesEmptyMessage
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.textColor = .secondaryLabel
                cell.accessoryType = .none
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: ActivityButtonsCell.reuseId, for: indexPath) as! ActivityButtonsCell
            let item = activities[indexPath.row]
            cell.configure(title: item.title, detail: item.detail)
            cell.onImpression = { [weak self] in self?.recordImpression(for: item) }
            cell.onClick = { [weak self] in self?.recordClick(for: item) }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Section(rawValue: indexPath.section) == .pushToStart {
            showPushToStartToken()
        }
    }
}

// MARK: - Activity cell (title + wzrk summary + Impression / Clicked buttons)

@available(iOS 13.0, *)
private final class ActivityButtonsCell: UITableViewCell {

    static let reuseId = "ActivityButtonsCell"

    var onImpression: (() -> Void)?
    var onClick: (() -> Void)?

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let impressionButton = UIButton(type: .system)
    private let clickButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.numberOfLines = 0

        detailLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0

        configure(button: impressionButton, title: "👁️ Impression")
        configure(button: clickButton, title: "👆 Clicked")
        impressionButton.addTarget(self, action: #selector(impressionTapped), for: .touchUpInside)
        clickButton.addTarget(self, action: #selector(clickTapped), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [impressionButton, clickButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 10

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, buttons])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, detail: String) {
        titleLabel.text = "Activity: \(title)"
        detailLabel.text = detail
    }

    private func configure(button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
    }

    @objc private func impressionTapped() { onImpression?() }
    @objc private func clickTapped() { onClick?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onImpression = nil
        onClick = nil
    }
}
