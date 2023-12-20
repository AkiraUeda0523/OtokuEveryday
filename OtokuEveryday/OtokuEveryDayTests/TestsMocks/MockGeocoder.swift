////
////  AddressGeocoderMock.swift
////  RedMoon2021Tests
////
////  Created by 上田晃 on 2023/08/08.
////
///
@testable import RedMoon2021
import MapKit

class MockGeocoder: AddressGeocoder {
    private let result: MKPlacemark?
    private let error: Error?
    var completionHandler: (() -> Void)?
    
    init(result: MKPlacemark?, error: Error?) {
        self.result = result
        self.error = error
    }
    func geocodeAddressString(_ addressString: String, completionHandler: @escaping CLGeocodeCompletionHandler) {
        completionHandler([result].compactMap { $0 }, error)
        self.completionHandler?()
    }
    
    func reverseGeocodeLocation(_ location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler) {
        completionHandler([result].compactMap { $0 }, error)
        self.completionHandler?()
    }
}
