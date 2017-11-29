//
//  JSONFileManager.swift
//  APNSMobile
//
//  Created by xiangyu sun on 6/29/17.
//  Copyright © 2017 Emirates. All rights reserved.
//

import Foundation

class JSONFileManager {
    static let shared = JSONFileManager()
    
    let fileManager = FileManager.default
    
    let JSONCacheFolderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/jsons")
    
    let JSONTemplatesCacheFolderPath = Bundle.main.path(forResource: "templates", ofType: nil)
    
    
    var userContents: [[String:[FileAttributeKey:Any]]]!
    var templateContents: [String]!
    
    init() {
        reloadData()
    }
    
    func reloadData() {
        let JSONCacheFolderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/jsons")
        do {
            if !FileManager.default.fileExists(atPath: JSONCacheFolderPath){
                try FileManager.default.createDirectory(atPath: JSONCacheFolderPath, withIntermediateDirectories: true, attributes: nil)
            }
            userContents = try FileManager.default.contentsOfDirectory(atPath: JSONCacheFolderPath).map({ (path) in
                let filePath = JSONCacheFolderPath.appending("/\(path)")
                let att = try FileManager.default.attributesOfItem(atPath: filePath)
                return [path:att]
            }).sorted(by: { (info1, info2) -> Bool in
                return (info1.values.first![FileAttributeKey.creationDate] as! Date) >= (info2.values.first![FileAttributeKey.creationDate] as! Date)
            })
            
            templateContents = try FileManager.default.contentsOfDirectory(atPath: JSONTemplatesCacheFolderPath!)
        }catch {
            userContents = []
            templateContents = []
        }
    }
    
}
