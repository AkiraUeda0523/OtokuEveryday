//
//  FirestoreProtocol.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/10/31.
protocol FirestoreWrapperProtocol {
    func setData(documentPath: String, data: [String: Any], merge: Bool, completion: @escaping (Error?) -> Void)
}
