//
//  AppIconGrabber.swift
//  EnumWindows
//
//  Created by Igor Mandrigin on 2017-02-22.
//  Copyright © 2017 Igor Mandrigin. All rights reserved.
//

import Foundation
import AppKit

struct AppIcon {
    
    let appName : String
    
    init(appName: String) {
        self.appName = appName
    }
    
    var path : String {
        let appPath = appName | { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0)?.path }
        return appPath ?? ""
    }
}

/**
 * Just having fun with the pipelining
 */
precedencegroup PipelinePrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
}
infix operator | : PipelinePrecedence

func | <A, B> (lhs : A?, rhs : (A) -> B?) -> B? {
    guard let l = lhs else {
        return nil
    }
    
    return rhs(l)
}
