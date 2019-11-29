//
//  AppDelegate.swift
//  BackgroundFetchDemo
//
//  Created by Subhra Roy on 24/11/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import UIKit
import BackgroundTasks

public enum Result : Error{
    
    case Success
    case Failure(String)
    
}

private  let serviceURL : String = "Your Fetch URL"

private typealias  BackgroundFetchHandler = (UIBackgroundFetchResult) -> Void

@available(iOS 13.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    private var  backgroundDataFetchHandler : BackgroundFetchHandler?
    private weak var rootController : ViewController?
    private var appBGTask : BGTask?
    private var downloadOp : SRDownloadOperation?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
         
     //   if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.Dev.apprefresh", using: nil) {  [unowned self] task in
               self.handleAppRefresh(task: task as! BGAppRefreshTask)
            } //DispatchQueue.global()
      //  } else {
               // UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
       // }
       
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
    
//    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//
//            fetchDataFromServerWith(handler: completionHandler)
//
//    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.scheduleAppRefresh()
        
    }
    private func fetchDataFromServerWith(handler: @escaping (UIBackgroundFetchResult) -> Void){
           self.backgroundDataFetchHandler = handler
           let queue = OperationQueue()
           queue.maxConcurrentOperationCount = 1
           
            self.downloadOp  = self.createOperationToFetch()
            self.downloadOp?.operationDidFinishHnadler { [unowned self] (response, state) in
                print("\(String(describing: response))")
               
               if state {
                   self.backgroundDataFetchHandler?(.newData)
               }else{
                    self.backgroundDataFetchHandler?(.failed)
               }
               
                let  msg : String = "UI has been updated"
                DispatchQueue.main.async { [unowned self]  in
                    if let vc : ViewController = self.getViewController() {
                        vc.updateUI(statusStr: msg)
                    }
                }
            }
           
           queue.addOperation(self.downloadOp!)
           self.downloadOp = nil
       }
       
    private  func getViewController() -> ViewController?{
          return  self.rootController
      }
      
      public func setRootController(controller : ViewController?) {
          self.rootController = controller
      }
    
    private func createOperationToFetch() -> SRDownloadOperation{
           
           let downloader : SRDownloadOperation = SRDownloadOperation()
           do{
               
            let _ = try downloader.initiate(serviceURL, hashIdentifier: "12345", progress: false)
               
           }catch{
               
           }
           return  downloader
       }

}
//MARK:------------iOS13-----------------------//
@available(iOS 13.0, *)
extension AppDelegate{
    
    // MARK: - Handling Launch for Tasks

       // Fetch the latest feed entries from server.
      private func handleAppRefresh(task: BGAppRefreshTask) {
          self.scheduleAppRefresh()
           
           let queue = OperationQueue()
           queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
           
           self.downloadOp = self.createOperationToFetch()
            self.downloadOp?.operationDidFinishHnadler { (response, state) in
                print("\(String(describing: response))")
                task.setTaskCompleted(success: state)
                let  msg : String = "UI has been updated"
                DispatchQueue.main.async { [unowned self]  in
                    if let vc : ViewController = self.getViewController() {
                        vc.updateUI(statusStr: msg)
                    }
                }
            }
           
           task.expirationHandler = {
               // After all operations are cancelled, the completion block below is called to set the task to complete.
               queue.cancelAllOperations()
                
           }
           queue.addOperations([self.downloadOp!], waitUntilFinished: false)
           self.downloadOp = nil
       }
    
}
@available(iOS 13.0, *)
extension  AppDelegate{
    
    private func cancelAllPendingBGTask() {
           BGTaskScheduler.shared.cancelAllTaskRequests()
       }
    
    private func scheduleAppRefresh() {
        
            /** let now = Date()
                   let oneWeek = TimeInterval(7 * 24 * 60 * 60)

                   // Clean the database at most once per week.
                   guard now > (lastCleanDate + oneWeek) else { return }
                   
                   let request = BGProcessingTaskRequest(identifier: "com.example.apple-samplecode.ColorFeed.db_cleaning")
                   request.requiresNetworkConnectivity = false
                   request.requiresExternalPower = true
                   */
        
           do {
               let request = BGAppRefreshTaskRequest(identifier: "com.Dev.apprefresh")
               request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
            
               try BGTaskScheduler.shared.submit(request)
    
           } catch {
               print(error)
           }
       }
    
}

