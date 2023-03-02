////
////  MapViewModel.swift
////  RedMoon2021
////
////  Created by 上田晃 on 2022/09/16.
////
//
//import Foundation
//import RxSwift
//
//private let disposeBag = DisposeBag()
//
//
//
//modelBoxObservable
////        testmodelBoxObservable
//    .debug("でばっぐでばっぐ")
//    .map { boxs in//型推論省略　boxs.filter
//        boxs.filter { $0.address.longitude != nil && $0.address.latitude != nil }//.map　トランスフォーム
//    }
//    .filter{models in
//        let adresses = models.map(\.address.longitude)
//        return !adresses.contains(where: {$0 == nil})
//    }
//    .distinctUntilChanged()//状態変化無しを無視　　呼ばれる−２
//    .subscribe(onNext: { [self] boxs in//let boxs: [OtokuMapModel]ーーーーーーー[スト、スト、スト]　　呼ばれる−１
//        boxs.forEach { box in//forEachは配列や辞書などを繰り返す場合に使用　　１forEach怪しい　　　⚠️ここにゴンチャ全体同じの無限に回ってきてる　　boxsバリュー０
//            guard let latitude = box.address.latitude,//飛ぶ
//                  let longitude = box.address.longitude
//            else { return }
//            print("ちぇっくいっと",box)
//            let pin = CustomPointAnnotation()
//            pin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
//            pin.title = box.article_title
//            pin.subtitle = "ⓘ詳細を表示"
//            pin.url = box.blog_web_url
//            self.mapView.addAnnotation(pin)
//            //                    self.moveTodaysModelBoxFirstIfNeeded()
//        }
//        //               authorizedAlways(status: self.status)//ここ　２これは絶対いらん
//    })
//    .disposed(by: disposeBag)
