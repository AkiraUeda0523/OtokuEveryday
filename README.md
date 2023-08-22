# OtokuEveryday
⚠️こちらREADME現在作成途中です。
・出社
・PM（主任）
・受託

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
- Firebase/Firestore
- Firebase/Realtime Database
- Firebase/InAppMessaging
- RealmSwift
- AdMob
- Swinject
---
 ## このプロジェクトの開発において、工夫した点など
### ・MapKitのstatus紛失時の挙動を制御する
バックグラウンドでの位置情報更新を有効にしていない場合、アプリがバックグラウンドに移行すると位置情報の更新が停止します。
### ・Map切り替え時の動作のもっさり感解消へ
１. セグメントごとにアノテーションを管理選別はinit内で既にできている

２.　　という事は単純にピンの数が多いので差し替え作業に時間を要している。

３. ピンの再利用、ピンが削除され、再作成されるのではなく、既存のピンを再利用することも検討。

４.　　ただ今回はセグメント数が２つと少ない為、単純に2画面方式（セグメント切り替えでisHidden）に落ち着く。
ただ今後仮に切り替え数が増えると画面だらけになって大変だと感じる為今回の様な状態には適していると感じる。

### ・RxSwiftとRxCocoaのバインディングを使用して、UICollectionViewにデータを表示
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
### ・
### ・

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


### ・Compositional LayoutにおけるUISegmentedControlの活用
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
UISegmentedControlの動作判定には`visibleItemsInvalidationHandler`を利用しました。
`UICollectionView`のセクションで現在表示されているアイテム（セル）に関する情報を取得し、それを用いて特定の操作を実行するためのハンドラーです。

スクロール中のセクションで画面中央に最も近いアイテムを特定し、そのアイテムのインデックス情報を取得し、セクションのフッタービューに配置されたページコントロールの現在のページを更新します。
これにより、ユーザーは自分が何ページ目を見ているのかを判断できます。
この操作は、ユーザーがスクロールしたときに動的に行われます。

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
## 機能一覧
- 匿名認証
- 位置情報検索機能

## テスト
- 単体テスト(model)
- 
- 
 
## 注意点
 

 

 

 

