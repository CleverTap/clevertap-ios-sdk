import UIKit
import CleverTapSDK

class VariablesTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Data source for table view sections
    private let sections: [(title: String?, items: [(title: String, subtitle: String?)])] = [
        (nil, [
            ("Define Variable", nil),
            ("Define file Variables with listeners", nil),
            ("Fetch Variables", nil),
            ("Sync Variables", nil),
            ("Get Variable", nil),
            ("Get Variable Value", nil),
            ("Add Variables Changed Callback", nil),
            ("Add One Time Variables Changed Callback", nil)
        ]),
        ("File Variables", [
            ("Define file Variables listeners", "adds file variables with fileReady() listeners"),
            ("Define file Variables with multiple listeners", "adds file variables with fileReady() listeners"),
            ("Global listeners & Define file Variables", "Adds listeners first and then registers the variables"),
            ("Multiple Global listeners & Define file Variables", "Adds listeners first and then registers the variables"),
            ("PrintFile Variables", nil)
        ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "SubtitleCell")
        //        tableView.style = .grouped
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    private func setupNavigationBar() {
        title = "Variables"        
        // Add back button
        let backButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension VariablesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        
        if let subtitle = item.subtitle {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath) as! SubtitleTableViewCell
            cell.configure(title: item.title, subtitle: subtitle)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            cell.accessoryType = .disclosureIndicator
            //            cell.backgroundColor = UIColor.systemBackground
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension VariablesTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedItem = sections[indexPath.section].items[indexPath.row]
        print("Selected: \(selectedItem.title)")
        
        // Handle navigation or action for selected item
        handleMenuSelection(for: selectedItem.title, section: indexPath.section, row: indexPath.row)
    }
    
    private func handleMenuSelection(for title: String, section: Int, row: Int) {
        if section == 0 {
            switch row {
            case 0:
                CleverTap.sharedInstance()?.defineVar(name: "var_int", number: 3)
                CleverTap.sharedInstance()?.defineVar(name: "var_long", long: 64)
                CleverTap.sharedInstance()?.defineVar(name: "var_short", short: Int16(2))
                CleverTap.sharedInstance()?.defineVar(name: "var_float", float: Float(5.0))
                CleverTap.sharedInstance()?.defineVar(name: "var_double", double: Double(6.02))
                CleverTap.sharedInstance()?.defineVar(name: "var_string", string: "hello")
                CleverTap.sharedInstance()?.defineVar(name: "var_boolean", boolean: true)
            case 1:
                print("Starting to define file vars:")
                FileVarsData.defineFileVars()
                print("Printing file vars values, they might be null if not yet fetched")
                FileVarsData.printFileVariables()
            case 2:
                CleverTap.sharedInstance()?.fetchVariables({ isSuccess in
                    print("Variables Fetched = \(isSuccess)")
                })
            case 3:
                CleverTap.sharedInstance()?.syncVariables()
            case 4:
                var varValues: [Var?] = []
                
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_int"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_long"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_short"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_float"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_double"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_string"))
                varValues.append(CleverTap.sharedInstance()?.getVariable("var_boolean"))
                
                print("Printing variables (basic types) :")
                for varValue in varValues {
                    print(varValue?.name() ?? "not found")
                }
            case 5:
                var varValues: [Any?] = []
                
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_int"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_long"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_short"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_float"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_double"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_string"))
                varValues.append(CleverTap.sharedInstance()?.getVariableValue("var_boolean"))
                
                print("Printing variables Values (basic types) :")
                for varValue in varValues {
                    print(varValue ?? "")
                }
                FileVarsData.printFileVariablesValues()
            case 6:
                CleverTap.sharedInstance()?.onVariablesChanged {
                    print("Variables Changed")
                }
                CleverTap.sharedInstance()?.onVariablesChangedAndNoDownloadsPending {
                    print("Files downloaded, onVariablesChangedAndNoDownloadsPending - should come after each fetch")
                    print("variablesChanged: reprinting files var data")
                    FileVarsData.printFileVariables()
                }
            case 7: CleverTap.sharedInstance()?.onceVariablesChanged {
                    print("One Time Variables Changed")
                    }
                CleverTap.sharedInstance()?.onceVariablesChangedAndNoDownloadsPending {
                    print("onceVariablesChangedAndNoDownloadsPending onceVariablesChangedAndNoDownloadsPending")
                }
            default:
                break
            }
        } else if section == 1 {
            // File Variables section items
            switch row {
            case 0:
                FileVarsData.defineFileVars()
                print("Printing file vars values, they might be null if not yet fetched")
                FileVarsData.printFileVariables()
            case 1:
                FileVarsData.defineFileVars(fileReadyListenerCount: 3)
                print("Printing file vars values, they might be null if not yet fetched")
                FileVarsData.printFileVariables()
            case 2:
                FileVarsData.addGlobalCallbacks()
                FileVarsData.defineFileVars()
            case 3:
                FileVarsData.addGlobalCallbacks(listenerCount: 3)
                FileVarsData.defineFileVars(fileReadyListenerCount: 3)
            case 4:
                FileVarsData.printFileVariables()
            default:
                break
            }
        }
    }
}

// MARK: - Custom Cell for Subtitle
class SubtitleTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        accessoryType = .disclosureIndicator
        //        backgroundColor = UIColor.systemBackground
        textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detailTextLabel?.textColor = UIColor.systemGray
        detailTextLabel?.numberOfLines = 0
    }
    
    func configure(title: String, subtitle: String) {
        textLabel?.text = title
        detailTextLabel?.text = subtitle
    }
}
