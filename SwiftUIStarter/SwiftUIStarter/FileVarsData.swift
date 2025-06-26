//
//  FileVarsData.swift
//  SwiftUIStarter
//
//  Created by Sonal Kachare on 25/06/25.
//


import Foundation
import CleverTapSDK

class FileVarsData {
    
    private static let listFileVarNames = [
        "fileVariableRoot",
        "folder1.fileVariable",
        "folder1.folder2.fileVariable",
        "folder1.folder3.fileVariable",
        "folder1.folder4.folder5.fileVariable",
        "assets.image.fileVariable",
        "assets.video.fileVariable",
        "assets.pdf.fileVariable",
        "assets.gif.fileVariable"
    ]
    
    static func addGlobalCallbacks(
        tag: String = "FileVarsData",
        listenerCount: Int = 1
    ) {
        for count in 0...listenerCount {
            let l1 = {
                print("\(tag): onVariablesChangedAndNoDownloadsPending from listener-\(count) - should come after each fetch")
                printFileVariables(tag: tag)
            }
            
            let l2 = {
                print("\(tag): onceVariablesChangedAndNoDownloadsPending from listener-\(count) - should come only once globally")
            }
            CleverTap.sharedInstance()?.onVariablesChanged (l1)
            CleverTap.sharedInstance()?.onVariablesChanged (l2)
        }
    }
    
    static func defineFileVars(
        tag: String = "FileVarsData",
        fileReadyListenerCount: Int = 1
    ) {
        var list: [Var] = []
        var builder = "File variables defined, current values:\n"
        
        for name in listFileVarNames {
            if let variable = defineFileVarPlusListener(
                name: name,
                fileReadyListenerCount: fileReadyListenerCount,
                tag: tag
            ) {
                list.append(variable)
                builder += "\(variable.name) : \(variable.stringValue ?? "")\n"
            }
        }
        
        print("\(tag): \(builder)")
    }
    
    private static func defineFileVarPlusListener(
        name: String,
        fileReadyListenerCount: Int,
        tag: String
    ) -> Var? {
        guard let variable = CleverTap.sharedInstance()?.defineVar(name: name) else {
            return nil
        }
        
        for count in 0...fileReadyListenerCount {
            
//            variable.addFileReadyHandler { fileVar in
//                print("\(tag): \(fileVar?.name ?? "") ready: \(fileVar?.stringValue ?? "") from listener \(count)")
//            }
        }
        
        return variable
    }
    
    static func printFileVariables(
        tag: String = "FileVarsData"
    ) {
        var builder = "List of file variables:\n"
        
        for name in listFileVarNames {
            if let variable = CleverTap.sharedInstance()?.getVariable(name) {
                builder += "\(variable.name) : \(variable.stringValue ?? "")\n"
            }
        }
        
        print("\(tag): \(builder)")
    }
    
    static func printFileVariablesValues(
        tag: String = "FileVarsData"
    ) {
        var builder = "List of file variables:\n"
        
        for name in listFileVarNames {
            if let url = CleverTap.sharedInstance()?.getVariableValue(name) as? String {
                builder += "\(url)\n"
            }
        }
        
        print("\(tag): \(builder)")
    }
}
