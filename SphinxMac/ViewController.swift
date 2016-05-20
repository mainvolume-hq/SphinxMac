//
//  ViewController.swift
//  SphinxMac
//
//  Created by mainvolume on 5/20/16.
//  Copyright © 2016 mainvolume. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var outputPipe:NSPipe!
    var internalPipe:NSPipe!
    var buildTask:NSTask!
    dynamic var isRunning = false
    
    
    @IBOutlet var textOutput: NSTextView!
    
    
    func activateSpeechRecognizer() {
        isRunning = true
        
        let taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        
        dispatch_async(taskQueue) {
            
            let modelPath = NSBundle.mainBundle().pathForResource("en-us", ofType: nil)
            let hmm = (modelPath! as NSString).stringByAppendingPathComponent("en-us")
            let lm = (modelPath! as NSString).stringByAppendingPathComponent("en-us.lm.dmp")
            let dict = (modelPath! as NSString).stringByAppendingPathComponent("cmudict-en-us.dict")
            
            self.buildTask = NSTask()
            self.buildTask.launchPath = NSBundle.mainBundle().pathForResource("pocketsphinx_continuous", ofType: nil)
            self.buildTask.arguments =  ["-inmic","yes","-hmm", hmm, "-lm", lm, "-dict", dict]
            
            //3.
            self.buildTask.terminationHandler = {
                
                task in
                dispatch_async(dispatch_get_main_queue(), {
                    self.isRunning = false
                })
                
            }
            
            self.captureStandardOutputAndRouteToTextView(self.buildTask)
            self.buildTask.launch()
            self.buildTask.waitUntilExit()
        }
        
    }
    
    func captureStandardOutputAndRouteToTextView(task:NSTask) {
        
        outputPipe = NSPipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: NSUTF8StringEncoding) ?? ""
            
            dispatch_async(dispatch_get_main_queue(), {
                let previousOutput = self.textOutput.string ?? ""
                let nextOutput = previousOutput + "\n" + outputString
                self.textOutput.string = nextOutput
                
                let range = NSRange(location:nextOutput.characters.count,length:0)
                self.textOutput.scrollRangeToVisible(range)
            
            })
            
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
        
        
        internalPipe = NSPipe()
        task.standardError = internalPipe
        
        internalPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: internalPipe.fileHandleForReading , queue: nil) {
            notification in
            let output = self.internalPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: NSUTF8StringEncoding) ?? ""
            
            dispatch_async(dispatch_get_main_queue(), {
                print(outputString)
                if outputString.rangeOfString("Ready") != nil{
                    print("Ready")
                } else if outputString.rangeOfString("Listening") != nil{
                    print("Listening")
                }
                print(outputString)
            })
            
            self.internalPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activateSpeechRecognizer()
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

