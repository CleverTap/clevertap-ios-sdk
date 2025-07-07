import SwiftUI
import CleverTapSDK

struct VariablesMenuView: View {
    @State private var isFileTypeVariablesExpanded = false
    
    // Simplified data source
    private let basicMenuItems: [String] = [
        "Define Variable",
        "Define file Variables with listeners",
        "Fetch Variables",
        "Sync Variables",
        "Get Variable",
        "Get Variable Value",
        "Add Variables Changed Callback",
        "Add One Time Variables Changed Callback",
    ]
    
    private let fileTypeMenuItems: [(title: String, subtitle: String)] = [
        ("Define file Variables listeners", "adds file variables with fileReady() listeners"),
        ("Define file Variables with multiple listeners", "adds file variables with fileReady() listeners"),
        ("Global listeners & Define file Variables", "Adds listeners first and then registers the variables"),
        ("Multiple Global listeners & Define file Variables", "Adds listeners first and then registers the variables"),
        ("PrintFile Variables", ""),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Basic Menu Items
                    VStack(spacing: 0) {
                        ForEach(Array(basicMenuItems.enumerated()), id: \.offset) { index, title in
                            SimpleMenuItemView(title: title, index: index)
                            
                            if index < basicMenuItems.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                            
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    // File Type Variables Section
                    VStack(spacing: 0) {
                        // Collapsible Header
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isFileTypeVariablesExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text("FILE TYPE VARIABLES")
                                    .font(.system(size: 16, weight: .bold))
                                
                                Image(systemName: isFileTypeVariablesExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        // File Type Menu Items
                        if isFileTypeVariablesExpanded {
                            VStack(spacing: 0) {
                                ForEach(Array(fileTypeMenuItems.enumerated()), id: \.offset) { index, item in
                                    DetailedMenuItemView(title: item.title, subtitle: item.subtitle, index: index)
                                    
                                    if index < fileTypeMenuItems.count - 1 {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct SimpleMenuItemView: View {
    let title: String
    @State private var isPressed = false
    let index: Int
    
    var body: some View {
        Button(action: {
            print("Selected: \(title)")
            buttonActionVariables(index: index)
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(isPressed ? Color(.systemGray5) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    func buttonActionVariables(index: Int) {
        switch(index) {
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
            CleverTap.sharedInstance()?.fetchVariables({ isSucess in
                print("Variables Fetched = \(isSucess)")
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
            CleverTap.sharedInstance()?.onceVariablesChanged {
                print("onceVariablesChangedAndNoDownloadsPending onceVariablesChangedAndNoDownloadsPending")
            }
            
        default: break
        }
    }
}

struct DetailedMenuItemView: View {
    let title: String
    let subtitle: String
    let index: Int
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("Selected: \(title)")
            buttonActionForFileVars(index: index)
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isPressed ? Color(.systemGray5) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    func buttonActionForFileVars(index: Int) {
        switch(index) {
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
        default: break
        }
    }
}
