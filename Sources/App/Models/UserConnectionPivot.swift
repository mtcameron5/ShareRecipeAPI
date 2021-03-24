//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

final class UserConnectionPivot: Model, Content {
    static let schema = "user-connection-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "followerID")
    var follower: User
    
    @Parent(key: "followedID")
    var followed: User
    
    init() { }
    
    init(id: UUID? = nil, follower: User, followed: User) throws {
        self.id = id
        self.$follower.id = try follower.requireID()
        self.$followed.id = try followed.requireID()
    }

}

