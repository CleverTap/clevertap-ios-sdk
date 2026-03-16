#if canImport(ActivityKit)
import ActivityKit
#endif
import UIKit
import CleverTapSDK

/// Demonstrates the full CleverTap Live Activities SDK integration using a
/// food-order tracking scenario. Tapping each row calls the real SDK API and
/// shows the result in the log view below the table.
@available(iOS 13.0, *)
class LiveActivitiesViewController: UIViewController {

    // MARK: - Active activity tracking

    /// ID of the currently running food-order Live Activity (if any).
    private var currentActivityID: String?

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
        // ── 1. Local flow: start ──────────────────────────────────────────────────
        let localSection = Section(
            header: "Local Flow — Start & Manage Activity",
            footer: "Starts a food-order Live Activity, registers the push token with CleverTap, then lets you simulate order progression.",
            rows: [
                Row("🚀 Start Food Order Activity",
                    subtitle: "Activity.request + CT launchActivity") { [weak self] in
                    self?.startFoodOrderActivity()
                },
                Row("🔥 Update: Preparing",
                    subtitle: "Activity.update → step 1") { [weak self] in
                    self?.updateActivity(step: 1, status: "Chef is preparing your order 🍕")
                },
                Row("🚴 Update: Out for Delivery",
                    subtitle: "Activity.update → step 2") { [weak self] in
                    self?.updateActivity(step: 2, status: "Your order is on its way! 🛵")
                },
                Row("🏠 End: Delivered",
                    subtitle: "Activity.end → CT signals backend") { [weak self] in
                    self?.endActivity()
                }
            ]
        )

        // ── 2. Push-to-Start token ────────────────────────────────────────────────
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

        sections = [localSection, ptsSection]
        tableView.reloadData()
    }

    // MARK: - Local Flow: start

    private func startFoodOrderActivity() {
        if #available(iOS 16.2, *) {
            let orderId = "ORD-\(Int.random(in: 10000...99999))"
            let attributes = FoodOrderActivityAttributes(
                restaurantName: "Pizza Palace",
                orderSummary: "2× Margherita, 1× Garlic Bread",
                orderId: orderId
            )
            let initialState = FoodOrderActivityAttributes.ContentState(
                status: "Order confirmed! Getting things ready… ✅",
                estimatedDelivery: Date().addingTimeInterval(30 * 60),
                progressStep: 0
            )

            Task {
                do {
                    let content = ActivityContent(state: initialState, staleDate: nil)
                    let activity = try Activity<FoodOrderActivityAttributes>.request(
                        attributes: attributes,
                        content: content,
                        pushType: .token
                    )

                    // Store the activity ID so we can update / end it later
                    await MainActor.run { self.currentActivityID = activity.id }

                    // ── CleverTap: register token with backend ────────────────────
                    let tag = "food-order-\(orderId)"
                    await MainActor.run {
                        CleverTap.sharedInstance()?.launchActivity(tag, activity: activity)
                    }

                    log("""
                        ✅ Food Order Live Activity started
                           Activity ID : \(activity.id)
                           CT Tag      : \(tag)
                           Restaurant  : \(attributes.restaurantName)
                           Order       : \(attributes.orderSummary)
                        → CT SDK is now monitoring pushTokenUpdates and activityStateUpdates.
                        """)
                } catch {
                    log("❌ Failed to start activity: \(error.localizedDescription)")
                }
            }
        } else {
            log("⚠️ Live Activities require iOS 16.2+.")
        }
    }

    // MARK: - Local Flow: update

    private func updateActivity(step: Int, status: String) {
        if #available(iOS 16.2, *) {
            guard let id = currentActivityID else {
                log("⚠️ No active activity. Tap 'Start Food Order Activity' first.")
                return
            }
            guard let activity = Activity<FoodOrderActivityAttributes>.activities.first(where: { $0.id == id }) else {
                log("⚠️ Activity \(id) is no longer running.")
                currentActivityID = nil
                return
            }

            let newState = FoodOrderActivityAttributes.ContentState(
                status: status,
                estimatedDelivery: Date().addingTimeInterval(Double(max(0, 3 - step)) * 10 * 60),
                progressStep: step
            )

            Task {
                await activity.update(ActivityContent(state: newState, staleDate: nil))
                log("""
                    ✅ Activity updated
                       Status : \(status)
                       Step   : \(step)/3
                    """)
            }
        } else {
            log("⚠️ Live Activities require iOS 16.2+.")
        }
    }

    // MARK: - Local Flow: end

    private func endActivity() {
        if #available(iOS 16.2, *) {
            guard let id = currentActivityID else {
                log("⚠️ No active activity to end.")
                return
            }
            guard let activity = Activity<FoodOrderActivityAttributes>.activities.first(where: { $0.id == id }) else {
                log("⚠️ Activity \(id) is no longer running.")
                currentActivityID = nil
                return
            }

            let finalState = FoodOrderActivityAttributes.ContentState(
                status: "Order delivered! Enjoy your meal 🎉",
                estimatedDelivery: Date(),
                progressStep: 3
            )

            Task {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(5))
                )
                await MainActor.run { self.currentActivityID = nil }
                log("""
                    ✅ Activity ended
                    → CT SDK detected .ended state and sent:
                       { action: "remove", push_token_tag: "<tag>", type: "live_activity" }
                    """)
            }
        } else {
            log("⚠️ Live Activities require iOS 16.2+.")
        }
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
