//
//   AddressGeocoderProtocol.swift
//  RedMoon2021
//
//  Created by 上田晃 on 2023/10/31.
//
import MapKit

protocol AddressGeocoder {
    func reverseGeocodeLocation(_ location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler)
    
    func geocodeAddressString(_ addressString: String, completionHandler: @escaping CLGeocodeCompletionHandler)
}//現状使っていない
