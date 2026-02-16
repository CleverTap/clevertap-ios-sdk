import Foundation
import CoreLocation

@objc(CTUtils)
@objcMembers
public class CTUtils: NSObject {

    @objc(urlEncodeString:)
    public static func urlEncodeString(_ s: String?) -> String? {
        guard let s = s else { return nil }

        var output = ""
        guard let source = s.cString(using: .utf8) else { return nil }

        for byte in source where byte != 0 {
            let char = UnicodeScalar(UInt8(byte))

            if char == " " {
                output.append("+")
            } else if char == "." || char == "-" || char == "_" || char == "~" ||
                      (char >= "a" && char <= "z") ||
                      (char >= "A" && char <= "Z") ||
                      (char >= "0" && char <= "9") {
                output.append(String(char))
            } else {
                output.append(String(format: "%%%02X", byte))
            }
        }
        return output
    }

    @objc(doesString:startWith:)
    public static func doesString(_ s: String?, startWith prefix: String?) -> Bool {
        do {
            guard let s = s, let prefix = prefix else { return false }
            guard s.count >= prefix.count else { return false }
            guard !s.isEmpty && !prefix.isEmpty else { return false }

            let startIndex = s.startIndex
            let endIndex = s.index(startIndex, offsetBy: prefix.count)
            return String(s[startIndex..<endIndex]) == prefix
        } catch {
            return false
        }
    }

    @objc(deviceTokenStringFromData:)
    public static func deviceTokenString(from tokenData: Data?) -> String? {
        guard let tokenData = tokenData, tokenData.count > 0 else { return nil }

        let tokenBytes = tokenData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [UInt32] in
            let buffer = ptr.bindMemory(to: UInt32.self)
            return Array(buffer)
        }

        guard tokenBytes.count >= 8 else { return nil }

        let hexToken = String(format: "%08x%08x%08x%08x%08x%08x%08x%08x",
                            tokenBytes[0].bigEndian, tokenBytes[1].bigEndian,
                            tokenBytes[2].bigEndian, tokenBytes[3].bigEndian,
                            tokenBytes[4].bigEndian, tokenBytes[5].bigEndian,
                            tokenBytes[6].bigEndian, tokenBytes[7].bigEndian)

        return hexToken
    }

    @objc(toTwoPlaces:)
    public static func toTwoPlaces(_ x: Double) -> Double {
        var result = x * 100.0
        result = round(result)
        result = result / 100.0
        return result
    }

    @objc(isNullOrEmpty:)
    public static func isNullOrEmpty(_ obj: Any?) -> Bool {
        guard let obj = obj else { return true }

        // Check for NSString to support RubyMotion
        if let string = obj as? String {
            return string.isEmpty
        }

        // Check for collections with count
        if let collection = obj as? any Collection {
            return collection.isEmpty
        }

        return false
    }

    @objc(jsonObjectToString:)
    public static func jsonObjectToString(_ object: Any?) -> String? {
        guard let object = object else { return "" }

        if let string = object as? String {
            return string
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return ""
        }
    }

    @objc(getKeyWithSuffix:accountID:)
    public static func getKey(withSuffix suffix: String, accountID: String) -> String {
        return "\(accountID):\(suffix)"
    }

    @objc(runSyncMainQueue:)
    public static func runSyncMainQueue(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }

    @objc(runAsyncMainQueue:)
    public static func runAsyncMainQueue(_ block: @escaping () -> Void) {
        DispatchQueue.main.async {
            block()
        }
    }

    @objc(haversineDistance:coordinateB:)
    public static func haversineDistance(_ coordinateA: CLLocationCoordinate2D, coordinateB: CLLocationCoordinate2D) -> Double {
        // The Earth radius ranges from a maximum of about 6378 km (equatorial)
        // to a minimum of about 6357 km (polar).
        // A globally-average value is usually considered to be 6371 km (6371e3).
        // This method uses 6378.2 km as the radius since this is the value
        // used by the backend and calculations should produce the same result.
        let earthDiameter = 2 * 6378.2

        let radConvert = Double.pi / 180.0
        let phi1 = coordinateA.latitude * radConvert
        let phi2 = coordinateB.latitude * radConvert

        let deltaPhi = (coordinateB.latitude - coordinateA.latitude) * radConvert
        let deltaLambda = (coordinateB.longitude - coordinateA.longitude) * radConvert

        let sinPhi = sin(deltaPhi / 2.0)
        let sinLambda = sin(deltaLambda / 2.0)

        let a = sinPhi * sinPhi + cos(phi1) * cos(phi2) * sinLambda * sinLambda
        // Distance in km
        let distance = earthDiameter * atan2(sqrt(a), sqrt(1 - a))
        return distance
    }

    @objc(numberFromString:)
    public static func number(from string: String?) -> NSNumber? {
        return number(from: string, withLocale: nil)
    }

    @objc(numberFromString:withLocale:)
    public static func number(from string: String?, withLocale locale: Locale?) -> NSNumber? {
        guard let string = string else { return nil }

        let scanner = Scanner(string: string)
        if let locale = locale {
            scanner.locale = locale
        }

        var d: Double = 0
        if scanner.scanDouble(&d) && scanner.isAtEnd {
            return NSNumber(value: d)
        }

        return nil
    }

    @objc(getNormalizedName:)
    public static func getNormalizedName(_ name: String?) -> String? {
        guard let name = name else { return nil }

        // Lowercase with English locale for consistent behavior with the backend
        // and across different device locales.
        var normalizedName = name.replacingOccurrences(of: " ", with: "")
        let englishLocale = Locale(identifier: "en_US")
        normalizedName = normalizedName.lowercased(with: englishLocale)
        normalizedName = normalizedName.trimmingCharacters(in: .whitespaces)
        return normalizedName
    }

    @objc(areEqualNormalizedName:andName:)
    public static func areEqualNormalizedName(_ firstName: String?, andName secondName: String?) -> Bool {
        if firstName == nil && secondName == nil {
            return true
        }

        if firstName == nil || secondName == nil {
            return false
        }

        guard let normalizedFirstName = getNormalizedName(firstName),
              let normalizedSecondName = getNormalizedName(secondName) else {
            return false
        }

        return normalizedFirstName == normalizedSecondName
    }

    @objc(isValidCleverTapId:)
    public static func isValidCleverTapId(_ cleverTapID: String?) -> Bool {
        let allowedCharacters = "[=|<>;+.A-Za-z0-9()!:$@_-]*"
        let predicate = NSPredicate(format: "SELF MATCHES %@", allowedCharacters)

        guard let cleverTapID = cleverTapID else {
            // TODO: Add logging - CleverTapLogStaticInternal(@"CleverTapUseCustomId has been specified true in Info.plist but custom CleverTap ID passed is NULL.")
            return false
        }

        if cleverTapID.isEmpty {
            // TODO: Add logging - CleverTapLogStaticInfo(@"CleverTapUseCustomId has been specified true in Info.plist but custom CleverTap ID passed is empty.")
            return false
        }

        if cleverTapID.count > 64 {
            // TODO: Add logging - CleverTapLogStaticInfo(@"Custom CleverTap ID passed is greater than 64 characters.")
            return false
        }

        if !predicate.evaluate(with: cleverTapID) {
            // TODO: Add logging - CleverTapLogStaticInfo(@"Custom CleverTap ID cannot contain special characters apart from (, ), !, :, @, $, _, and -")
            return false
        }

        return true
    }
}
