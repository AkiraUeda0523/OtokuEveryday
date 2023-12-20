//
//  FirestoreProtocol.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/10/31.
//

protocol FirestoreProtocol {
    func collectionPath(_ path: String) -> FirestoreProtocol
    func documentPath(_ path: String) -> DocumentReferenceProtocol
    func actualSetData(_ data: [String: Any], merge: Bool, completion: ((Error?) -> Void)?) //現状使っていない
}

protocol DocumentReferenceProtocol {
    func setData(_ documentData: [String: Any], merge: Bool, completion: ((Error?) -> Void)?)
}
