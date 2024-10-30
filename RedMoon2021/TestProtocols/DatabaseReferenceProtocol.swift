//
//  DatabaseReferenceProtocol.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/12/23.
//
import Foundation
import Firebase
protocol DatabaseReferenceProtocol {
    func observeSingleEvent(of eventType: DataEventType, with block: @escaping (DataSnapshot) -> Void)
}
