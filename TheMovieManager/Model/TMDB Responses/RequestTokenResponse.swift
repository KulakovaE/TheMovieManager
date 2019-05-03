//
//  RequestTokenResponse.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct RequestTokenResponse: Codable {
    let success: Bool
    let expireDate: String
    let requestToken: String

    enum CodingKeys: String, CodingKey{
        case success = "success"
        case expireDate = "expires_at"
        case requestToken = "request_token"
    }
}


