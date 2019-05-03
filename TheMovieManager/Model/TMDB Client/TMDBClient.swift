//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "17ef7e136e80c8b85418e6fef5026226"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case getFavorites
        case search(String)
        case markWatchlist
        case markFavorite
        case posterImage(String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                //ova so addinPercent e zatoa sto vo patekata praznoto mesto _ e zameneto so %
            case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam
            case.markFavorite: return Endpoints.base + "acount/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .posterImage(let posterPath): return "https://image.tmdb.org/t/p/w500" + posterPath
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    //DELETE request
    class func logout(completion: @escaping () -> Void){
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LogoutRequest(sessionID: Auth.sessionId)
        request.httpBody = try! JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completion()
        }
        task.resume()
        
    }
    
    //Refactoring POST
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void){
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                completion (nil, error)
            }
        }
        task.resume()
    }
    
    //POST request
    class func markFavorite(movieId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void) {
        
        let body = MarkFavorite(mediaType: "movie", mediaId: movieId, favorite: favorite)
        taskForPOSTRequest(url: Endpoints.markFavorite.url, responseType: TMDBResponse.self, body: body) {(response, error) in
            
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completion (false, error)
            }
        }
    }
    
    class func markWatchlist(movieId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
        
        let body = MarkWatchlist(mediaType: "movie", mediaId: movieId, watchlist: watchlist)
        taskForPOSTRequest(url: Endpoints.markWatchlist.url, responseType: TMDBResponse.self, body: body) {(response, error) in
            
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completion (false, error)
            }
            
        }
    }
    
    class func createSessionId(completion: @escaping (Bool, Error?)-> Void ){
        
        let body = PostSession(requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.createSessionId.url, responseType: SessionResponse.self, body: body) {(response, error) in
            
            if let response = response {
                Auth.sessionId = response.sessionId
                completion(true, nil)
            } else{
                completion(false, error)
            }
        }
    }

    class func login(username: String, password: String, completion: @escaping (Bool, Error?)-> Void) {
       
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.login.url, responseType: RequestTokenResponse.self, body: body) {(response, error) in

            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            } else {
                completion(false, nil)
            }
        }
    }

   //Refactoring GET request
   @discardableResult class func taskForGETRequest<ResponseType:Decodable>(url:URL, response:ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void)-> URLSessionTask{
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
               return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                     completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                     completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
    }
    
     // GET request
    class func search(query:String, completion: @escaping ([Movie], Error?)->Void)->URLSessionTask{
        let task = taskForGETRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
        return task
    }

    class func getFavorites(completion: @escaping ([Movie], Error?)-> Void){
        taskForGETRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void){
        
        taskForGETRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
                if let response = response {
                    completion(response.results, nil)
                } else {
                completion([], error)
            }
        }
    }
    
    class func downloadPosterImage(path: String, completion: @escaping(Data?, Error?)->Void){
        let task = URLSession.shared.dataTask(with: Endpoints.posterImage(path).url) {
            data,response,error in
            DispatchQueue.main.async {
                completion(data,error)
            }
        }
        task.resume()
    }
}
