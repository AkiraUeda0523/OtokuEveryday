//
//  MapModel.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/02/07.

import RxSwift
import RxCocoa
import Firebase
import RealmSwift
import Network
// MARK: - Protocols
protocol MapModelInput {
    func fetchAddressDataFromRealTimeDB()
    func fetchOtokuSpecialtyData()
    var shouldUpdateDataJudgeObserver: AnyObserver<Bool> { get }
    func fetchDataFromFirebaseAndSaveToRealm()
}
protocol MapModelOutput {
    var AddressDataObservable: Observable<[OtokuAddressModel]> { get }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> { get }
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> { get }
}
protocol MapModelType {
    var output: MapModelOutput { get }
    var input: MapModelInput { get }
}
// MARK: -
struct SlideShowModel {
    var image: String
    var webUrl: String
    var title: String
    var address: String
    var comment: String
    init?(input: [String: Any]) {
        guard let webUrl = input["webUrl"] as? String,
              let address = input["address"] as? String,
              let title = input["title"] as? String,
              let image = input["image"] as? String,
              let comment = input["comment"] as? String
        else {
            return nil
        }
        self.webUrl = webUrl
        self.address = address
        self.title = title
        self.image = image
        self.comment = comment
    }
}
extension SlideShowModel: Equatable {
    static func == (lhs: SlideShowModel, rhs: SlideShowModel) -> Bool {
        return lhs.image == rhs.image &&
        lhs.webUrl == rhs.webUrl &&
        lhs.title == rhs.title &&
        lhs.address == rhs.address &&
        lhs.comment == rhs.comment
    }
}
// MARK: - Main Class
final class MapModel {
    private let addressDataRelay = BehaviorRelay<[OtokuAddressModel]>(value: [])
    private let otokuDataRelay = BehaviorRelay<[OtokuDataModel]>(value: [])
    private let otokuSpecialtyRelay = BehaviorRelay<[SlideShowModel]>(value: [])
    private let shouldUpdateDataJudge = PublishSubject<Bool>()
    let disposeBag = DisposeBag()
}
// MARK: - Input Implementation
extension MapModel: MapModelInput {
    var shouldUpdateDataJudgeObserver: AnyObserver<Bool> {
        return shouldUpdateDataJudge.asObserver()
    }
    func fetchAddressDataFromRealTimeDB() {
        isConnectedToNetwork { [weak self] isConnected in
            DispatchQueue.main.async { [self] in
                // selfのアンラップを確認
                guard let self = self else { return }
                
                do {
                    // Realmインスタンスを取得（ここでエラーハンドリング）
                    let realm = try Realm()
                    // Realmから住所データを取得
                    let otokuAddressBox = realm.objects(OtokuAddressRealmModel.self)
                    // ネットワークに接続されていない場合
                    if !isConnected {
                        if otokuAddressBox.isEmpty {
                            // ⚠️Realmデータが空の場合、エラーメッセージまたは適切なフィードバックを提供
                        } else {
                            // ローカルのRealmデータを使用し、Observableに反映
                            self.addressDataRelay.accept(otokuAddressBox.map { $0.toModel() })
                        }
                        return
                    }
                    // 以下、ネットワークに接続されている場合の処理
                    // Realmデータが空の場合はFirebaseからデータを取得
                    if otokuAddressBox.isEmpty {
                        self.fetchDataFromFirebaseAndSaveToRealm()
                    } else {
                        // Realmデータが存在する場合は更新の必要性を判断
                        self.shouldUpdateDataJudge.asObservable()
                            .take(1)//⚠️ここちゃんととれるか？⚠️
                            .subscribe(onNext: { shouldUpdate in
                                // 更新が必要な場合はFirebaseからデータを取得
                                if shouldUpdate {
                                    self.fetchDataFromFirebaseAndSaveToRealm()
                                } else {
                                    // 更新不要の場合は現在のRealmデータを使用
                                    DispatchQueue.main.async {
                                        self.addressDataRelay.accept(otokuAddressBox.map { $0.toModel() })
                                    }
                                }
                            })
                            .disposed(by: self.disposeBag)
                    }
                } catch {
                    // Realmの初期化時にエラーが発生した場合の処理
                    print("Error fetching data from Realm: \(error)")
                    // 必要に応じてユーザーへのエラー表示などの処理を追加
                }
            }
        }
    }
    // Firebaseから住所データを取得し、Realmに保存する
    func fetchDataFromFirebaseAndSaveToRealm() {
        let ref = Database.database().reference(withPath: "SecondOtokuAddressModelsObject")
        ref.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in//observe(of: .value)に？ーーしなくていい。保存の度に復活するので
            guard let strongSelf = self else { return }
            // スナップショットからデータを取得し、辞書型配列としてキャスト
            guard let data = snapshot.value as? [String: [String: Any]] else {
                return
            }
            // 住所データを格納するための配列を初期化
            var otokuAddressBox: [OtokuAddressModel] = []
            // 取得したデータの各要素を処理
            for (_, item) in data {
                if let addressId = item["address_id"] as? String,
                   let content = item["content"] as? String {
                    let latitude = item["latitude"] as? Double
                    let longitude = item["longitude"] as? Double
                    let otokuAddressModel = OtokuAddressModel(address_id: addressId, content: content, latitude: latitude, longitude: longitude)
                    otokuAddressBox.append(otokuAddressModel)
                    // Realmモデルに変換し、Realmデータベースに保存
                    let realmModel = OtokuAddressRealmModel.from(otokuAddressModel)
                    let realm = try! Realm()
                    try! realm.write {
                        realm.add(realmModel, update: .modified)
                    }
                }
            }
            //             処理が完了したら、Observableに住所データを流す
            strongSelf.addressDataRelay.accept(otokuAddressBox)
        })
    }
    // Firestoreから「お得スペシャルティ」データを取得するメソッド　addSnapshotListenerをgetDocumentsに変更
    func fetchOtokuSpecialtyData() {
        // スライドショーモデルの配列を初期化
        var slideArray = [SlideShowModel]()
        // Firestoreの特定のドキュメントからデータを取得
        Firestore.firestore().collection("OtokuSpecialtyData")
            .document("2021").collection("2021-12").getDocuments { [self] snapshots, error in
                // エラーがあれば、その内容を出力し、処理を終了
                if let error = error {
                    print("情報の取得に失敗\(error)")
                    return
                }
                // スライドショーデータの配列をリセット
                slideArray = []
                // 各スナップショット（ドキュメント）を処理
                snapshots?.documents.forEach({ (snapshot) in
                    // ドキュメントのデータを取得
                    let data = snapshot.data()
                    // データからスライドショーモデルを生成し、配列に追加
                    if let information = SlideShowModel(input: data) {
                        slideArray.append(information)
                    }
                })
                // 処理が完了したら、Observableにスライドショーデータを流す
                self.otokuSpecialtyRelay.accept(slideArray)
            }
    }
    // ネットワーク接続状態を確認するメソッド
    func isConnectedToNetwork(completion: @escaping (Bool) -> Void) {
        // NWPathMonitorを使ってネットワーク接続を監視
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        // パスの更新があるたびに呼び出されるハンドラーを設定
        monitor.pathUpdateHandler = { path in
            // 接続状態が「満たされている（satisfied）」かどうかで判定し、結果を返す
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
            // 監視を終了
            monitor.cancel()
        }
        // 監視を開始
        monitor.start(queue: queue)
    }
}
// MARK: - Output Implementation
extension MapModel: MapModelOutput {
    var otokuSpecialtyObservable: Observable<[SlideShowModel]> {
        return otokuSpecialtyRelay.asObservable()
    }
    var AddressDataObservable: Observable<[OtokuAddressModel]> {
        return addressDataRelay.asObservable()
    }
    var AllOtokuDataObservable: Observable<[OtokuDataModel]> {
        return  otokuDataRelay.asObservable()
    }
}
// MARK: - Additional Extensions
extension MapModel: MapModelType {
    var output: MapModelOutput { return self }
    var input: MapModelInput { return self }
}
// MARK: -
@objcMembers class OtokuAddressRealmModel: Object {
    dynamic var address_id: String = ""
    dynamic var content: String = ""
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    override static func primaryKey() -> String? {
        return "address_id"
    }
    static func from(_ model: OtokuAddressModel) -> OtokuAddressRealmModel {
        let realmModel = OtokuAddressRealmModel()
        realmModel.address_id = model.address_id
        realmModel.content = model.content!
        realmModel.latitude = model.latitude!
        realmModel.longitude = model.longitude!
        return realmModel
    }
    func toModel() -> OtokuAddressModel {
        return OtokuAddressModel(address_id: address_id, content: content, latitude: latitude, longitude: longitude)
    }
}
