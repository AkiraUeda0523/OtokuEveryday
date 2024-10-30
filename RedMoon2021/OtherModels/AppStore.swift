//
//  AppStore.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2022/10/23.
// https://apps.apple.com/jp/app/%E3%81%8A%E5%BE%97%E3%82%A8%E3%83%96%E3%83%AA%E3%83%87%E3%82%A4/id1601815598

import Foundation
import Alamofire
// MARK: - ヘルパータイプ
// App Storeに関連するエラーの列挙型
enum AppStoreError: Error {
    case networkError
    case invalidResponseData
}
struct AppStoreResponse: Decodable {
    let results: [LookUpResult]
}
struct LookUpResult: Decodable {
    let version: String
    //    例
    //    let artistName: String
    //    let releaseNotes: String
    //    let minimumOsVersion: String
    //    let genreIds: [String]
}
// MARK: - Main Class
// App Storeの情報を取得・管理するクラス
class AppStore {
    private static let lastCheckVersionDateKey = "\(Bundle.main.bundleIdentifier!).lastCheckVersionDateKey"
    // アプリのバージョンをチェックするメソッド
    static func checkVersion(completion: @escaping (_ isOlder: Bool) -> Void) {
        let lastDate = UserDefaults.standard.integer(forKey: lastCheckVersionDateKey)
        let now = currentDate
        // 前回のチェックから日付が変わっていない場合はスキップ
        guard lastDate < now else { return }
        UserDefaults.standard.set(now, forKey: lastCheckVersionDateKey)
        // App Storeの情報を取得
        lookUp { (result: Result<LookUpResult, AppStoreError>) in
            do {
                let lookUpResult = try result.get()
                let storeVerInt = versionToInt(lookUpResult.version)
                let currentVerInt = versionToInt(Bundle.version)
                completion(storeVerInt > currentVerInt)
            } catch {
                completion(false)
            }
        }
    }
    // バージョン文字列を整数に変換するユーティリティメソッド
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
    // App Storeのページを開くメソッド
    static func open() {
        if let url = URL(string: storeURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
// MARK: - Private Extensions
private extension AppStore {
    // App Storeと関連する静的プロパティ
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
    // App Storeからアプリの情報を取得するメソッド
    static func lookUp(completion: @escaping (Result<LookUpResult, AppStoreError>) -> Void) {
        AF.request(lookUpURLString).responseDecodable(of: AppStoreResponse.self) { response in
            switch response.result {
            case .success(let appStoreResponse):
                if let firstResult = appStoreResponse.results.first {
                    completion(.success(firstResult))
                } else {
                    completion(.failure(.invalidResponseData))
                }
            case .failure:
                completion(.failure(.networkError))
            }
        }
    }
}
// MARK: - Bundle Extension
extension Bundle {
    // アプリの現在のバージョンを取得する静的プロパティ
    static var version: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
}
