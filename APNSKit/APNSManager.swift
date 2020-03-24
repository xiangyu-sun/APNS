//
//  APNSManager.swift
//  APNSMobile
//
//  Created by Alex on 5/31/17.
//  Copyright © 2017 Uriphium. All rights reserved.
//


import Foundation
import Security

public struct APNServiceResponse {
    public var serviceStatus:(Int, APNServiceStatus)
    public var serviceErrorReason:APNServiceErrorReason?
    public var apnsId:String?
}

/// Apple Push Notification Message
public struct ApplePushMessage {
    /// Message Id
    public let messageId:String = UUID().uuidString
    /// Application BundleID
    public let topic:String
    /// APNS Priority 5 or 10
    public let priority:Int
    /// APNS Payload aps {...}
    public let payload:Dictionary<String,Any>
    /// Device Token without <> and whitespaces
    public let deviceToken:String
    /// Path for P12 certificate
    public let certificatePath:String
    /// Passphrase for certificate
    public let passphrase:String
    /// Use sandbox server URL or not
    public let sandbox:Bool


    public init(topic:String, priority:Int, payload:Dictionary<String,Any>, deviceToken:String, certificatePath:String, passphrase:String, sandbox:Bool = true) {
        self.topic = topic
        self.priority = priority
        self.payload = payload
        self.deviceToken = deviceToken
        self.certificatePath = certificatePath
        self.passphrase = passphrase
        self.sandbox = sandbox
    }
}


public class APNSNetwork: NSObject{
    fileprivate var secIdentity:SecIdentity?
    static fileprivate var session:URLSession?
    public static let shared = APNSNetwork()
    
    override init() {
        super.init()
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        APNSNetwork.session = session
    }
    
    
    public func sendPushWithMessage(_ message:ApplePushMessage, completed: ((APNServiceResponse)->())?, onError: ((Error?) -> ())?) throws {

        let url = serviceURLFor(sandbox: message.sandbox, token: message.deviceToken)
        var request = URLRequest(url: url)
        
        guard let ind = getIdentityWith(certificatePath: message.certificatePath, passphrase: message.passphrase) else {
            return
        }
        self.secIdentity = ind
        
        let data = try JSONSerialization.data(withJSONObject: message.payload, options: JSONSerialization.WritingOptions(rawValue: 0))
        request.httpBody = data
        request.httpMethod = "POST"
        request.addValue(message.topic, forHTTPHeaderField: "apns-topic")
        request.addValue("\(message.priority)", forHTTPHeaderField: "apns-priority")
        
        let task = APNSNetwork.session?.dataTask(with: request, completionHandler:{ (data, response, err) -> Void in
            
            guard err == nil else {
                onError?(err)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                onError?(err)
                return
            }
            
            let (statusCode, status) = APNServiceStatus.statusCodeFrom(response: response)
            let httpResponse = response
            let apnsId = httpResponse.allHeaderFields["apns-id"] as? String
            var responseStatus = APNServiceResponse(serviceStatus: (statusCode, status), serviceErrorReason: nil, apnsId: apnsId)
            
            guard status == .success else {
                let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0))
                guard let js = json as? Dictionary<String,Any>,
                    let reason = js["reason"] as? String
                    else {
                        return
                }
                let serviceReason = APNServiceErrorReason(rawValue: reason)
                responseStatus.serviceErrorReason = serviceReason
                completed?(responseStatus)
                return
            }
            responseStatus.apnsId = apnsId
            completed?(responseStatus)
        })
        task?.resume()
    }
}

extension APNSNetwork: URLSessionDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var cert : SecCertificate?
        SecIdentityCopyCertificate(self.secIdentity!, &cert)
        let credentials = URLCredential(identity: self.secIdentity!, certificates: [cert!], persistence: .forSession)
        completionHandler(.useCredential,credentials)
    }
}

extension APNSNetwork {
    internal func getIdentityWith(certificatePath:String, passphrase:String) -> SecIdentity? {
        let PKCS12Data = try? Data(contentsOf: URL(fileURLWithPath: certificatePath))
        let key : String = kSecImportExportPassphrase as String
        let options = [key : passphrase]
        var items : CFArray?
        let ossStatus = SecPKCS12Import(PKCS12Data! as CFData, options as CFDictionary, &items)
        guard ossStatus == errSecSuccess else {
            return nil
        }
        let arr = items!
        if CFArrayGetCount(arr) > 0 {
            let newArray = arr as [AnyObject]
            let dictionary = newArray[0]
            let secIdentity = dictionary.value(forKey: kSecImportItemIdentity as String) as! SecIdentity
            return secIdentity
        }
        return nil
    }
    
    fileprivate func serviceURLFor(sandbox:Bool, token:String) -> URL {
        var serviceStrUrl:String?
        switch sandbox {
        case true: serviceStrUrl = "https://api.development.push.apple.com:443/3/device/"
        case false: serviceStrUrl = "https://api.push.apple.com:443/3/device/"
        }
        return URL(string: serviceStrUrl! + token)!
    }
}
