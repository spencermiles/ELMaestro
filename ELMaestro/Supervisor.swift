//
//  Supervisor.swift
//  ELMaestro
//
//  Created by Brandon Sneed on 9/23/15.
//  Copyright (c) 2015 theholygrail. All rights reserved.
//

import Foundation
import ELRouter

@objc
public class Supervisor: UIResponder {
    
    override init() {
        super.init()
        
        // ...
    }
    
    public func loadPlugin(pluginType: AnyObject.Type) {
        // I used AnyObject.Type here, because Pluggable.Type translates
        // to Class<Pluggable> in objc, but returns an AnyObject.Type instead.
        
        // WARNING: Don't step through this, or you'll crash Xcode.. cuz it sucks.
        if let pluginType = pluginType as? Pluggable.Type {
            let plugin = pluginType.init(containerBundleID: "com.fuck.you")
            if let instance = plugin {
                print("proposing: \(instance.identifier).")
                proposedPlugins.append(instance)
            }
        }
        // END WARNING.
    }
    
    public func startup() {
        // identify the plugins we will actually load.
        loadedPlugins = validateProposedPlugins(proposedPlugins)
        
        for i in 0..<loadedPlugins.count {
            let plugin = loadedPlugins[i]
            
            startPlugin(plugin)
        }
        
        Router.sharedInstance.updateNavigator()
    }
    
    public func pluginLoaded(dependencyID: DependencyID) -> Bool {
        return loadedPlugins.contains({ (item) -> Bool in
            return (item.identifier == dependencyID)
        })
    }
    
    public func pluginStarted(dependencyID: DependencyID) -> Bool {
        return startedPlugins.contains({ (item) -> Bool in
            return (item.identifier == dependencyID)
        })
    }
    
    public func pluginAPIForID(id: DependencyID) -> AnyObject? {
        var result: AnyObject? = nil
        
        if let plugin = pluginByIdentifier(id) as? PluggableFeature {
            result = plugin.pluginAPI?()
        }
        
        return result
    }
    
    private func pluginByIdentifier(id: DependencyID) -> Pluggable? {
        let found = startedPlugins.filter { (plugin) -> Bool in
            if plugin.identifier.lowercaseString == id.lowercaseString {
                return true
            }
            return false
        }
        
        if found.count > 1 {
            assertionFailure("found more than one plugin with id \(id)!")
        } else if found.count == 1 {
            return found[0]
        }
        
        return nil
    }
    
    private func startPlugin(plugin: Pluggable) {
        if !pluginStarted(plugin.identifier) {
            print("starting: \(plugin.identifier)")
            
            // try find any dependencies that haven't been started yet.
            if let deps = plugin.dependencies {
                for i in 0..<deps.count {
                    if let dep = pluginByIdentifier(deps[i]) {
                        // if it's already loaded, this does nothing.
                        startPlugin(dep)
                    }
                }
            }
            
            plugin.startup(self)
            startedPlugins.append(plugin)
            print("started: \(plugin.identifier)")
        }
    }
    
    private func validateProposedPlugins(proposedPlugins: [Pluggable]) -> [Pluggable] {
        var acceptedPlugins = [Pluggable]()
        
        for i in 0..<proposedPlugins.count {
            print("checking proposal: \(proposedPlugins[i].identifier).")
            var hasDeps = true
            // look at the dependencies and make sure they're all there.
            if let deps = proposedPlugins[i].dependencies {
                for item in deps {
                    let present = proposedPlugins.contains { (plugin) -> Bool in
                        return (plugin.identifier == item)
                    }
                    
                    // the dependency is present, validate it.
                    if present {
                        hasDeps = true
                        acceptedPlugins.append(proposedPlugins[i])
                    } else {
                        print("ERROR: proposed plugin \(item) is missing dependency \(item).")
                    }
                }
            } else {
                // it doesn't have any dependencies, so it's validated.
                hasDeps = false
                acceptedPlugins.append(proposedPlugins[i])
            }
            let subtext = hasDeps ? "(dependencies present)" : "(no dependencies required)"
            print("validating proposal: \(proposedPlugins[i].identifier) \(subtext)")
        }
        
        return acceptedPlugins
    }
    
    private var proposedPlugins = [Pluggable]()
    private var loadedPlugins = [Pluggable]()
    public private(set) var startedPlugins = [Pluggable]()
    
    /// Get all of the started plugins that conform to PluggableFeature
    var startedFeaturePlugins: [PluggableFeature] {
        return startedPlugins.flatMap { $0 as? PluggableFeature }
    }
}

@objc
public class ApplicationSupervisor: Supervisor, UIApplicationDelegate {
    /* 
     I had to do the sharedInstance stuff a bit differently here since the app
     ends up instantiating the first ApplicationSupervisor.
    */
    private struct Static {
        static var onceToken: dispatch_once_t = 0
        static var instance: ApplicationSupervisor? = nil
    }

    public static var sharedInstance: ApplicationSupervisor {
        let instance = Static.instance
        return instance!
    }
    
    override public init() {
        super.init()
        dispatch_once(&Static.onceToken) {
            Static.instance = self
        }
    }
    
    public var window: UIWindow? = nil
    
    public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }
    
    public func applicationWillResignActive(application: UIApplication) {
        for feature in startedFeaturePlugins {
            feature.applicationWillResignActive?()
        }
    }
    
    public func applicationDidEnterBackground(application: UIApplication) {
        for feature in startedFeaturePlugins {
            feature.applicationDidEnterBackground?()
        }
    }
    
    public func applicationWillEnterForeground(application: UIApplication) {
        for feature in startedFeaturePlugins {
            feature.applicationWillEnterForeground?()
        }
    }
    
    public func applicationDidBecomeActive(application: UIApplication) {
        for feature in startedFeaturePlugins {
            feature.applicationDidBecomeActive?()
        }
    }
    
    public func applicationWillTerminate(application: UIApplication) {
        for feature in startedFeaturePlugins {
            feature.applicationDidBecomeActive?()
        }
    }
}
