//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Fluent

struct CreateUserRatesRecipePivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-rates-recipe-pivot")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipeID", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("rating", .float, .required)
            .unique(on: "userID", "recipeID")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user-rates-recipe-pivot").delete()
    }
}
