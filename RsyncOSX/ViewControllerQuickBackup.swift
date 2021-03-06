//
//  ViewControllerQuickBackup.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.12.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length cyclomatic_complexity

import Cocoa
import Foundation

protocol QuickBackupCompleted: AnyObject {
    func quickbackupcompleted()
}

class ViewControllerQuickBackup: NSViewController, SetDismisser, Abort, Delay, Setcolor {
    var seconds: Int?
    var row: Int?
    var filterby: Sortandfilter?
    var quickbackup: QuickBackup?
    var executing: Bool = true
    var max: Double?
    var maxInt: Int?
    var diddissappear: Bool = false
    var indexinitiated: Int = -1

    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var abortbutton: NSButton!
    @IBOutlet var completed: NSTextField!

    // Either abort or close
    @IBAction func abort(_: NSButton) {
        self.quickbackup?.abort()
        self.quickbackup = nil
        self.abort()
        if (self.presentingViewController as? ViewControllerMain) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vctabmain)
        } else if (self.presentingViewController as? ViewControllerSchedule) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vctabschedule)
        } else if (self.presentingViewController as? ViewControllerNewConfigurations) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcnewconfigurations)
        } else if (self.presentingViewController as? ViewControllerRestore) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcrestore)
        } else if (self.presentingViewController as? ViewControllerSnapshots) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcsnapshot)
        } else if (self.presentingViewController as? ViewControllerSsh) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcssh)
        } else if (self.presentingViewController as? ViewControllerLoggData) != nil {
            self.dismissview(viewcontroller: self, vcontroller: .vcloggdata)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcquickbackup, nsviewcontroller: self)
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.completed.isHidden = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else {
            globalMainQueue.async { () -> Void in
                self.mainTableView.reloadData()
            }
            return
        }
        self.quickbackup = QuickBackup()
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
        // release the quickobject
        self.quickbackup = nil
    }

    private func initiateProgressbar(progress: NSProgressIndicator) {
        progress.isHidden = false
        if let calculatedNumberOfFiles = self.quickbackup?.maxcount {
            progress.maxValue = Double(calculatedNumberOfFiles)
            self.max = Double(calculatedNumberOfFiles)
            self.maxInt = calculatedNumberOfFiles
        }
        progress.minValue = 0
        progress.doubleValue = 0
        progress.startAnimation(self)
    }

    private func updateProgressbar(progress: NSProgressIndicator) {
        let value = Double((self.quickbackup?.outputprocess?.getOutput()?.count) ?? 0)
        progress.doubleValue = value
    }
}

extension ViewControllerQuickBackup: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return self.quickbackup?.sortedlist?.count ?? 0
    }
}

extension ViewControllerQuickBackup: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard self.quickbackup?.sortedlist != nil else { return nil }
        guard row < (self.quickbackup?.sortedlist?.count ?? 0) else { return nil }
        if let object: NSDictionary = self.quickbackup?.sortedlist?[row],
           let cellIdentifier: String = tableColumn?.identifier.rawValue
        {
            let hiddenID = object.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int
            switch cellIdentifier {
            case "percentCellID":
                guard hiddenID == self.quickbackup?.hiddenID else { return nil }
                if let cell: NSProgressIndicator = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) as? NSProgressIndicator {
                    if row > self.indexinitiated {
                        self.indexinitiated = row
                        self.initiateProgressbar(progress: cell)
                    } else {
                        self.updateProgressbar(progress: cell)
                    }
                    return cell
                }
            case "countCellID":
                guard hiddenID == self.quickbackup?.hiddenID else { return nil }
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) as? NSTableCellView {
                    let filestodo = (self.maxInt ?? 0) - (self.quickbackup?.outputprocess?.getOutput()?.count ?? 0)
                    if filestodo > 0 {
                        cell.textField?.stringValue = String(filestodo)
                        return cell
                    } else {
                        cell.textField?.stringValue = ""
                        return cell
                    }
                }
            default:
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) as? NSTableCellView {
                    cell.textField?.stringValue = object.value(forKey: cellIdentifier) as? String ?? ""
                    return cell
                }
            }
        }
        return nil
    }
}

extension ViewControllerQuickBackup: Reloadandrefresh {
    func reloadtabledata() {
        globalMainQueue.async { () -> Void in
            self.mainTableView.reloadData()
        }
    }
}

extension ViewControllerQuickBackup: QuickBackupCompleted {
    func quickbackupcompleted() {
        self.completed.isHidden = false
        self.completed.textColor = setcolor(nsviewcontroller: self, color: .green)
        self.executing = false
    }
}
