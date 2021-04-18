//
//  File.swift
//  
//
//  Created by Cameron Augustine on 4/9/21.
//

import Fluent

struct CreateUserWorkingOnRecipePivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-working-on-recipe-pivot")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipeID", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .unique(on: "userID", "recipeID")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-working-on-recipe-pivot").delete()
    }
}
