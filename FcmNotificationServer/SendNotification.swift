//
//  SendNotification2.swift
//  FcmNotificationServer
//
//  Created by Giwoo Kim on 5/29/24.

import Foundation
import JWTKit
import OAuth2

struct  MyPayload: JWTPayload {
    func verify(using signer: JWTKit.JWTSigner) throws {
      
    }
    
    let iss: String // 발급자
    let scope: String // 스코프
    let aud: String // 대상자
    let exp: Int // 만료 시간
    let iat: Int // 발급 시간
}

class SendNotification {

    
    
    var accessToken: String = ""
    var tokenExpiryDate: Date? = nil
    var fcmToken: String = "cpo_X_YyoE90qTIzhI0CtW:APA91bFAM3TRcBRlh2afZK35Oc-3f2CjQxM-mGTtcLUCjeZ9mG9ZYxrNIXzuWnyNQQjgkS_FFE7nIGDLhd_hNRYh_3iqHedcGBmBszg6D4zYIgp_Ftte4yNJiMJtZ6SDgOKXWT9jNj65"

    struct ServiceAccount: Codable {
        let type: String
        let project_id: String
        let private_key_id: String
        let private_key: String
        let client_email: String
        let client_id: String
        let auth_uri: String
        let token_uri: String
        let auth_provider_x509_cert_url: String
        let client_x509_cert_url: String
    }
    
    struct GoogleAccessTokenResponse: Codable {
        let access_token: String
        let expires_in: Int
        let token_type: String
    }
    
    func getAccessToken(serviceAccountFile: String, completion: @escaping (String?) -> Void) {
        print("tokenExpiryDate \(String(describing: tokenExpiryDate))")
        
        
        if let expiryDate = tokenExpiryDate, expiryDate > Date() , accessToken != ""  {
            completion(accessToken)
            return
        }
        
        guard let serviceAccountURL = Bundle.main.url(forResource: serviceAccountFile, withExtension:  nil),
              let keyData = try? Data(contentsOf: serviceAccountURL),
              let keyJSON = try? JSONSerialization.jsonObject(with: keyData, options: []) as? [String: Any],
              let clientEmail = keyJSON["client_email"] as? String,
              let privateKey = keyJSON["private_key"] as? String,
              let privateKeyId = keyJSON["private_key_id"] as? String else {
         
            print("Error reading service account key file.")
            completion(nil)
            return
        }
        print("client Email  \(clientEmail)")
        // JWT 클레임 구성
        let tokenURI = "https://oauth2.googleapis.com/token"
        let scope = "https://www.googleapis.com/auth/firebase.messaging"
        let currentTime = Int(Date().timeIntervalSince1970)
        let expiryTime = currentTime + 3600 * 1// 1시간 유효
        
        let payload  = MyPayload(iss: clientEmail, scope: scope, aud: tokenURI, exp: expiryTime, iat: currentTime)
        
        
        do {
            // JWT 서명자 생성 및 JWT 서명
            let signer = try JWTSigner.rs256(key: .private(pem: privateKey.data(using: .utf8)!))
            let jwt = try signer.sign(payload, kid: JWKIdentifier(string: privateKeyId))
            //  print("JWT: \(jwt)")
        
            var request = URLRequest(url: URL(string: tokenURI)!)
            request.httpMethod = "POST"
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
            request.httpBody = body.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error:", error?.localizedDescription ?? "Unknown error")
                    completion(nil)
                    return
                }
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    print("HTTP 상태 코드:", httpStatus.statusCode)
                    completion(nil)
                    return
                }
                do {
                    let tokenResponse = try JSONDecoder().decode(GoogleAccessTokenResponse.self, from: data)
                   
                    self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
                    
                    if let tokenExpiryDate = self.tokenExpiryDate {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .short // or .medium, .long, .full
                        dateFormatter.timeStyle = .short // or .medium, .long, .full
                        
                        let formattedDate = dateFormatter.string(from: tokenExpiryDate)
                        print("tokenExpiryDate \(formattedDate)")
                    } else {
                        print("tokenExpiryDate is nil")
                    }

                    completion(tokenResponse.access_token)
                } catch {
                    print("Error decoding access token response: \(error)")
                    completion(nil)
                }
            }
            task.resume()
            
        } catch {
            print("Error decoding service account key file: \(error)")
            completion(nil)
        }
    }
    
    func sendPushNotification() {
        let url = URL(string: "https://fcm.googleapis.com/v1/projects/croaksproject/messages:send")!
        var request = URLRequest(url: url)
        
        self.getAccessToken(serviceAccountFile: "croaksproject-firebase-adminsdk-anwwd-c3c5246e76.json") { token in
            if let token = token {
                self.accessToken = token
                
                print("accessToken from getAccessToken:\n")
                print(self.accessToken)
                
                let headers = [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(self.accessToken)",
                ]
                
                request.httpMethod = "POST"
                request.allHTTPHeaderFields = headers
                
//                let parameters: [String: Any] = [
//                    "message": [
//                        "token": self.fcmToken,
//                        "notification": [
//                            "title": "Hi Croaks~~",
//                            "body": "Good Morning From FCM~"
//                        ]
//                    ]
//                ]
//                
               
                let payload: [String: Any] = [
                    "message": [
                        "token": self.fcmToken,
                       
                        "apns": [
                            "headers": [
                                "apns-push-type": "background",
                                "apns-priority": "5",
                                "apns-topic": "com.gw.andy.Croak"
                            ],
                            "payload": [
                                "aps": [
                                    "content-available": 1
                                ]
                            
                            ]
                        ]
                    ]
                ]

                
//                request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
//                print("HTTP Method: \(request.httpMethod ?? "No Method Specified")")
//                
//                if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
//                    print("HTTP Body: \(bodyString)")
//                } else {
//                    print("No HTTP Body")
//                }
//                
//                let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                    guard let data = data, error == nil else {
//                        print("Error:", error?.localizedDescription ?? "Unknown error")
//                        return
//                    }
//                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
//                        print("HTTP 상태 코드:", httpStatus.statusCode)
//                        return
//                    }
//                    let responseString = String(data: data, encoding: .utf8)
//                    print("응답 데이터: \(responseString ?? "")")
//                }
//                task.resume()
//                
//                sleep(3)
                
                
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                print("HTTP Method: \(request.httpMethod ?? "No Method Specified")")
                
                if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("HTTP Body: \(bodyString)")
                } else {
                    print("No HTTP Body")
                }
                
                let task2 = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {
                        print("Error:", error?.localizedDescription ?? "Unknown error")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        print("HTTP 상태 코드:", httpStatus.statusCode)
                        return
                    }
                    let responseString = String(data: data, encoding: .utf8)
                    print("응답 데이터: \(responseString ?? "")")
                }
                task2.resume()
              
            } else {
                print("token is lost")
            }
        }
    }
}


