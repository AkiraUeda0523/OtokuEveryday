
![名称未設定 (1)](https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/b7616f77-8787-4b88-b497-f81fdcc14120)


![お得表](https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/82c5f1b8-3998-469c-9751-21ada15d24b5)
## 志望理由<br><br>
### ・これまで学習してきた事を実践投入して社会のサービスの向上に貢献したい為<br><br>
### ・業務を通じて個人開発では実感しづらい設計や仕組みの旨味の部分を体感したい為<br><br>
### ・普段の勉強会への参加などを通じてIT業界の雰囲気を心地よく感じる為<br><br>
### ・Swiftへの興味が尽きない為<br><br>
## 以上４つの理由により現在iOSエンジニアを志望しています。<br><br>

<br>

### ・父親がエンジニアでしたのでプログラムに興味は持っていました。

### ・１９８４年生まれの39歳です。プログラムを書き出して2年程経ちます。奈良県在住で既婚です。かなりスタートに遅れを取っていることは承知しております。<br><br>
### ・営業チームのリーダーをしておりましたので、顧客折衝が得意です。<br><br>

### ・長く営業関係の仕事をしてきましたが、記憶に残る様な大きなクレームは記憶にありません。（思い出せない？）<br><br>

### ・僭越ではありますが、PMを目指したいと考えており、顧客折衝の上手なエンジニアを目標とします。<br><br>

### ・スクラム及びスクラムマスターに興味があります。<br><br>

### ・オンライン・オフライン問わず勉強会への参加を好んでおり、登壇、発信に一層力を入れたいと思っています。<br><br>


### ・勤務体系は通勤を出来るだけ希望し、雇用形態、給与等の希望はありません。<br><br><br><br><br><br><br><br><br>








# OtokuEveryday
⚠️READMEまだまだ作成途中です。

## 説明
 「今日のお得」「明日のお得」「来月のお得」も年間カレンダーから簡単にチェックできる「お得エブリデイ」

フード、レジャー、ビューティー、サブスクなどのジャンルからもお得情報を検索可能！

さらにあなたの近くのお得がマップで確認できるので、自宅の近所はもちろん、休日のお出掛け先や旅行でどこにいても近くのお得を逃しません。

飲食店やレジャー施設などの実店舗、ショッピングサイト、ポイ活に最適なアプリなどのお得情報をご紹介しています。
 
![完成版6 5インチ修正ラスト？ 001](https://user-images.githubusercontent.com/78495222/233771373-bb67a410-37c7-4bdc-a8a8-55ce6de0ae2e.png)
## アプリ内使用技術でのプロポーザル申し込み履歴 
### ・iOSDC Japan 2023（採択戴きました！）
<img width="400" alt="スクリーンショット 2023-06-25 18 18 44" src="https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/1d38f95d-5b1b-4a19-88a5-e70629c5c020">
<img width="400" alt="スクリーンショット 2023-06-25 18 20 44" src="https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/0acbe12b-6d74-4251-8125-159d4eac6d7c">
---
<img width="400" alt="スクリーンショット 2023-10-22 23 40 55" src="https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/31cbbec3-3861-4ce5-9e68-cbeb2e48f020">

### [↑上記の内容で参加ブログを書いています。](https://note.com/ojioji0523/n/nd7c511dedc97)

---
### ・iOSDC Japan 2022(残念ながら落選)
<img width="400" alt="スクリーンショット 2023-06-25 18 20 29" src="https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/170fd570-4bf3-49d9-8f27-a7a1e7fc81d8">
<img width="400" alt="スクリーンショット 2023-06-25 18 15 14" src="https://github.com/AkiraUeda0523/OtokuEveryday/assets/78495222/ef6d8d45-81b6-4e19-b6e8-908bffb966fb">

## 環境

- Language：Swift
- Version：2.4.1
- Xcode：14.3.1
- URL：[App Store](https://apps.apple.com/jp/app/%E3%81%8A%E5%BE%97%E3%82%A8%E3%83%96%E3%83%AA%E3%83%87%E3%82%A4/id1601815598
) 
- Architecture：MVVM


## 使用技術
- RxSwift
- Swinject
- UICollectionViewCompositionalLayout
- Firebase/Firestore
- Firebase/Realtime Database
- Firebase/InAppMessaging
- RealmSwift
- AdMob

---
 ## このプロジェクトの開発において、工夫した点など
### ・機能実装は基本的にRxSwiftを使用しています。
---
### ・データベースのバージョンを管理し、必要に応じて更新
```swift
 if UserDefaults.standard.value(forKey: "storedVersion") == nil {
            UserDefaults.standard.set(0, forKey: "storedVersion")
        }
        let config = Realm.Configuration(
            schemaVersion: 2, // 現在のスキーマのバージョン
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // スキーマのバージョンが 0 の場合、プライマリーキーを追加
                    migration.enumerateObjects(ofType: OtokuDataRealmModel.className()) { oldObject, newObject in
                        let id = UUID().uuidString
                        newObject!["id"] = id
                    }
                }
            })
        let currentSchemaVersion = config.schemaVersion
        print("Current schema version: \(currentSchemaVersion)")
        // デフォルトの Realm を設定する
        Realm.Configuration.defaultConfiguration = config
        do {
            let realm = try Realm()
            print("Realm path: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch let error as NSError {
            print("Error opening realm: \(error.localizedDescription)")
        }
```
---
### ・匿名ユーザー認証
```swift

 func authState() {
        _authStatus.accept(.retrying) // show HUD
        var handle: AuthStateDidChangeListenerHandle?
        handle = Auth.auth().addStateDidChangeListener({  [weak self] (auth, user) in
            guard let self = self else { return }
            if let currentUser = user, currentUser.isAnonymous {
                self._authStatus.accept(.anonymous)
                if let handle = handle {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            } else {
                self.retrySignInAnonymously()
            }
        })
    }
    
    func retrySignInAnonymously() {
        if retryCount < maxRetryCount {
            retryCount += 1
            let delay = Double(pow(2.0, Double(retryCount)))
            let workItem = DispatchWorkItem { [weak self] in
                Auth.auth().signInAnonymously { (authResult, error) in
                    guard let self = self else { return }
                    if let user = authResult?.user, error == nil {
                        print("匿名サインインに成功しました", user.uid)
                        self._authStatus.accept(.anonymous)
                    } else {
                        print("匿名サインインに失敗しました:" ,error!.localizedDescription)
                        if self.retryCount == self.maxRetryCount {
                            self._authStatus.accept(.error("リトライ回数を超えました。匿名サインインに失敗しました: \(error!.localizedDescription)"))
                        } else {
                            self._authStatus.accept(.retrying) // show HUD
                            self.retrySignInAnonymously()
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
```
・Firebase Authを使用して現在のユーザー認証状態を確認
・すでに匿名ユーザーとしてログインしているかをチェック
・初回の認証が失敗した場合や、ログインしていない場合に匿名ユーザーとしての再認証を試みる
・リトライの回数制限や、指数バックオフを用いた遅延リトライを行う
認証状態のUI反映:
・認証状態に応じてUIの状態（HUDの表示やエラーメッセージ）を更新

---
### ・FireBaseの選別
・データ数が３０００以上あるため、FireStoreではなくRealTimeDataBaseを採用しました。

---
### ・MapKitのstatus紛失時の挙動を制御する
バックグラウンドでの位置情報更新を有効にしていない場合、アプリがバックグラウンドに移行すると位置情報の更新が停止します。

---
### ・Map切り替え時の動作のもっさり感解消へ
・セグメントごとにアノテーションを管理選別はinit内で既にできている

・ピンの数が多いので差し替え作業に時間を要している。

・ピンの再利用、ピンが削除され、再作成されるのではなく、既存のピンを再利用することも検討。

・今回はセグメント数が２つと少ない為、単純に2画面方式（セグメント切り替えでisHidden）に落ち着く。

ただ今後仮に切り替え数が増えると画面だらけになって大変だと感じる為今回の様な状態には適していると感じる。

---
### ・データバインディング
```swift
 ViewController.swift

 private func collectionViewObserveList() {
        otokuCollectionView.delegate = nil
        otokuCollectionView.dataSource = nil
        calendarViewModel
            .output
            .showableInfosObservable
            .observe(on: MainScheduler.instance)
            .bind(to: otokuCollectionView.rx.items(cellIdentifier: cellId, cellType: OtokuCollectionViewCell.self)) { row, element, cell in
                cell.otokuLabel.text = element.article_title
                let url = URL(string: element.collectionView_image_url) ?? URL(string: self.defaultImageUrl)!
                if url.absoluteString == self.defaultImageUrl {
                    cell.otokuImage.contentMode = .scaleAspectFit
                } else {
                    cell.otokuImage.contentMode = .scaleAspectFill
                }
                cell.otokuImage.af.setImage(withURL: url, imageTransition: .crossDissolve(0.5))
            }
            .disposed(by: disposeBag)
    }

```

・bind(to: otokuCollectionView.rx.items(cellIdentifier: cellId, cellType: OtokuCollectionViewCell.self)) { row, element, cell in ... } (データソースメソッドで言うところのcellForItemAt)

・セクション数が明示的に定義していないため、デフォルトのセクション数1（データソースメソッドで言うところのnumberOfSections(in:)）

・observe(on: MainScheduler.instance).bind(to: otokuCollectionView.rx.items(...))（Observableが発行するアイテムの数が、セクション内のアイテム数に対応。データソースメソッドで言うところのnumberOfItemsInSection）

---
### ・AdMob広告を表示しています
```swift

extension SetAdMobModel: SetAdMobModelInput{
    func setAdMob(viewWidthSize:CGFloat,Self:UIViewController) {
        let AdMobID = ""
        var admobView = GADBannerView()
        admobView = GADBannerView(adSize:GADAdSizeBanner)
        admobView.frame.size = CGSize(width:viewWidthSize, height:admobView.frame.height)
        admobView.adUnitID = AdMobID
        admobView.rootViewController = Self
        admobView.load(GADRequest())
        self.SetAdMobModelRelay.accept(admobView)
    }
}
```
---
### ・アップデートを促す
```swift

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
```
・自動アップデートを設定されていない方向けに新しいバージョンが配信された際通知を出します

---

### ・データ同期とUI更新の制御
```swift
func bindFetchData() {
        let realm = try! Realm()
        let otokuDataBox = realm.objects(OtokuDataRealmModel.self)
        
        if otokuDataBox.isEmpty {
            fetchDataFromFirebaseAndUpdate()
        } else {
            let versionRef = Database.database().reference().child("version")
            let timeoutSeconds = 5.0
            DispatchQueue.global().asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                if !(self?.isUIUpdated ?? false) {
                    self?.updateUIFromRealmData()
                }
            }
            versionRef.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else { return }
                if let currentVersion = snapshot.value as? Int,
                   let storedVersion = UserDefaults.standard.value(forKey: "storedVersion") as? Int,
                   storedVersion < currentVersion {
                    self.fetchDataFromFirebaseAndUpdate()
                } else if !self.isUIUpdated {
                    self.updateUIFromRealmData()
                }
            }
        }
    }
    func fetchDataFromFirebaseAndUpdate() {
        DispatchQueue.global().async { 
            let ref = Database.database().reference().child("OtokuDataModelsObject")
            ref.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self, let otokuData = snapshot.value as? [Any] else { return }
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(realm.objects(OtokuDataRealmModel.self))
                    var otokuDataModels = [OtokuDataRealmModel]()
                    for element in otokuData {
                        if element is NSNull { continue }
                        guard let i = element as? [String: Any] else { continue }
                        if let otokuDataModel = OtokuDataRealmModel.from(dictionary: i) {
                            otokuDataModels.append(otokuDataModel)
                        }
                    }
                    realm.add(otokuDataModels, update: .modified)
                }
                
                let versionRef = Database.database().reference().child("version")
                versionRef.observeSingleEvent(of: .value) { snapshot in
                    if let currentVersion = snapshot.value as? Int {
                        UserDefaults.standard.set(currentVersion, forKey: "storedVersion")
                    }
                    DispatchQueue.main.async {
                        self.updateUIFromRealmData()
                    }
                }
            }
        }
    }
    func updateUIFromRealmData() {
        DispatchQueue.main.async { // メインスレッド
            let otokuDataList = self.mapOtokuDataFromRealm()
            self.calendarModel.accept(otokuDataList)
            self.isUIUpdated = true
        }
```
・データの同期:Realmデータベースからのデータの取得
Firebaseからの新しいデータの取得とRealmデータベースへのアップデート

・バージョン管理を通じたデータの新鮮さの確認:保存されているバージョンとFirebaseのバージョンを比較
新しいバージョンのデータがあればデータを更新

・UIの更新:Realmデータベースから取得したデータをもとにUIを更新

---

### ・CoreLocation 内のCLGeocoderクラスを使い倒す
```swift
 ViewModel.swift


 modelBoxObservable
            .map { boxs in
                boxs.filter { $0.address.longitude == nil || $0.address.latitude == nil }
            }
            .compactMap(\.first)
            .subscribe(onNext: { [weak self] box in
                guard let content = box.address.content, !content.isEmpty else {
                    self?.moveModelBoxFirstIfNeeded()
                    return
                }
                sleep(5)
                self?.addressGeocoder.geocodeAddressString(content) { [weak self] placemarks, error in
                    guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
                        self?.moveModelBoxFirstIfNeeded()
                        return
                    }
                    self?.db.collection("map_ addresses")
                        .document(box.id)
                        .setData(
                            [
                                "latitude": coordinate.latitude as Any,
                                "longitude": coordinate.longitude as Any
                            ],
                            merge: true
                        ) { err in
                            if err != nil {
                                self?.moveModelBoxFirstIfNeeded()
                            }
                        }
                }
            })
            .disposed(by: disposeBag)
```


```swift
 ViewModel.swift



 private func moveModelBoxFirstIfNeeded() {
        if self.addAnnotationRetryCount < 500 && self.selectSegmentIndexType == 0{
            self.addAnnotationRetryCount += 1
            let currentValue = todaysAnnotationModel.value
            guard currentValue.count >= 2 , let removeId = currentValue.first(where: {$0.address.longitude == nil})
                .map(\.id)
            else { return }
            let result: [OtokuMapModel] = currentValue.filter{$0.id != removeId}
            todaysAnnotationModel.accept(result)
        } else if self.addAnnotationRetryCount < 500 && self.selectSegmentIndexType == 1{
            self.addAnnotationRetryCount += 1
            let currentValue = allDaysAnnotationModel.value
            guard currentValue.count >= 2 , let removeId = currentValue.first(where: {$0.address.longitude == nil})
                .map(\.id)
            else { return }
            let result: [OtokuMapModel] = currentValue.filter{$0.id != removeId}
            allDaysAnnotationModel.accept(result)
        }
    }
```
・map操作 : ボックスのリストから、経度または緯度が`nil`のボックスをフィルタリングします。これは、地理座標情報がまだ設定されていないボックスのみを取得します。

・compactMap操作 : フィルタリングされたボックスのリストの最初の要素（存在する場合）を取得します。

・subscribe(onNext:)操作 : ここで、フィルタリングされたリストの最初のボックスが`nil`でないか、また、そのボックスのアドレス内容が空でないことをチェックします。これらの条件が満たされない場合、`moveModelBoxFirstIfNeeded`メソッドが呼び出されます。

`moveModelBoxFirstIfNeeded`メソッドは、条件により、現在のアノテーションモデルから特定の要素を削除する役割を果たします。
経度がnilの最初のアノテーションが削除されます。これはリトライメカニズムの一部として機能します。

このように、`moveModelBoxFirstIfNeeded()`を使用することでGeocoderの制約を交わしつつ限界まで使い回すことができる。

---
### ・Compositional LayoutにおけるUIPageControlの活用
```swift
func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            if GALLERY_SECTION.contains(section) {
                let sectionLayout = LayoutBuilder.rectangleHorizonContinuousWithFooterSection(collectionViewBounds: self.collectionView.bounds)
                sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
                    guard let self = self else { return }
                    guard !visibleItems.isEmpty else { return }
                    // Find the item that is closest to the center of the screen
                    let centerOffset = offset.x + self.collectionView.bounds.width / 2
                    var smallestDistance = CGFloat.infinity
                    var closestIndex = 0
                    for item in visibleItems {
                        let distance = abs(item.frame.midX - centerOffset)
                        if distance < smallestDistance {
                            smallestDistance = distance
                            closestIndex = item.indexPath.item
                        }
                    }
                    DispatchQueue.main.async {
                        let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section)) as? FooterView
                        footer?.pageControl.currentPage = closestIndex
                    }
                }
                return sectionLayout
            } else if TEXT_SECTION.contains(section) {
                return LayoutBuilder.buildTextSectionLayout()
            } else if LIST_SECTION.contains(section) {
                let sectionLayout = LayoutBuilder.buildHorizontalTableSectionLayout(collectionViewBounds: self.collectionView.bounds)
                sectionLayout.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, _ in
                    guard let self = self else { return }
                    guard !visibleItems.isEmpty else { return }
                    let centerOffset = offset.x + self.collectionView.bounds.width / 2
                    var smallestDistance = CGFloat.infinity
                    var closestIndex = 0
                    for item in visibleItems {
                        let distance = abs(item.frame.midX - centerOffset)
                        if distance < smallestDistance {
                            smallestDistance = distance
                            closestIndex = item.indexPath.item
                        }
                    }
                    let closestGroupIndex = closestIndex / 3
                    DispatchQueue.main.async {
                        let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section)) as? FooterView
                        footer?.pageControl.currentPage = closestGroupIndex
                    }
                }
                return sectionLayout
            }
            return LayoutBuilder.buildHorizontalTableSectionLayout(collectionViewBounds: self.collectionView.bounds)
        }
        return layout
    }
```
UIPageControlの動作判定には`visibleItemsInvalidationHandler`を利用しました。
`UICollectionView`のセクションで現在表示されているアイテム（セル）に関する情報を取得し、それを用いて特定の操作を実行するためのハンドラーです。

スクロール中のセクションで画面中央に最も近いアイテムを特定し、そのアイテムのインデックス情報を取得し、セクションのフッタービューに配置されたページコントロールの現在のページを更新します。
これにより、ユーザーは自分が何ページ目を見ているのかを判断できます。
この操作は、ユーザーがスクロールしたときに動的に行われます。

---

### ・ネットワークの状態によってのデータ取得方法の分岐

```swift
 FetchCommonDataModel.swift

 func bindFetchData() {
        print("bindFetchData called")
        isConnectedToNetwork { [weak self] isConnected in
            guard let self = self else { return }
            
            if isConnected {
                self.handleNetworkConnected()
            } else {
                self.updateUIFromRealmData() // If no network connectivity, use local data.
            }
        }
    }

    private func handleNetworkConnected() {
        if dataStorage.isEmpty() {
            fetchDataFromFirebaseAndUpdate()
            return
        }

        dataFetcher.fetchVersion()
            .subscribe(onNext: { [weak self] currentVersion in
                self?.handleVersionFetched(currentVersion: currentVersion)
            }, onError: { [weak self] _ in
                self?.updateUIFromRealmData() // In case of an error, use local data.
            })
            .disposed(by: disposeBag)
    }

    private func handleVersionFetched(currentVersion: Int) {
        guard let storedVersion = versionManager.storedVersion else {
            updateUIFromRealmData()
            return
        }

        if storedVersion < currentVersion {
            fetchDataFromFirebaseAndUpdate()
            shouldUpdateData.accept(true)
        } else {
            updateUIFromRealmData()
        }
    }


    func isConnectedToNetwork(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
            monitor.cancel() // Once we get the status, we can stop the monitor.
        }
        monitor.start(queue: queue)
    }
 
```
ネットワークの接続状態を確認し、それに基づいて最新のデータを取得するか、ローカルのデータを使用してUIを更新するかを決定する。

---
## 使用ライブラリ一覧
Alamofire,RxSwift,
  RxCocoa,
  RxDataSources,Firebase/Core,Firebase/Auth,
  Firebase/Storage,
  Firebase/Firestore,
  Firebase/Database,
  Firebase/Analytics,
  Firebase/InAppMessaging,
  Google-Mobile-Ads-SDK,
  SDWebImage,
  FSCalendar,
  ViewAnimator,
  PKHUD,
  CalculateCalendarLogic,
  SVGKit,
  PinLayout,
  AlamofireImage, 
  RealmSwift,
  Nuke, 
  RxTest,
  RxBlocking,Swinject

---
## 機能一覧
- 匿名認証
- AdMob広告
- 位置情報

## テスト
- 単体テスト(model層)
 
## 注意点
 こちらのリポジトリはビルドは通りません

 

 

 

