//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

final class UserConnection: Model, Content {
    static let schema = "user"
    
    @ID
    var id: UUID?
