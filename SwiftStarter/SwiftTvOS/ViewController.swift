import UIKit
import CleverTapSDK

@available(tvOS 13.0, *)
final class ViewController: UIViewController {

    private let sectionColors: [UIColor] = [
        UIColor(red: 0.15, green: 0.40, blue: 0.80, alpha: 1.0),
        UIColor(red: 0.60, green: 0.20, blue: 0.70, alpha: 1.0),
        UIColor(red: 0.13, green: 0.55, blue: 0.45, alpha: 1.0),
        UIColor(red: 0.75, green: 0.35, blue: 0.10, alpha: 1.0)
    ]
    
    private lazy var sections: [Section] = [
        Section(title: "User Actions", items: [
            CardItem(title: "User Login",    action: #selector(userLogin)),
            CardItem(title: "Push Profile",  action: #selector(pushProfile))
        ]),
        Section(title: "Event Tracking", items: [
            CardItem(title: "Record Event",                action: #selector(recordEvent)),
            CardItem(title: "Record Product Viewed Event", action: #selector(recordProductViewedEvent)),
            CardItem(title: "Record Charged Event",        action: #selector(recordChargedEvent)),
            CardItem(title: "Record Custom Event",         action: #selector(recordCustomEvent))
        ]),
        Section(title: "App Inbox", items: [
            CardItem(title: "Show Inbox",   action: #selector(showInbox)),
        ]),
        Section(title: "In-App Notifications", items: [
            CardItem(title: "Trigger In-App", action: #selector(triggerAlertInApp))
        ])
    ]
    private var collectionView: UICollectionView!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        setupCollectionView()
    }

    // MARK: Collection View Setup

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.clipsToBounds = false

        collectionView.register(CardCell.self, forCellWithReuseIdentifier: CardCell.reuseID)
        collectionView.register(
            SectionHeader.self,
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
            withReuseIdentifier: SectionHeader.reuseID
        )

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Compositional Layout

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in

            // Item: fixed-size card
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(340),
                heightDimension: .absolute(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            // Group: horizontal row containing the items
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(340),
                heightDimension: .absolute(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section: horizontal scrolling
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 30, trailing: 0)
            section.interGroupSpacing = 12

            // Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionElementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }

    // MARK: - Stub Methods (Replace with SDK calls)

    @objc private func userLogin() {
        let profile: Dictionary<String, AnyObject> = [
            "Name": "Jack Montana" as AnyObject,
            "Email": "jack.montana@gmail.com" as AnyObject,
              "Identity": 61026032 as AnyObject,
        ]
        CleverTap.sharedInstance()?.onUserLogin(profile)
    }

    @objc private func pushProfile() {
        let dob = NSDateComponents()
        dob.day = 24
        dob.month = 5
        dob.year = 1992
        let d = NSCalendar.current.date(from: dob as DateComponents)
        let profile: Dictionary<String, AnyObject> = [
            "Name": "Jack Montana" as AnyObject,
            "Identity": 61026032 as AnyObject,
            "Email": "jack@gmail.com" as AnyObject,
            "Phone": "+14155551234" as AnyObject,
            "Gender": "M" as AnyObject,
            "Employed": "Y" as AnyObject,
            "Education": "Graduate" as AnyObject,
            "Married": "Y" as AnyObject,
            "DOB": d! as AnyObject,
            "Age": 26 as AnyObject,
            "Tz":"Asia/Kolkata" as AnyObject
            ]
        CleverTap.sharedInstance()?.profilePush(profile)
    }

    @objc private func recordEvent() {
        CleverTap.sharedInstance()?.recordEvent("Product viewed")
    }

    @objc private func recordProductViewedEvent() {
        
        let props = [
                    "Product name": "Casio Chronograph Watch",
                    "Category": "Mens Accessories",
                    "Price": 59.99,
                    "Date": NSDate()
                ] as [String : Any]

        CleverTap.sharedInstance()?.recordEvent("Product viewed", withProps: props)
    }

    @objc private func recordChargedEvent() {
        let chargeDetails = [
                    "Amount": 300,
                    "Payment mode": "Credit Card",
                    "Charged ID": 24052013
                ] as [String : Any]

                let item1 = [
                    "Category": "books",
                    "Book name": "The Millionaire next door",
                    "Quantity": 1
                ] as [String : Any]

                let item2 = [
                    "Category": "books",
                    "Book name": "Achieving inner zen",
                    "Quantity": 1
                ] as [String : Any]

                let item3 = [
                    "Category": "books",
                    "Book name": "Chuck it, let's do it",
                    "Quantity": 5
                ] as [String : Any]
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: chargeDetails, andItems: [item1, item2, item3])
    }

    @objc private func recordCustomEvent() {
        let props = [
                   "Property 1": "Value 1",
                   "Property 2": 42
               ] as [String : Any]

        CleverTap.sharedInstance()?.recordEvent("Custom Event", withProps: props)
    }

    @objc private func triggerAlertInApp() {
        CleverTap.sharedInstance()?.recordEvent("tesr")
    }

    @objc private func showInbox() {
        print("Show App Inbox")
    }
}

// MARK: - UICollectionViewDataSource
@available(tvOS 13.0, *)
extension ViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CardCell.reuseID, for: indexPath
        ) as? CardCell else {
            fatalError("Unable to dequeue CardCell")
        }
        let item = sections[indexPath.section].items[indexPath.item]
        let color = sectionColors[indexPath.section % sectionColors.count]
        cell.configure(title: item.title, color: color)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: SectionHeader.reuseID,
                  for: indexPath
              ) as? SectionHeader else {
            fatalError("Unable to dequeue SectionHeader")
        }
        header.configure(title: sections[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegate

@available(tvOS 13.0, *)
extension ViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.item]
         perform(item.action)
    }
}
