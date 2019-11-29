//
//  SRDownloadOperation.swift
//  BackgroundFetchDemo
//
//  Created by Subhra Roy on 29/11/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import Foundation

public typealias  OperationCompletionBlock = (_ response : Any? , _ status : Bool) -> Void

class  SRDownloadOperation : SRQueueOperation{
    
    private var taskIdentifier : String?
    private var url : URL!
    private  var  responseData : Data?
    private var operationHandler : OperationCompletionBlock?
    
    
    func initiate(_ serviceURL : String? , hashIdentifier: String? = nil, progress: Bool = false) throws -> Bool {
        
        self.inProgress = progress
        self.taskIdentifier = hashIdentifier
        
        super.initiate(hashIdentifier, progress: progress)
        
        if let opUrl : String = serviceURL {
            
            self.url = URL(string: opUrl)
            
            return true
        }else{
            throw  Result.Failure("Failed")
            
        }
    }
    
    override  init() {
           super.init()
       }
    
    func operationDidFinishHnadler(closure : @escaping OperationCompletionBlock) {
        self.operationHandler = closure
    }
    
    override  func execute() {
        super.execute()
        self.inProgress = true
         self.responseData = Data()
       
        let dataTask = self.session.dataTask(with: self.url)
        dataTask.resume()
    }
    
    lazy var session : URLSession = {
        let sessionConfigue = URLSessionConfiguration.background(withIdentifier: "Background")
        let session = URLSession(configuration: sessionConfigue, delegate: self, delegateQueue: nil)
        return  session
    }()
    
    /// Finish task and changed to .finished
       /// - Author: Subhra Roy
       override func completeOpeartion() -> Void{
        super.completeOpeartion()
           self.inProgress = false
          self.responseData = nil
          self.operationHandler = nil
        self.session.finishTasksAndInvalidate()
       }
    
    deinit {
        print("SRDownloadOperation dealloc")
    }
}

extension  SRDownloadOperation : URLSessionDataDelegate {
    
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
            self.completeOpeartion()
            return
        }
            // Check if the operation has been Suspended
        else if(task.state == URLSessionTask.State.suspended) {
            self.completeOpeartion()
            return
        }
        
        if let errorInfo = error{
            
            print("Session error: \(errorInfo.localizedDescription)")
    
        }
        else{
            
            if let data : Data = self.responseData{
                
                 if let _ = error {
                        self.operationHandler?(nil, false)
                   }else{
                       
                   do{
                       let responseDict : Any = try JSONSerialization.jsonObject(with: data, options: [])
                       //print("\(responseDict)")
                     self.operationHandler?(responseDict, true)
                   }catch{
                       self.operationHandler?(nil, false)
                   }

                   }
            }
            
        }
        self.completeOpeartion()
    }
    
}
