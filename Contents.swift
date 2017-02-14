//code for oAuth from http://rshankar.com/retrieve-list-of-twitter-followers-using-swift/

import UIKit
import PlaygroundSupport

let session = URLSession.shared
let consumerKey = "XXX"
let consumerSecret = "XXX"
let host = ""
let authURL = "https://api.twitter.com/oauth2/token"

// MARK:- Bearer Token
func getBearerToken(completion:@escaping (_ bearerToken: String) ->Void) {
    
    let components = NSURLComponents()
    components.scheme = "https";
    components.host = host
    components.path = "/oauth2/token";
    
    let request = NSMutableURLRequest(url: URL(string :authURL)!)
    request.httpMethod = "POST"
    request.addValue("Basic " + getBase64EncodeString(), forHTTPHeaderField: "Authorization")
    request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
    let grantType =  "grant_type=client_credentials"
    
    request.httpBody = grantType.data(using: String.Encoding.utf8, allowLossyConversion: true)
    
    let task:  URLSessionDataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
        do {
            if let results: NSDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments  ) as? NSDictionary {
                if let token = results["access_token"] as? String {
                    completion(token)
                } else {
                    print(results["errors"] ?? "error but no error message")
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    })
    task.resume()
}

// MARK:- base64Encode String

func getBase64EncodeString() -> String {
    
    let consumerKeyRFC1738 = consumerKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    
    let consumerSecretRFC1738 = consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    
    let concatenateKeyAndSecret = consumerKeyRFC1738! + ":" + consumerSecretRFC1738!
    
    let secretAndKeyData = concatenateKeyAndSecret.data(using: String.Encoding.ascii, allowLossyConversion: true)
    
    let base64EncodeKeyAndSecret = secretAndKeyData?.base64EncodedString(options: [])  //base64EncodedStringWithOptions(NSData.Base64EncodingOptions())
    
    return base64EncodeKeyAndSecret!
}

// MARK:- Service Call

func searchForTweets(searchString: String) {
    
    getBearerToken(completion: { (bearerToken) -> Void in
        
        let baseUrl = "https://api.twitter.com/1.1/search/tweets.json?count=20"
        guard let encodedRequest = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {return}
        let searchOptions =  "-filter:retweets"
        let finalUrl = baseUrl + "&q=" + encodedRequest + searchOptions
        
        let firstRequest = NSMutableURLRequest(url: NSURL(string: finalUrl) as! URL)
        firstRequest.httpMethod = "GET"
        
        let token = "Bearer " + bearerToken
        
        firstRequest.addValue(token, forHTTPHeaderField: "Authorization")
        
        let firstTask: URLSessionDataTask = session.dataTask(with: firstRequest as URLRequest, completionHandler: { (firstTaskData, firstTaskResponse, firstTaskError) -> Void in
            
            if firstTaskError != nil {
                print("Error: \(firstTaskError)")
            }
            
            do {
                guard let unwrappedData = firstTaskData else { print("no data back on sendTwitterRequest"); return}
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: [])
                let jsonAsDict = json as? [String:Any]
                let statusesAsDict = jsonAsDict?["statuses"] as! [[String:Any]]
                
                for status in statusesAsDict {
                    guard let text = status["text"],
                        let time = status["created_at"],
                        let tweetID = status["id_str"] as? String,
                        let user = status["user"] as? [String:Any],
                        let screenName = user["screen_name"]
                        else {continue}
                    
                    print("Tweet: \(text) Time: \(time) by screenName: \(screenName) ")
                    
                }
            } catch let jsonError as NSError {
                print("json error: \(jsonError.localizedDescription)")
            }
        })
        firstTask.resume()
    })
}

PlaygroundPage.current.needsIndefiniteExecution = true

searchForTweets(searchString: "Grammys")






