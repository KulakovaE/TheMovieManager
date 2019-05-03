//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        setLoggingIn(true)
        TMDBClient.getRequestToken(completion: handleRequestTokenResponse(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        setLoggingIn(true)
        TMDBClient.getRequestToken{(success, error) in
            if success {
                UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
            }
        }
        //performSegue(withIdentifier: "completeLogin", sender: nil)
    }
    
    func handleRequestTokenResponse(success: Bool, error: Error?){
        if success {
            print(TMDBClient.Auth.requestToken)
                TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:error:))
        }
    }
    
    func handleLoginResponse(success: Bool, error: Error?){
        print(TMDBClient.Auth.requestToken)
        if success {
            TMDBClient.createSessionId(completion: handleSessionResponse(success:error:))
        }
    }
    
    func handleSessionResponse(success: Bool, error: Error?){
        setLoggingIn(false)
        if success{
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }
    }
    func setLoggingIn(_ logginIn: Bool){
        if logginIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !logginIn
        passwordTextField.isEnabled = !logginIn
        loginButton.isEnabled = !logginIn
        loginViaWebsiteButton.isEnabled = !logginIn
    }
}
