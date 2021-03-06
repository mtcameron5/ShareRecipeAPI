//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Fluent

struct CreateUserLikesRecipePivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-likes-recipe-pivot")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipeID", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .unique(on: "userID", "recipeID")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-likes-recipe-pivot").delete()
    }
}
