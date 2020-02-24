//
//  Log.swift
//  VergeCore
//
//  Created by muukii on 2020/02/24.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.log

public enum VergeOSLogs {
  public static let debugLog = OSLog(subsystem: "Verge", category: "Debug")
}
