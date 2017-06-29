//
//  FormViewController.swift
//  APNSMobile
//
//  Created by 孙翔宇 on 6/4/17.
//  Copyright © 2017 Emirates. All rights reserved.
//

import UIKit
import Eureka
import CryptoSwift

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !FileManager.default.fileExists(atPath: tokenPath!) {
            try! FileManager.default.createDirectory(atPath: tokenPath!, withIntermediateDirectories: true, attributes: nil)
        }
        
        if !FileManager.default.fileExists(atPath: path!) {
            try! FileManager.default.createDirectory(atPath: path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        payload = try! String(contentsOf: Bundle.main.url(forResource: "NotificationPayload", withExtension: "apns")!)
        

        deviceToken = UserDefaults.standard.object(forKey: "token") as? String ?? "2D71256D9F7587CCDD195303185DB91D835EEBD32CB36081C6E65B0984C5EBFD"
        
        
        
        
        
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
                row.updateCell()
            }
        }
    }
    

    func send(delay:Int=0) {
        
        guard let ps = self.payload, let payload = try! JSONSerialization.jsonObject(with: ps.data(using: .utf8)!, options: .allowFragments) as? [String:Any] else {
            return
        }
        
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delay)) {
            let str = Bundle.main.path(forResource: self.sandbox ? "Certificates-Dev-APNS" : "Certificates", ofType: "p12")!
            var mess = ApplePushMessage(topic: "com.emirates.enterprise.EKiPhone",
                                        priority: 10,
                                        payload: payload,
                                        deviceToken: self.deviceToken!,
                                        certificatePath:str,
                                        passphrase: self.sandbox ? "12345":"123456",
                                        sandbox: self.sandbox)
            
            mess.responseBlock = { response in
                print(response)
                
                let filePath = "\(self.path!)/\(ps.md5())"
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
