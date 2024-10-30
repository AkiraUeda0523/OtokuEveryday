//
//  MockFirestoreWrapper.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//
@testable import RedMoon2021

class MockFirestoreWrapper: FirestoreWrapperProtocol {
    var setDataCalledWith: (documentPath: String, data: [String: Any], merge: Bool)?
    var collectionCalledWith: String?
    var documentCalledWith: String?
    func setData(documentPath: String, data: [String: Any], merge: Bool, completion: @escaping (Error?) -> Void) {
        setDataCalledWith = (documentPath, data, merge)
        let components = documentPath.split(separator: "/")
        if components.count == 2 {
            collectionCalledWith = String(components[0])
            documentCalledWith = String(components[1])
        }
        completion(nil)
    }
}
