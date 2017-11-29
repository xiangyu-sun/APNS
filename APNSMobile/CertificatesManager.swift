//
//  CertsManager.swift
//  APNSMobile
//
//  Created by xiangyu sun on 9/11/17.
//  Copyright © 2017 Emirates. All rights reserved.
//

import Foundation

class CertificatesManager {
    static let shared = CertificatesManager()
    
    let certsCacheFolderPath = Bundle.main.url(forResource: "cerificates", withExtension: nil)!
    
    var configuration: [String : [String : String]]
    init() {
        let data = try! Data(contentsOf: certsCacheFolderPath.appendingPathComponent("info.json"))
        
        let info = try! JSONSerialization.jsonObject(with: data, options: [])
        
        configuration = info as! [String : [String : String]]
    }
    
    func pathForCert(name:String) -> String? {
        return Bundle.main.path(forResource: name, ofType: "p12", inDirectory: "cerificates")
    }
}
