//
//  ViewController.swift
//  BrickHack-Mobile
//
//  Created by Christopher Baudouin, Jr. on 11/13/18.
//  Copyright © 2018 codeRIT. All rights reserved.
//

import UIKit
import OAuth2
import Alamofire

let environment = "https://staging.brickhack.io"
let authorizeRoute = "\(environment)/oauth/authorize"
let currentUserRoute = "\(environment)/oauth/token/info"
let todaysStatsDataRoute = "\(environment)/manage/dashboard/todays_stats_data"
let trackableTagsRoute = "\(environment)/manage/trackable_tags.json"
let trackableEventsRoute = "\(environment)/manage/trackable_events.json"
let trackableEventsRouteByUserRoute = "\(environment)/manage/trackable_events.json?trackable_event[user_id]="
let networkReachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton?

    var oauth2 = OAuth2ImplicitGrant(settings: [
        "client_id": "a46ad487beade18ee2868fb9b6a6de69950f3a5bd7b2d5eb3fb62e35f53c120e",
        "authorize_uri": authorizeRoute,
        "redirect_uris": ["brickhack-ios://oauth/callback"],
        "scope": ""] as OAuth2JSON)

    @IBAction func initializeOAuth(_ sender: UIButton) {
        if hasInternetAccess(){
            if oauth2.isAuthorizing {
                oauth2.abortAuthorization()
                return
            }
            
            sender.setTitle("AUTHORIZING...", for: UIControl.State.normal)
            sender.isEnabled = false
            
            oauth2.authConfig.authorizeEmbedded = true
            oauth2.authConfig.authorizeContext = self
            
            oauth2.logger = OAuth2DebugLogger(.trace)
            
            oauth2.authorize(){responce, error in
                print("Authorizing...")
                if error != nil{
                    self.didCancelOrFail(error, sender: sender)
                    print("Authorization denied.")
                }else if self.oauth2.hasUnexpiredAccessToken(){
                    print("Authorization successful.")
                    self.performSegue(withIdentifier: "authSuccessSegue", sender: self)
                    self.resetLoginButton(sender)
                }
            }
        }else{
            displayNoNetworkAlert()
        }
    }
    
    func didCancelOrFail(_ error: Error?, sender: UIButton) {
        DispatchQueue.main.async {
            if let error = error {
                print("Authorization went wrong: \(error)")
            }
            self.resetLoginButton(sender)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if hasInternetAccess(){
            if oauth2.hasUnexpiredAccessToken(){
                self.performSegue(withIdentifier: "authSuccessSegue", sender: self)
            }
        }
    }
    
    func resetLoginButton(_ sender: UIButton){
        sender.setTitle("LOGIN WITH BRICKHACK.IO »", for: UIControl.State.normal)
        sender.isEnabled = true
    }
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "authSuccessSegue"){
            let navigationController  = segue.destination as! UINavigationController
            let menuView = navigationController.topViewController as? HomeViewController
            menuView?.oauth2 = self.oauth2
        }
    }
    
    func hasInternetAccess() -> Bool{
        if networkReachabilityManager?.isReachable ?? false{
            return true
        }else{
            return false
        }
    }
    
    func displayNoNetworkAlert(){
        let alertController = UIAlertController(
            title: "Network Issue",
            message: "An issue occured with your network. Please be sure you are connected to the internet.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
