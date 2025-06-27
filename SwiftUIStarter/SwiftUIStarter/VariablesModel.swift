import Foundation
import CleverTapSDK

class VariablesModel: NSObject, ObservableObject {
    var varsDefined = false
    // MARK: - Variables
    // Primitives
    var var_int, var_bool, var_float, var_double, var_short, var_number, var_long: Var?
    var var_file_1, var_file_2, var_file_3: Var?

    // Groups
    var var_group_hello, var_dict, var_dict_complex, var_outer, var_android_samsung, var_s1, var_s2, var_group_varGroup, var_group: Var?
    
    var var1, var2, var3: Var?

    // MARK: - VarModel Publisher
    @Published var vars: [VarModel] = []
    @Published var fileVars: [VarModel] = []

    // MARK: - Initializers
    override init() {
        super.init()
    }
    
    func setCallbacks() {
        // Set callbacks
        CleverTap.sharedInstance()?.onVariablesChanged { [weak self] in
            NSLog("[Starter][CleverTap]: CleverTap onVariablesChanged")
            self?.createVarsArray()
            self?.createFileVarsArray()
        }
        
        CleverTap.sharedInstance()?.onVariablesChangedAndNoDownloadsPending { [weak self] in
            NSLog("[Starter][CleverTap]: CleverTap onVariablesChangedAndNoDownloadsPending")
            self?.createVarsArray()
            self?.createFileVarsArray()
        }
        
        var_file_1?.setDelegate(self)
        var_file_2?.setDelegate(self)
        var_file_3?.setDelegate(self)
    }
    
    func defineVariables() {
        if (!varsDefined) {
            varsDefined = true
            
            var_int = CleverTap.sharedInstance()?.defineVar(name: "var_int", integer: 10)
            var_bool = CleverTap.sharedInstance()?.defineVar(name: "var_bool", boolean: true)
            var_float = CleverTap.sharedInstance()?.defineVar(name: "var_float", float: 5.0)
            var_double = CleverTap.sharedInstance()?.defineVar(name: "var_double", double: 55.999)
            var_short = CleverTap.sharedInstance()?.defineVar(name: "var_short", short: 1)
            var_number = CleverTap.sharedInstance()?.defineVar(name: "var_number", number: NSNumber(value: 32))
            var_long = CleverTap.sharedInstance()?.defineVar(name: "var_long", long: 64)
            
            var_group_hello = CleverTap.sharedInstance()?.defineVar(name: "var.hello", string: "hello, group")
            
            var_dict = CleverTap.sharedInstance()?.defineVar(name: "var_dict", dictionary: [
                "nested_string": "hello, nested",
                "nested_double": 10.5
            ])
            
            var_dict_complex = CleverTap.sharedInstance()?.defineVar(name: "var_dict_complex", dictionary: [
                "nested_int": 1,
                "nested_string": "hello, nested",
                "nested_map": [
                    "nested_map_int": 11,
                    "nested_map_string": "hello, nested map",
                ]
            ])
            
            var_outer = CleverTap.sharedInstance()?.defineVar(name: "var_dict.nested_outside", string: "hello, outside")

            var_group_varGroup = CleverTap.sharedInstance()?.defineVar(name: "var.group.varGroup", string: "This is in a group.")
            var_group = CleverTap.sharedInstance()?.defineVar(name: "var.group", dictionary: ["anotherInner": "This is also in a group"])
            
            var1 = CleverTap.sharedInstance()?.defineVar(name: "group1.var1", integer: 1)
            var3 = CleverTap.sharedInstance()?.defineVar(name: "group1.group2.var3", integer: 3)
            var2 = CleverTap.sharedInstance()?.defineVar(name: "group1", dictionary: ["var2": 2, "group2": ["var4": 4]])
            var_file_1 = CleverTap.sharedInstance()?.defineFileVar(name: "folder1.fileVariable")
            var_file_2 = CleverTap.sharedInstance()?.defineFileVar(name: "folder1.folder2.fileVariable")
            var_file_3 = CleverTap.sharedInstance()?.defineFileVar(name: "folder1.folder3.fileVariable")
            
            setCallbacks()
        }
    }
    
    deinit {
        // Remove delegate
        var_file_1?.setDelegate(nil)
        var_file_2?.setDelegate(nil)
        var_file_3?.setDelegate(nil)
    }
    
    // MARK: - Model Funcs
    func createVarsArray() {
        vars = [
            VarModel(title: var1!.name(), value: var1?.value ?? "nil"),
            VarModel(title: "\(var1!.name()) defaultValue", value: var1?.defaultValue ?? "nil"),
            VarModel(title: var2!.name(), value: var2?.value ?? "nil"),
            VarModel(title: "\(var2!.name()) defaultValue", value: var2?.defaultValue ?? "nil"),
            VarModel(title: var3!.name(), value: var3?.value ?? "nil"),
            VarModel(title: "\(var3!.name()) defaultValue", value: var3?.defaultValue ?? "nil"),
            
            VarModel(title: var_int!.name(), value: var_int?.intValue() ?? "nil"),
            VarModel(title: var_bool!.name(), value: var_bool?.boolValue() ?? "nil"),
            VarModel(title: var_float!.name(), value: var_float?.floatValue() ?? "nil"),
            VarModel(title: var_double!.name(), value: var_double?.doubleValue() ?? "nil"),
            VarModel(title: var_short!.name(), value: var_short?.shortValue() ?? "nil"),
            VarModel(title: var_number!.name(), value: var_number?.numberValue?.int32Value ?? "nil"),
            VarModel(title: var_long!.name(), value: var_long?.longValue() ?? "nil"),
            
            VarModel(title: var_group_hello!.name(), value: var_group_hello?.value ?? "nil"),

            VarModel(title: var_dict!.name(), value: var_dict?.value ?? "nil"),
            VarModel(title: "\(var_dict!.name()) defaultValue", value: var_dict?.defaultValue ?? "nil"),
            
            VarModel(title: var_android_samsung!.name(), value: var_android_samsung?.value ?? "nil"),
            VarModel(title: var_group!.name(), value: var_group?.value ?? "nil"),
            VarModel(title: var_group_varGroup!.name(), value: var_group_varGroup?.value ?? "nil"),
            VarModel(title: var_dict_complex!.name(), value: var_dict_complex?.value ?? "nil"),
            VarModel(title: "\(var_dict_complex!.name()) nested_string", value: var_dict_complex?.object(forKey: "nested_string") ?? "nil"),
            VarModel(title: var_file_1!.name(), value: var_file_1?.value ?? "nil"),
            VarModel(title: var_file_2!.name(), value: var_file_2?.value ?? "nil"),
            VarModel(title: var_file_3!.name(), value: var_file_3?.value ?? "nil")
        ]
    }
    
    func createFileVarsArray() {
        fileVars = [
            VarModel(title: var_file_1!.name(), value: var_file_1?.value ?? "nil"),
            VarModel(title: var_file_2!.name(), value: var_file_2?.value ?? "nil"),
            VarModel(title: var_file_3!.name(), value: var_file_3?.value ?? "nil")
        ]
    }
    
    public func sync() {
        NSLog("[Starter][CleverTap]: Calling CleverTap syncVariables:true")
        CleverTap.sharedInstance()?.syncVariables(true)
    }

    public func forceContentUpdate() {
        CleverTap.sharedInstance()?.fetchVariables({ [weak self] success in
            NSLog("[Starter][CleverTap]: CleverTap fetchVariables: \(success)")
            self?.createVarsArray()
            self?.createFileVarsArray()
        })
    }
}

// MARK: - Variables Model
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension VariablesModel {
    struct VarModel: Identifiable {
        var id: String
        var value: Any
        var title: String {
            return id
        }
        
        init(title: String, value: Any) {
            id = title
            self.value = value
        }
    }
}

// MARK: - Var Delegate
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
@objc extension VariablesModel: VarDelegate {
    func valueDidChange(_ variable: CleverTapSDK.Var) {
        NSLog("[Starter][CleverTap]: CleverTap \(String(describing: variable.name)):valueDidChange to: \(variable.value ?? "nil")")
    }
    
    func fileIsReady(_ variable: CleverTapSDK.Var) {
        NSLog("[Starter][CleverTap]: CleverTap fileIsReady path: \(variable.value ?? "nil")")
    }
}
