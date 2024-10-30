//
//  FirestoreWrapper.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2024/01/15.
//
import Foundation
import FirebaseFirestore
class FirestoreWrapper: FirestoreWrapperProtocol {
    func setData(documentPath: String, data: [String: Any], merge: Bool, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        db.document(documentPath).setData(data, merge: merge, completion: completion)
    }
}
