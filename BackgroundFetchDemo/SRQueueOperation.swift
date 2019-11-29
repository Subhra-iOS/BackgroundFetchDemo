//
//  SRQueueOperation.swift
//  PrintApp
//
//  Created by Subhra Roy on 24/11/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import Foundation

@objc private enum OperationState : Int {
    
    /**
     The `Operation`'s conditions have all been satisfied, and it is ready
     to execute.
     */
    case ready
    
    /// The `Operation` is executing.
    case executing
    
    /// The `Operation` has finished executing.
    case finished
    
    /// The `Operation` has cancelled.
    case cancelled
    
}


@objc public class SRQueueOperation : Operation {
    
    @objc public  var hashIdentifier : String?
    @objc public  var inProgress : Bool = false
    
    
    private let operationStateQueue = DispatchQueue(label: "com.operations.state", attributes: .concurrent)
    private var opState = OperationState.ready
    
    func initiate(_ hashIdentifier : String? = nil, progress : Bool = false) {
        
        self.hashIdentifier = hashIdentifier
        self.inProgress = progress

        
    }
    
    override  init() {
        
    }
    
    @objc private dynamic var state: OperationState {
        get {
            return operationStateQueue.sync(execute: { opState })
        }
        set {
            willChangeValue(forKey: "state")
            operationStateQueue.sync(flags: .barrier,
                               execute: { opState = newValue })
            didChangeValue(forKey: "state")
        }
    }
    
    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        return state == .executing
    }
    
    public final override var isFinished: Bool {
        return state == .finished
    }
    
    public final override var isAsynchronous: Bool {
        return true
    }
    
    public override final func start() {
        super.start()
        if isCancelled {
            finish()
            return
        }
        state = .executing
        execute()
    }
    
    public final func finish() {
        state = .finished
    }
    
    open func execute(){
    
        print("Subclass must override")
    }
    
    open func completeOpeartion(){
        self.finish()
        
    }
    
    deinit {
        print("SRQueueOperation dealloc")
    }
    
    
}

extension SRQueueOperation {
    
    @objc private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state" , "cancelledState"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsCancelled() -> Set<String> {
        return ["cancelledState"]
    }
    
}

extension  SRQueueOperation{
    
    // MARK: CustomDebugStringConvertible
    
    override public var debugDescription: String {
        
        return "Operation Name: \(String(describing: name)) isCancelled?: \(isCancelled) isExecuting?: \(isExecuting) isFinished?: \(isFinished) isReady?: \(isReady) isAsynchronous?: \(isAsynchronous) Dependencies: \(dependencies) Priority: \(queuePriority) Quality of Services: \(qualityOfService)"
    }
    
}
