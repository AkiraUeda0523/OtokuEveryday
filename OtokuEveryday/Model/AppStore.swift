//
//  AppStore.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/10/23.
//https://apps.apple.com/jp/app/%E3%81%8A%E5%BE%97%E3%82%A8%E3%83%96%E3%83%AA%E3%83%87%E3%82%A4/id1601815598

import Foundation
import Alamofire

typealias LookUpResult = [String: Any]

enum AppStoreError: Error {
    case networkError
    case invalidResponseData
}

class AppStore {
    private static let lastCheckVersionDateKey = "\(Bundle.main.bundleIdentifier!).lastCheckVersionDateKey"
    
    static func checkVersion(completion: @escaping (_ isOlder: Bool) -> Void) {
        let lastDate = UserDefaults.standard.integer(forKey: lastCheckVersionDateKey)
        let now = currentDate
        // 日付が変わるまでスキップ
        guard lastDate < now else { return }
        UserDefaults.standard.set(now, forKey: lastCheckVersionDateKey)
        lookUp { (result: Result<LookUpResult, AppStoreError>) in
            do {
                let lookUpResult = try result.get()
                if let storeVersion = lookUpResult["version"] as? String {
                    let storeVerInt = versionToInt(storeVersion)
                    let currentVerInt = versionToInt(Bundle.version)
                    completion(storeVerInt > currentVerInt)
                }
            }
            catch {
                completion(false)
            }
        }
    }
    static func versionToInt(_ ver: String) -> Int {
        let arr = ver.split(separator: ".").map { Int($0) ?? 0 }
        switch arr.count {
        case 3:
            return arr[0] * 1000 * 1000 + arr[1] * 1000 + arr[2]
        case 2:
            return arr[0] * 1000 * 1000 + arr[1] * 1000
        case 1:
            return arr[0] * 1000 * 1000
        default:
            assertionFailure("Illegal version string.")
            return 0
        }
    }
    static func open() {
        if let url = URL(string: storeURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
private extension AppStore {
    
    static var iTunesID: String {
        "1601815598"
    }
    static var storeURLString: String {
        "https://apps.apple.com/jp/app/%E3%81%8A%E5%BE%97%E3%82%A8%E3%83%96%E3%83%AA%E3%83%87%E3%82%A4/id"
        + iTunesID
    }
    static var lookUpURLString: String {
        "https://itunes.apple.com/lookup?id=" + iTunesID
    }
    static var currentDate: Int {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .current
        formatter.dateFormat = "yyyyMMdd"
        return Int(formatter.string(from: Date()))!
    }
    static func lookUp(completion: @escaping (Result<LookUpResult, AppStoreError>) -> Void) {
        AF.request(lookUpURLString).responseJSON(queue: .main, options: .allowFragments) { (response: AFDataResponse<Any>) in
            let result: Result<LookUpResult, AppStoreError>
            if let error = response.error {
                result = .failure(.networkError)
            }
            else {
                if let value = response.value as? [String: Any],
                   let results = value["results"] as? [LookUpResult],
                   let obj = results.first {
                    result = .success(obj)
                }
                else {
                    result = .failure(.invalidResponseData)
                }
            }
            completion(result)
        }
    }
}
extension Bundle {
    static var version: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
}
