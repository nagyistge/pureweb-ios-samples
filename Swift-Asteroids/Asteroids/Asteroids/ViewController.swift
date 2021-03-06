//
//  ViewController.swift
//  Asteroids
//
//  Created by Jonathan Neitz on 2016-02-10.
//  Copyright © 2016 Calgary Scientific Inc. All rights reserved.
//

import UIKit
import PureWeb

class ViewController: UIViewController, PWWebClientDelegate {

    var appUrl = NSURL()
    var authenticationRequired = false
    var authenticationCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        
        if(authenticationRequired && !authenticationCompleted) {
            performSegueWithIdentifier("PresentLoginView", sender: self)
            
        } else if(!authenticationRequired) {
            let framework = PWFramework.sharedInstance()
            
            if(!framework.client().isConnected) {
                framework.client().connect(appUrl.absoluteString)
            }
            
            performSegueWithIdentifier("PresentAsteroidsView", sender: self)
        }
    }
    
    func setupWithAppURL(url: NSURL, authenticationRequired auth:Bool) {
        PWFramework.sharedInstance().client().delegate = self;
        
        self.appUrl = url;
        self.authenticationRequired = auth
    }
    
    func connectedChanged() {
        let connected = PWFramework.sharedInstance().client().isConnected
        
        if connected {
            
            print("Connected Successfully")
            authenticationCompleted = true
            
            if authenticationRequired {
                dismissViewControllerAnimated(true, completion: {
                    self.performSegueWithIdentifier("PresentAsteroidsView", sender: self)
                })
            }
        }
    }
    
    func sessionStateChanged() {
        switch PWFramework.sharedInstance().client().sessionState {
            
        case .Disconnected:
            // Notify users that the session has been disconnected
            dispatch_async(dispatch_get_main_queue(),{
                    let message = "Session has lost connection to service.\n Reopen the application to begin a new connection."
                    let alertController = UIAlertController(title: "Session Disconnected", message: message, preferredStyle: .Alert)
                    self.presentViewController(alertController, animated: true, completion: nil)
            });
            break
            
        case .Failed:
            //the attempted session failed, this likely means the supplied credentials were invalid or the connection was lost
            dispatch_async(dispatch_get_main_queue(),{
                self.dismissViewControllerAnimated(true, completion:{
                    var message = PWFramework.sharedInstance().client().acquireException.description;
                    //PWLogError(@"Connection Failed With Error %@", message);
                    
                    if message.isEmpty {
                        message = "Connection attempt failed"
                    }
                    
                    let alert = UIAlertController(title: "Asteroids", message: message, preferredStyle: .Alert)
                    
                    let okAction = UIAlertAction(title: "Ok", style: .Default, handler: { (action:UIAlertAction) in
                        self.authenticationRequired = false
                        self.authenticationCompleted = false
                    })
                    
                    alert.addAction(okAction)
                    if ( !self.authenticationCompleted && !PWFramework.sharedInstance().client().isConnected){
                    self.presentViewController(alert, animated: true, completion: nil)
                    }
                });
            });
            break
        default:break
        }
    }
    
    
    func processLoginCredentials(username:String, password:String) {
        let framework = PWFramework.sharedInstance();
        
        let authInfo = PWBasicAuthorizationInfo(name: username, password: password)
        framework.client().authorizationInfo = authInfo;
        
        print("Connecting PureWeb framework")
        framework.client().connect(appUrl.absoluteString);
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destController = segue.destinationViewController as? LoginViewController {
            
            destController.processLoginCredentials = processLoginCredentials
        }
    }
}
