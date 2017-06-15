//
//  Request.swift
//  qiskit
//
//  Created by Manoel Marques on 4/5/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation

final class Request {

    private static let HTTPSTATUSOK: Int = 200
    private static let REACHTIMEOUT: TimeInterval = 90.0
    private static let CONNTIMEOUT: TimeInterval = 120.0

    let credential: Credentials
    private var urlSession: URLSession

    init() throws {
        self.credential = try Credentials()

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.allowsCellularAccess = true
        sessionConfig.timeoutIntervalForRequest = Request.REACHTIMEOUT
        sessionConfig.timeoutIntervalForResource = Request.CONNTIMEOUT
        self.urlSession = URLSession(configuration: sessionConfig)
    }

    init(_ token: String, _ config: Qconfig? = nil) throws {
        self.credential = try Credentials(token, config)

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.allowsCellularAccess = true
        sessionConfig.timeoutIntervalForRequest = Request.REACHTIMEOUT
        sessionConfig.timeoutIntervalForResource = Request.CONNTIMEOUT
        self.urlSession = URLSession(configuration: sessionConfig)
    }

    func post(path: String, params: String = "", data: [String : Any] = [:],
              responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) {
        self.postInternal(path: path, params: params, data: data) { (json, error) in
            if error != nil {
                if case IBMQuantumExperienceError.httpError(_, let status, _) = error! {
                        if status == 401 {
                            self.credential.obtainToken(request: self) { (error) -> Void in
                                self.postInternal(path: path, params: params, data: data) { (json, error) in
                                    responseHandler(json, error)
                                }
                            }
                            return
                        }
                }
            }
            responseHandler(json, error)
        }
    }

    func postInternal(path: String, params: String = "", data: [String : Any] = [:],
                      responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) {
        guard let token = self.credential.token else {
            responseHandler([:], IBMQuantumExperienceError.missingTokenId)
            return
        }
        let fullPath = "\(path)?access_token=\(token)\(params)"
        guard let url = URL(string: fullPath, relativeTo: self.credential.config.url) else {
            responseHandler([:],
                    IBMQuantumExperienceError.invalidURL(url: "\(self.credential.config.url.description)\(fullPath)"))
            return
        }
        postInternal(url: url, data: data, responseHandler: responseHandler)
    }

    func postInternal(url: URL, data: [String : Any] = [:],
                      responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) {
        print(url.absoluteString)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: Request.CONNTIMEOUT)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let dataString = String(data: request.httpBody!, encoding: .utf8)
            print(dataString!)
        } catch let error {
            responseHandler([:], IBMQuantumExperienceError.internalError(error: error))
            return
        }
        let task = self.urlSession.dataTask(with: request) { (data, response, error) -> Void in
            if error != nil {
                responseHandler([:], IBMQuantumExperienceError.internalError(error: error!))
                return
            }
            if response == nil {
                responseHandler([:], IBMQuantumExperienceError.nullResponse(url: url.absoluteString))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                responseHandler([:], IBMQuantumExperienceError.invalidHTTPResponse(response: response!))
                return
            }
            if data == nil {
                responseHandler([:], IBMQuantumExperienceError.nullResponseData(url: url.absoluteString))
                return
            }
            do {
                if let dataString = String(data: data!, encoding: .utf8) {
                    print(dataString)
                }
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    as? [String : Any] else {
                        responseHandler([:], IBMQuantumExperienceError.invalidHTTPResponse(response: response!))
                        return
                }
                var msg = ""
                if let errorObj = json["error"] as? [String:Any] {
                    if let status = errorObj["status"] as? Int {
                        msg.append("Status: \(status)")
                    }
                    if let code = errorObj["code"] as? String {
                        msg.append("; Code: \(code)")
                    }
                    if let message = errorObj["message"] as? String {
                        msg.append("; Msg: \(message)")
                    }
                }
                if httpResponse.statusCode != Request.HTTPSTATUSOK {
                    responseHandler([:], IBMQuantumExperienceError.httpError(url: url.absoluteString,
                                                                             status: httpResponse.statusCode, msg: msg))
                    return
                }
                responseHandler(json, nil)
            } catch let error {
                responseHandler([:], IBMQuantumExperienceError.internalError(error: error))
            }
        }
        task.resume()
    }

    func get(path: String, params: String = "", with_token: Bool = true,
             responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) {
        self.getInternal(path: path, params: params, with_token: with_token) { (json, error) in
            if error != nil {
                if case IBMQuantumExperienceError.httpError(_, let status, _) = error! {
                    if status == 401 {
                        self.credential.obtainToken(request: self) { (error) -> Void in
                            self.getInternal(path: path, params: params, with_token: true) { (json, error) in
                                responseHandler(json, error)
                            }
                        }
                        return
                    }
                }
            }
            responseHandler(json, error)
        }
    }

    private func getInternal(path: String, params: String = "", with_token: Bool = true,
                             responseHandler: @escaping ((_:[String:Any], _:IBMQuantumExperienceError?) -> Void)) {
        var access_token = ""
        if with_token {
            if let token = self.credential.token {
                access_token = "?access_token=\(token)"
            }
            else {
                responseHandler([:], IBMQuantumExperienceError.missingTokenId)
                return
            }
        }
        let fullPath = "\(path)\(access_token)\(params)"
        guard let url = URL(string: fullPath, relativeTo:self.credential.config.url) else {
            responseHandler([:],
                IBMQuantumExperienceError.invalidURL(url: "\(self.credential.config.url.description)\(fullPath)"))
            return
        }
        print(url.absoluteString)
        var request = URLRequest(url:url, cachePolicy:.reloadIgnoringLocalCacheData,
                                 timeoutInterval:Request.CONNTIMEOUT)
        request.httpMethod = "GET"
        let task = self.urlSession.dataTask(with: request) { (data, response, error) -> Void in
            if error != nil {
                responseHandler([:], IBMQuantumExperienceError.internalError(error: error!))
                return
            }
            if response == nil {
                responseHandler([:], IBMQuantumExperienceError.nullResponse(url: url.absoluteString))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                responseHandler([:], IBMQuantumExperienceError.invalidHTTPResponse(response: response!))
                return
            }
            if data == nil {
                responseHandler([:], IBMQuantumExperienceError.nullResponseData(url: url.absoluteString))
                return
            }
            do {
                if let dataString = String(data: data!, encoding: .utf8) {
                    print(dataString)
                }
                guard let json = try JSONSerialization.jsonObject(with: data!,
                                    options: .allowFragments) as? [String : Any] else {
                    responseHandler([:], IBMQuantumExperienceError.invalidHTTPResponse(response: response!))
                    return
                }
                var msg = ""
                if let errorObj = json["error"] as? [String:Any] {
                    if let status = errorObj["status"] as? Int {
                        msg.append("Status: \(status)")
                    }
                    if let code = errorObj["code"] as? String {
                        msg.append("; Code: \(code)")
                    }
                    if let message = errorObj["message"] as? String {
                        msg.append("; Msg: \(message)")
                    }
                }
                if httpResponse.statusCode != Request.HTTPSTATUSOK {
                    responseHandler([:], IBMQuantumExperienceError.httpError(url: url.absoluteString,
                                                                             status: httpResponse.statusCode, msg: msg))
                    return
                }
                responseHandler(json, nil)
            } catch let error {
                responseHandler([:], IBMQuantumExperienceError.internalError(error: error))
            }
        }
        task.resume()
    }
}
