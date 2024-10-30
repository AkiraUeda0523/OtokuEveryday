//
//  FirebaseFetcherModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/12/23.
//
import Firebase
// MARK: -
enum FirebaseFetcherError: Error {
    case invalidVersionData
    case invalidOtokuData
}
// MARK: - Protocols
protocol FirebaseFetcher {
    func firebaseFetchVersion() async throws -> Int
    func firebaseFetchData() async throws -> [OtokuDataModel]
}
// MARK: - Main Class
class FirebaseFetcherModel: FirebaseFetcher {
    // Firebaseからアプリのバージョン情報を非同期で取得するメソッド
    func firebaseFetchVersion() async throws -> Int {
        // Firebaseのデータベースからバージョン情報を参照
        let versionRef = Database.database().reference().child("version")
        // データスナップショットを非同期で取得
        let snapshot = try await versionRef.getData()
        // スナップショットからバージョン番号を取得（取得できない場合はエラーを投げる）
        guard let version = snapshot.value as? Int else {
            throw FirebaseFetcherError.invalidVersionData
        }
        return version
    }
    // Firebaseから「お得データモデル」の情報を非同期で取得し、デコードするメソッド
    func firebaseFetchData() async throws -> [OtokuDataModel] {
        // Firebaseから特定のデータオブジェクトを参照
        let ref = Database.database().reference().child("OtokuDataModelsObject")
        // データスナップショットを非同期で取得
        let snapshot = try await ref.getData()
        // スナップショットからデータの辞書を取得（取得できない場合はエラーを投げる）
        guard let dataDictionaries = snapshot.value as? [[String: Any]] else {
            throw FirebaseFetcherError.invalidOtokuData
        }
        // JSONデータを`OtokuDataModel`配列にデコード
        let jsonData = try JSONSerialization.data(withJSONObject: dataDictionaries, options: [])
        let otokuDataModels = try JSONDecoder().decode([OtokuDataModel].self, from: jsonData)
        return otokuDataModels
    }
}
