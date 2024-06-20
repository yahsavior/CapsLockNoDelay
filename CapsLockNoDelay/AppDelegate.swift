//
//  AppDelegate.swift
//  CapsLockNoDelay
//
//  Created by Guy Kaplan on 31/10/2020.
//

import Cocoa
import ServiceManagement
import LaunchAtLogin
import Foundation


class AppDelegate: NSObject, NSApplicationDelegate {
    var capsLockManager: Toggleable? = nil

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        if !isInApplicationsFolder() {
                showAlertMoveToApplications()
                moveAppToApplicationsFolder()
                NSApp.terminate(nil) // Exit the app after moving
            }
        
        print(LaunchAtLogin.isEnabled)
        //=> false

        LaunchAtLogin.isEnabled = true

        print(LaunchAtLogin.isEnabled)
        //=> true
        
        
//        requestAccessibilityPermissionsIfNeeded()
        
//        if !checkAccessibilityPermissions() {
//            showAccessibilityAlertAndTerminate()
//        }
        
        let alert = NSAlert()
        alert.messageText = "App Opened Successfully"
        alert.informativeText = "CapsLockNoDelay has launched successfully."

        // Add buttons to the alert
        alert.addButton(withTitle: "OK")

        // Display the alert
        alert.runModal()
        
        if !checkIfCapsLockIsAssignedToLayoutSwitching() {
            self.capsLockManager = CapsLockManager()
        }
        else {
            // I did not observe delays when switching layouts.
            // Enabling this when there are no delays may cause bugs.
            //            self.capsLockManager = InputSourceManager()
        }
        
        // Start listening for events.
        registerEventListener()
    }
    
    func showAccessibilityAlertAndTerminate() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = "CapsLockNoDelay requires Accessibility permissions to function properly. Please enable these permissions in System Preferences."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
        NSApp.terminate(self)
    }
    
    func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func isInApplicationsFolder() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        let applicationsFolderPath = "/Applications"
        
        return bundlePath.hasPrefix(applicationsFolderPath)
    }
    
    func showAlertMoveToApplications() {
        let alert = NSAlert()
        alert.messageText = "Move App to Applications Folder"
        alert.informativeText = "Please move this app to the Applications folder."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
    }
    
    func moveAppToApplicationsFolder() {
        let fileManager = FileManager.default
        let appPath = Bundle.main.bundlePath
        let applicationsFolderPath = "/Applications"
        let newPath = "\(applicationsFolderPath)/\(URL(fileURLWithPath: appPath).lastPathComponent)"
        
        do {
            try fileManager.moveItem(atPath: appPath, toPath: newPath)
            print("App moved to Applications folder")
        } catch {
            print("Error moving app: \(error.localizedDescription)")
        }
    }

    
    /// Register an event listener and listen for caps-lock presses.
    func registerEventListener() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .systemDefined]) { (event) in
            if (event.type != .systemDefined) {
                return
            }
            if (event.subtype.rawValue == 211) {
                if event.data1 != 1 {
                    self.capsLockManager?.toggleState()
                }
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
//    private func hasAccessibilityPermission() -> Bool {
//        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
//        return AXIsProcessTrustedWithOptions(options)
//    }
    
//    private func askForAccessibilityPermission() {
//        let alert = NSAlert.init()
//        alert.messageText = "CapsLockNoDelay requires accessibility permissions."
//        alert.informativeText = "Please re-launch CapsLockNoDelay after you've granted permission in system preferences."
//        alert.addButton(withTitle: "Configure Accessibility Settings")
//        alert.alertStyle = NSAlert.Style.warning

//        if alert.runModal() == .alertFirstButtonReturn {
//            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
//                return
//            }
//            NSWorkspace.shared.open(url)
//            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").first?.activate(options: [])
//            NSApplication.shared.terminate(self)
//        }
//    }
    
    func requestAccessibilityPermissionsIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            // Show a dialog or prompt the user to enable Accessibility
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "CapsLockNoDelay requires Accessibility permissions to function properly. Please enable these permissions in System Preferences."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openAccessibilityPreferences()
            }
        }
    }

    func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkIfRunningFromApplicationsFolder() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        let appPath = "/Applications/"
        return bundlePath.hasPrefix(appPath)
    }
    
    private func moveApplicationToApplicationsFolder() {
        let bundlePath = Bundle.main.bundlePath
        let appPath = "/Applications/"
        let appName = "CapsLockNoDelay.app"
        let newPath = appPath + appName
        do {
            try FileManager.default.moveItem(atPath: bundlePath, toPath: newPath)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to move CapsLockNoDelay to the applications folder."
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
    }
    
    private func checkIfCapsLockIsAssignedToLayoutSwitching() -> Bool {
        let command = "defaults read -g TISRomanSwitchState"
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        return output?.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }
}
