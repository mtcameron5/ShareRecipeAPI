//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Fluent

struct CreateUserConnectionPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-connection-pivot")
            .id()
            .field("followerID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("followedID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .unique(on: "followerID", "followedID")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-connection-pivot").delete()
    }
}
