//
//  FormViewController.swift
//  APNSMobile
//
//  Created by 孙翔宇 on 6/4/17.
//  Copyright © 2017 Uriphium. All rights reserved.
//

import UIKit
import Eureka
import APNsCore

enum Priority :Int{
    case conservesPower = 5
    case immediately = 10
}
class APNSFormViewController: FormViewController {
    var payload :String?
    var deviceToken :String?
    var certName :String?
    var topic: String?
    var priority = Priority.immediately
    var sandBox: Bool{
        get{
            return UserDefaults.standard.bool(forKey: "sandBox")
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "sandBox")
            UserDefaults.standard.synchronize()
        }
    }
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/jsons")
    
    let tokenPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/token")
    
    func sha256(data: Data) -> Data {
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            data.withUnsafeBytes {messageBytes in
                CC_SHA256(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }
        return digestData
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !FileManager.default.fileExists(atPath: tokenPath!) {
            try! FileManager.default.createDirectory(atPath: tokenPath!, withIntermediateDirectories: true, attributes: nil)
        }
        deviceToken = UserDefaults.standard.object(forKey: "token") as? String ?? "2DAED506D2C0E6E483B706CF0DD580813973AACAA71DE927A020398F30D5D7DA"
        
        
        self.topic  = CertificatesManager.shared.configuration.keys.first

        self.certName = CertificatesManager.shared.configuration.first?.value.keys.first
        
        form +++ Section("APNS")
            <<< TextRow(){ row in
                row.title = "Device Token"
                row.value = deviceToken
            }.onChange({ (apns) in
                self.deviceToken = apns.value
                UserDefaults.standard.setValue(apns.value, forKey: "token")
            })
            <<< PickerInlineRow<String>() {
                $0.title = "Topic"
                $0.value = self.topic
                $0.options = CertificatesManager.shared.configuration.keys.map{$0}
                }.onChange({ (picker) in
                    self.topic = picker.value
                })
            
            <<< TextAreaRow("payload") {
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 150)
                $0.value = payload
            }.onChange({ (text) in
               
                guard let data = text.value?.data(using: .utf8) else{
                    return
                }
                
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                let fData = try? JSONSerialization.data(withJSONObject: json!, options: .prettyPrinted)
                
                let fPayload = String(bytes: fData!, encoding: .utf8)
                self.payload = fPayload
                
            })
            
            
            <<< PickerInlineRow<String>() {
                $0.title = "Certificate"
                $0.value = self.certName
                $0.options = CertificatesManager.shared.configuration.flatMap{ $1.keys.first }
                }.onChange({ (picker) in
                    self.certName = picker.value
                })
            
            <<< PickerInlineRow<Priority>() {
                $0.title = "Priotity"
                $0.value = self.priority
                $0.options = [.conservesPower, .immediately]
                }.onChange({ (picker) in
                    self.priority = picker.value ?? Priority.immediately
                })
            
            <<< SwitchRow(){
                $0.title = "Sandbox"
                $0.value = self.sandBox
                }.onChange({ (on) in
                   self.sandBox = on.value ?? false
                })

            <<< ButtonRow (){
                $0.title = "Send"
                }.onCellSelection { cell, row in
                    self.send()
        }
            <<< ButtonRow (){
                $0.title = "Send with Delay of 5s"
                }.onCellSelection { cell, row in
                    self.send(delay: 5)
        }
        
        NotificationCenter.default.addObserver(forName: .loadObject, object: nil, queue: nil) { (noti) in
            
            let payload = noti.userInfo?["payload"] as? String
            
            guard let data = payload?.data(using: .utf8) else{
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            
            let fData = try? JSONSerialization.data(withJSONObject: json!, options: .prettyPrinted)
            
            let fPayload = String(bytes: fData!, encoding: .utf8)
            
            if let row = self.form.rowBy(tag: "payload") as? TextAreaRow {
                row.value = fPayload
                row.reload(with: .none)
            }else{
                self.payload = fPayload
            }
        }
    }
    
    

    func send(delay:Int=0) {
        
        guard let ps = self.payload,
            let topic = self.topic,
            let certName = self.certName,
            let passphrase = CertificatesManager.shared.configuration[topic]?[certName]
            else {
            return
        }
        var payload =  [String: Any]()
        
        do{
            payload = try JSONSerialization.jsonObject(with: ps.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            
        }catch{
            let alert = UIAlertController(title: "", message: "JSON Format not right", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (alert) in
                
            }))
            self.present(alert, animated: true, completion: {
                
            })
        }
        
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delay)) {
            
            let str = CertificatesManager.shared.pathForCert(name: certName)!
            let mess = ApplePushMessage(topic: topic,
                                        priority: self.priority.rawValue,
                                        payload: payload,
                                        deviceToken: self.deviceToken!,
                                        certificatePath:str,
                                        passphrase: passphrase,
                                        sandbox: self.sandBox)

            do {
                try APNSNetwork.shared.sendPushWithMessage(mess, completed: { (response) in
                    print(response)
                    let testHash = self.sha256(data:ps.data(using: .utf8)!)
                    
                    let filePath = "\(self.path!)/\(testHash.map { String(format: "%02hhx", $0) }.joined())"
                    print(filePath)
                    try! ps.write(toFile: filePath, atomically: true, encoding: .utf8)
                }, onError: { (error) in
                    let alert = UIAlertController(title: nil, message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                        
                    }))
                    self.present(alert, animated: true, completion: {
                        
                    })
                })
            }catch let error {
                
                let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                    
                }))
                self.present(alert, animated: true, completion: {
                    
                })
            }
        }
    }
}
