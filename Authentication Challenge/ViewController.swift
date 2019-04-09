//
//  ViewController.swift
//  Authentication Challenge
//
//  Created by Denis Bystruev on 09/04/2019.
//  Copyright © 2019 Denis Bystruev. All rights reserved.
//
//  From https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var resultView: UITextView!
    
    @IBAction func goButtonPressed(_ sender: UIButton) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        show(message: "\(formatter.string(from: Date()))", clear: true)
        
        guard let urlText = urlField.text, !urlText.isEmpty, let url = URL(string: urlText) else {
            show(message: "URL is empty or mailformed")
            return
        }
        
        sender.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            sender.isEnabled = true
        }
        
        let configuration = URLSession.shared.configuration
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
        
            if let data = data {
                self.show(message: "\(data) received")
                if let text = String(data: data, encoding: .utf8) {
                    self.show(message: text)
                }
            }
            
            if let error = error {
                self.show(message: "Error: \(error.localizedDescription)")
            }
        }
        task.resume()
        
    }
}

// MARK: - URLSessionTaskDelegate
extension ViewController: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authMethod = challenge.protectionSpace.authenticationMethod
        
        guard authMethod == NSURLAuthenticationMethodHTTPBasic || authMethod == NSURLAuthenticationMethodDefault else {
            self.show(message: "Error: unknown authentication method")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        DispatchQueue.main.async {
            guard let credentials = self.credentialsFromUI() else {
                self.show(message: "Error: credentials are empty or mailformed")
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            completionHandler(.useCredential, credentials)
        }
    }
}

// MARK: - Custom Methods
extension ViewController {
    func credentialsFromUI() -> URLCredential? {
        guard let username = self.usernameField.text, !username.isEmpty,
            let password = self.passwordField.text, !password.isEmpty else {
                return nil
        }
        
        return URLCredential(user: username, password: password, persistence: .forSession)
    }
    
    func show(message: String, clear: Bool = false) {
        DispatchQueue.main.async {
            let text = clear ? "" : self.resultView.text ?? ""
            self.resultView.text = "\(text)\n\(message)"
        }
    }
}
