//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/9/21.
//
import Vapor
import Fluent
import Foundation

struct CreateRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("recipes")
            .id()
            .field("name", .string, .required)
            .field("ingredients", .array(of: .string), .required)
            .field("directions", .array(of: .string), .required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .field("servings", .int, .required)
            .field("prepTime", .string, .required)
            .field("cookTime", .string, .required)
            .field("recipePicture", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("recipes").delete()
    }
}
