//
//  processCmd.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 10.03.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length

import Foundation

protocol ErrorOutput: AnyObject {
    func erroroutput()
}

class ProcessCmd: Delay {
    // Variable for reference to Process
    var processReference: Process?
    // Message to calling class
    weak var updateDelegate: UpdateProgress?
    // Observers
    weak var notifications_datahandle: NSObjectProtocol?
    weak var notifications_termination: NSObjectProtocol?
    // Command to be executed, normally rsync
    var command: String?
    // Arguments to command
    var arguments: [String]?
    // true if processtermination
    var termination: Bool = false
    // possible error ouput
    weak var possibleerrorDelegate: ErrorOutput?
    // A Timer object to continusly check process is alive
    var continuislycheckforalive: Timer?
    var executecontinuislycheckforalive: Bool = false
    var previousnumberofoutput: Int?
    var outputprocessverifyrsync: OutputProcess?

    func setupdateDelegate(object: UpdateProgress) {
        self.updateDelegate = object
    }

    func executeProcess(outputprocess: OutputProcess?) {
        // Process
        let task = Process()
        // If self.command != nil either alternativ path for rsync or other command than rsync to be executed
        if let command = self.command {
            self.executecontinuislycheckforalive = false
            task.launchPath = command
        } else {
            if self.arguments?.contains("--dry-run") ?? false == false {
                self.executecontinuislycheckforalive = true
            }
            task.launchPath = Getrsyncpath().rsyncpath
        }
        task.arguments = self.arguments
        // If there are any Environmentvariables like
        // SSH_AUTH_SOCK": "/Users/user/.gnupg/S.gpg-agent.ssh"
        if let environment = Environment() {
            task.environment = environment.environment
        }
        // Pipe for reading output from Process
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        // Observator for reading data from pipe, observer is removed when Process terminates
        self.notifications_datahandle = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: nil, queue: nil) { [weak self] _ in
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    outputprocess?.addlinefromoutput(str: str as String)
                    // Send message about files
                    self?.updateDelegate?.fileHandler()
                    if self?.termination ?? false {
                        self?.possibleerrorDelegate?.erroroutput()
                    }
                }
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
        // Observator Process termination, observer is removed when Process terminates
        self.notifications_termination = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: nil, queue: nil) { _ in
            self.delayWithSeconds(0.5) {
                self.termination = true
                self.updateDelegate?.processTermination()
                // Deallocate the Timer object
                self.continuislycheckforalive?.invalidate()
                // Must remove for deallocation
                NotificationCenter.default.removeObserver(self.notifications_datahandle as Any)
                NotificationCenter.default.removeObserver(self.notifications_termination as Any)
            }
        }
        self.processReference = task
        task.launch()
        // Create the Timer object for verifying the process object is alive
        if self.executecontinuislycheckforalive {
            self.continuislycheckforalive = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.verifyrunningprocess), userInfo: nil, repeats: true)
        }
        self.outputprocessverifyrsync = outputprocess
    }

    // Get the reference to the Process object.
    func getProcess() -> Process? {
        return self.processReference
    }

    // Terminate Process, used when user Aborts task.
    func abortProcess() {
        _ = InterruptProcess(process: self.processReference)
    }

    @objc func verifyrunningprocess() {
        // print("verify")
        guard self.previousnumberofoutput != nil else {
            self.previousnumberofoutput = self.outputprocessverifyrsync?.count()
            return
        }
        guard self.outputprocessverifyrsync?.count() ?? 0 > self.previousnumberofoutput ?? 0 else {
            // print(self.outputprocess2?.count() ?? 0)
            // print(self.previousnumberofoutput ?? 0)
            return
        }
        let question: String = NSLocalizedString("Seems like rsync is not responding?", comment: "Process")
        let text: String = NSLocalizedString("Interrupt rsync?", comment: "Process")
        let dialog: String = NSLocalizedString("Interrupt", comment: "Process")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            _ = InterruptProcess(process: self.processReference)
        }
    }

    init(command: String?, arguments: [String]?) {
        self.command = command
        self.arguments = arguments
        self.possibleerrorDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
    }
}
