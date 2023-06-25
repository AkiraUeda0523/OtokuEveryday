# OtokuEveryday
⚠️こちらREADME現在作成途中です。
## 説明
 「今日のお得」「明日のお得」「来月のお得」も年間カレンダーから簡単にチェックできる「お得エブリデイ」
フード、レジャー、ビューティー、サブスクなどのジャンルからもお得情報を検索可能！
さらにあなたの近くのお得がマップで確認できるので、自宅の近所はもちろん、休日のお出掛け先や旅行でどこにいても近くのお得を逃しません。
飲食店やレジャー施設などの実店舗、ショッピングサイト、ポイ活に最適なアプリなどのお得情報をご紹介しています。
 
![完成版6 5インチ修正ラスト？ 001](https://user-images.githubusercontent.com/78495222/233771373-bb67a410-37c7-4bdc-a8a8-55ce6de0ae2e.png)
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
---
 ## このプロジェクトの開発において、工夫した点など



### 
CoreLocation 内のCLGeocoderクラスを使い倒す
```swift
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
このように、`moveModelBoxFirstIfNeeded()`を使用することでGeocoderの制約を交わしつつ限界まで使い回すことができる。

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
  RxBlocking
## 機能一覧
- 匿名認証
- 位置情報検索機能

## テスト
- 単体テスト(model)
- 
- 
 
## 注意点
 

 

 

 

