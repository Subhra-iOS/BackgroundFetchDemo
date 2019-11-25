//
//  AppDelegate.swift
//  BackgroundFetchDemo
//
//  Created by Subhra Roy on 24/11/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import UIKit
import BackgroundTasks

private  let url : String = "https://stgappapi.e-arc.com/api/banner/get"

private typealias  BackgroundFetchHandler = (UIBackgroundFetchResult) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private  var  responseData : Data?
    private var  backgroundDataFetchHandler : BackgroundFetchHandler?
    private weak var rootController : ViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
          self.responseData = Data()
          UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        //registerBackgroundTaks()
       // registerLocalNotification()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        fetchDataFromServerWith(handler: completionHandler)
       
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
       // cancelAllPendingBGTask()
        //scheduleAppRefresh()
    }


}

//MARK:-------API call using URL Session----------//
extension  AppDelegate{
    
    private  func getViewController() -> ViewController?{
        return  self.rootController
    }
    
    public func setRootController(controller : ViewController?) {
        self.rootController = controller
    }
    
    private func fetchDataFromServerWith(handler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        self.backgroundDataFetchHandler = handler
        
        let sessionConfigue = URLSessionConfiguration.background(withIdentifier: "Background")
        let session = URLSession(configuration: sessionConfigue, delegate: self, delegateQueue: nil)
        let dataTask = session.dataTask(with: URL(string: url)!)
        dataTask.resume()
        
    }
}

extension  AppDelegate : URLSessionDataDelegate {
    
     public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void){
        
        if(dataTask.state == URLSessionTask.State.canceling) {
            
            completionHandler(.cancel)
            return
            
        }else{
                
                if let urlResponse : HTTPURLResponse = response as? HTTPURLResponse{
                    
                    let httpsResponse : HTTPURLResponse = urlResponse
                    let statusCode = httpsResponse.statusCode
                    if statusCode == 200 {
                        
                        completionHandler(.allow)
                    }else{
                        
                        completionHandler(.cancel)
                    }
                }
        }
        
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask){
        
    }
    
      func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data){
          
          if(dataTask.state == URLSessionTask.State.canceling) {
              
              return
              
          }else{
              
             self.responseData?.append(data)
          }
          
      }
  
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        
        // Check if the operation has been cancelled
        if(task.state == URLSessionTask.State.canceling){
            
            return
        }
            // Check if the operation has been Suspended
        else if(task.state == URLSessionTask.State.suspended) {
            
            return
        }
        
        if let errorInfo = error{
            
            print("Session error: \(errorInfo.localizedDescription)")
    
        }
        else{
            
            if let data : Data = self.responseData{
                
                 if let _ = error {
                        self.backgroundDataFetchHandler?(.failed)
                   }else{
                       
                       do{
                           let responseDict : Any = try JSONSerialization.jsonObject(with: data, options: [])
                           print("\(responseDict)")
                       }catch{
                           
                       }
                        self.backgroundDataFetchHandler?(.newData)
                        let  msg : String = "UI has been updated"
                        DispatchQueue.main.async { [unowned self]  in
                            if let vc : ViewController = self.getViewController() {
                                vc.updateUI(statusStr: msg)
                            }
                        }
                   }
            }
            
        }
        
    }
    
}

extension AppDelegate{
    
    private func cancelAllPendingBGTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.SO.apprefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // App Refresh after 1 minute.
        //Note :: EarliestBeginDate should not be set to too far into the future.
        do {
        try BGTaskScheduler.shared.submit(request)
        } catch {
        print("Could not schedule app refresh: \(error)")
        }
    }
    //MARK: Register BackGround Tasks
    private func registerBackgroundTaks() {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.SO.apprefresh", using: nil) { task in
            //This task is cast with processing request (BGAppRefreshTask)
            self.scheduleLocalNotification()
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }
    
   private  func handleAppRefreshTask(task: BGAppRefreshTask) {
          //Todo Work
          /*
           //AppRefresh Process
           */
          task.expirationHandler = {
              //This Block call by System
              //Canle your all tak's & queues
          }
          scheduleLocalNotification()
          //
          task.setTaskCompleted(success: true)
      }
    
}

//MARK:- Notification Helper
extension AppDelegate {
    
    func registerLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    func scheduleLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.fireNotification()
            }
        }
    }
    
    func fireNotification() {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Bg"
        notificationContent.body = "BG Notifications."
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "local_notification", content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
}

