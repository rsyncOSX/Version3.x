//
//  operations.swift
//  Rsync
//
//  Created by Thomas Evensen on 09/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

// Operation record to store info about all jobs.
struct argumentsOneConfig {
   
    var task:String
    var backupID:String
    var config:configuration
    var arg:[String]?
    var argdryRun:[String]?
    var argDisplay:[String]?
    var argdryRunDisplay:[String]?
    var serverdate:String?
    var localdate:String?
    var index:Int
    var warning:Bool = false
    
    init(backupID:String, task:String, config:configuration, index:Int) {
        self.backupID = backupID
        self.task = task
        self.config = config
        self.index = index
    }
}

// Preparing all parameters for all jobs based upon the stored configuration.

struct argumentsConfigurations {

    // Record to store all arguments for rsync
    // Arguments are prepared during startup
    var rsyncArguments: argumentsOneConfig
    // Object for preparing rsync arguments
    let getrsyncArguments = rsyncProcessArguments()
    
    init(rsyncArguments: argumentsOneConfig) {
        self.rsyncArguments = rsyncArguments
        self.rsyncArguments.task = rsyncArguments.config.task
        self.rsyncArguments.backupID = rsyncArguments.config.backupID
        // prepare all arguments task
        self.rsyncArguments.arg = getrsyncArguments.argumentsRsync(rsyncArguments.config, dryRun: false, forDisplay: false)
        self.rsyncArguments.argDisplay = getrsyncArguments.argumentsRsync(rsyncArguments.config, dryRun: false, forDisplay: true)
        self.rsyncArguments.argdryRun = getrsyncArguments.argumentsRsync(rsyncArguments.config, dryRun: true, forDisplay: false)
        self.rsyncArguments.argdryRunDisplay = getrsyncArguments.argumentsRsync(rsyncArguments.config, dryRun: true, forDisplay: true)
    }
}

