//
//  DatabaseError.swift
//  VergeORM
//
//  Created by muukii on 2020/01/02.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

//public enum DatabaseError: Error {
//
//}

public enum BatchUpdatesError: Error {
  case aborted
  case storedEntityNotFound
}
