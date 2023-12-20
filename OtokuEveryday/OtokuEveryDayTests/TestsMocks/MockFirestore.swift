//
//  SharedFirebaseMock.swift
//  RedMoon2021Tests
//
//  Created by 上田晃 on 2023/10/31.
//

@testable import RedMoon2021

class MockFirestore: FirestoreProtocol {
    var collectionCalledWith: String?
    var documentCalledWith: String?
    var setDataCalledWith: [String: Any]?
    
    func collectionPath(_ path: String) -> FirestoreProtocol {
        collectionCalledWith = path
        return self
    }
    func documentPath(_ path: String) -> DocumentReferenceProtocol {
        documentCalledWith = path
        return MockDocumentReference(mockFirestore: self)
    }
    func actualSetData(_ data: [String: Any], merge: Bool, completion: ((Error?) -> Void)?) {
        setDataCalledWith = data
        completion?(nil)
    }
}

// MARK: -
class MockDocumentReference: DocumentReferenceProtocol {
    let mockFirestore: MockFirestore
    
    init(mockFirestore: MockFirestore) {
        self.mockFirestore = mockFirestore
    }
    
    func setData(_ documentData: [String: Any], merge: Bool, completion: ((Error?) -> Void)? = nil) {
        mockFirestore.setDataCalledWith = documentData
        completion?(nil)
    }
}
