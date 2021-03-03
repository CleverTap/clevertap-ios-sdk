//
//  Utilities.swift
//  SPMStarter
//
//  Created by Aditi Agrawal on 09/11/20.
//

import UIKit

extension UIColor {
    
    public convenience init?(hex: String) {
        let r, g, b: CGFloat
       
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt32 = 0
            if scanner.scanHexInt32(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255.0
                g = CGFloat((hexNumber & 0xff00) >> 8) / 255.0
                b = CGFloat((hexNumber & 0xff) >> 0) / 255.0
                self.init(red: r, green: g, blue: b, alpha: 1.0)
                return
            }
        }
        return nil
    }
}
