//
//  FormViewController.swift
//  APNSMobile
//
//  Created by 孙翔宇 on 6/4/17.
//  Copyright © 2017 Emirates. All rights reserved.
//

import UIKit
import Eureka

class APNSFormViewController: FormViewController {
    var payload :String?
    var deviceToken :String?
    var sandbox = UserDefaults.standard.bool(forKey: "sandbox"){
        didSet{
            UserDefaults.standard.set(sandbox, forKey: "sandbox")
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
        
        
        
        
        
        form +++ Section("APNS")
            <<< TextRow(){ row in
                row.title = "Device Token"
                row.value = deviceToken
            }.onChange({ (apns) in
                self.deviceToken = apns.value
                UserDefaults.standard.setValue(apns.value, forKey: "token")
            })
            <<< TextAreaRow("payload") {
                $0.textAreaHeight = .dynamic(initialTextViewHeight: 150)
                $0.value = payload
            }.onChange({ (text) in
                self.payload = text.value
            })
            
            <<< SwitchRow (){
                $0.title = "SandBox"
                $0.value = self.sandbox
        }.onChange({ (aSwitch) in
            self.sandbox = aSwitch.value!
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
            if let row = self.form.rowBy(tag: "payload") as? TextAreaRow {
                row.value = noti.userInfo?["payload"] as? String
                row.reload(with: .none)

            }
            
   
        }
    }
    
    

    func send(delay:Int=0) {
        
        guard let ps = self.payload, let payload = try! JSONSerialization.jsonObject(with: ps.data(using: .utf8)!, options: .allowFragments) as? [String:Any] else {
            return
        }
        
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delay)) {
            let str = Bundle.main.path(forResource: self.sandbox ? "Certificates-Dev" : "CertificatesDev_ENT", ofType: "p12")!
            var mess = ApplePushMessage(topic: "com.emirates.enterprise.EKiPhone.dev",
                                        priority: 10,
                                        payload: payload,
                                        deviceToken: self.deviceToken!,
                                        certificatePath:str,
                                        passphrase: self.sandbox ? "12345":"123123",
                                        sandbox: self.sandbox)
            
            mess.responseBlock = { response in
                print(response)
                let testHash = self.sha256(data:ps.data(using: .utf8)!)
           
                let filePath = "\(self.path!)/\(testHash.map { String(format: "%02hhx", $0) }.joined())"
                print(filePath)
                try! ps.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
            
            
            
            mess.networkError = { err in
                if let error = err {
                    let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                        
                    }))
                    self.present(alert, animated: true, completion: {
                        
                    })
                }
            }
            do {
                _ = try mess.send()
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
