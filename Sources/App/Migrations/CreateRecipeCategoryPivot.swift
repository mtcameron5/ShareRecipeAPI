//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

import Fluent

struct CreateRecipeCategoryPivot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("recipe-category-pivot")
            .id()
            .field("recipeID", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
            .unique(on: "recipeID", "categoryID")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("recipe-category-pivot").delete()
    }
}
