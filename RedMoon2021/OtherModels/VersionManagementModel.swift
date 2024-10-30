//
//  VersionManagementModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/12/23.
//
import Foundation
// MARK: - Protocols
protocol UserDefaultsVersion {
    var userDefaultsVersionNumber: Int? { get set }
}
// MARK: - Main Class
class VersionManagementModel: UserDefaultsVersion {
    // ストアされたバージョン番号の取得および設定
    var userDefaultsVersionNumber: Int? {
        get {
            return UserDefaults.standard.value(forKey: Constants.storedVersionKey) as? Int
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.storedVersionKey)
        }
    }
}
enum Constants {
    static let storedVersionKey = "storedVersion"
}
