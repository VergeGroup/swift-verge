//
//  APIRequests.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Moya

enum APIRequests {
  
  static func token(code: Auth.AuthCode) -> AuthRequest {
                     
    .init(
      path: "token",
      method: .post,
      headers: ["Authorization" : "Basic \("\(Secret.clientID):\(Secret.clientSecret)".data(using: .utf8)!.base64EncodedString())"],
      task: .requestParameters(
        parameters: [
          "redirect_uri" : Auth.callBackURI,
          "grant_type" : "authorization_code",
          "code" : code.raw
        ],
        encoding: URLEncoding.default
      )
    )
  }
  
  static func me() -> Templates.JSONResponse.Auth.Request {
    .init(
      path: "me",
      method: .get,
      headers: [:],
      task: .requestParameters(
        parameters: [:],
        encoding: URLEncoding.default
      )
    )
  }
  
}

public protocol SpotifyRequestType : TargetType {
}

extension SpotifyRequestType {
  public var baseURL: URL {
    URL(string: "https://api.spotify.com/v1")!
  }
  
  public var sampleData: Data {
    return Data()
  }
  
}

public protocol RequestTemplate {
  
  init(path: String, method: Moya.Method, headers: [String : String]?, task: Task)
}

public struct AuthRequest: RequestTemplate, TargetType {
  
  public var baseURL: URL {
    URL(string: "https://accounts.spotify.com/api/")!
  }
  
  public var sampleData: Data {
    return Data()
  }
  
  public var path: String
  public var method: Moya.Method
  public var headers: [String : String]?
  public var task: Task
  
  public init(path: String, method: Moya.Method, headers: [String : String]?, task: Task) {
    self.path = path
    self.method = method
    self.headers = headers
    self.task = task
  }
}

public enum Templates {
  
  public enum JSONResponse {
    
    public enum Auth {
      
      public struct Request: RequestTemplate, SpotifyRequestType, AccessTokenAuthorizable {
        
        public var path: String
        public var method: Moya.Method
        public var headers: [String : String]?
        public var task: Task
        
        public var authorizationType: AuthorizationType {
          .bearer
        }
        
        public init(path: String, method: Moya.Method, headers: [String : String]?, task: Task) {
          self.path = path
          self.method = method
          self.headers = headers
          self.task = task
        }
      }
      
    }
    
    public enum NoAuth {
      
      public struct Request: RequestTemplate, SpotifyRequestType {
        
        public var path: String
        public var method: Moya.Method
        public var headers: [String : String]?
        public var task: Task
        
        public init(path: String, method: Moya.Method, headers: [String : String]?, task: Task) {
          self.path = path
          self.method = method
          self.headers = headers
          self.task = task
        }
      }
      
    }
    
  }
}
