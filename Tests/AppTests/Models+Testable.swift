//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/11/21.
//

@testable import App
import Fluent
import Vapor

extension User {
    static func create(
        name: String = "Cameron",
        username: String? = nil,
        password: String = "password",
        admin: Bool = false,
        on database: Database
    ) throws -> User {
        let createUsername: String
        
        if let suppliedUsername = username {
            createUsername  = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }
        
        let hashedPassword = try Bcrypt.hash(password)
        let user = User(name: name, username: createUsername, password: hashedPassword, admin: admin)
        try user.save(on: database).wait()
        return user
    }
}

extension Recipe {
    static func create(
        name: String = "Paprika Curry",
        ingredients: [String] = ["Paprika", "Curry Powder", "Milk"],
        directions: [String] = ["Put Milk In Sauce Pan", "Add curry powder and paprika"],
        user: User? = nil,
        servings: Int = 8,
        prepTime: String = "20 Minutes",
        cookTime: String = "20 Minutes",
        on database: Database
    ) throws -> Recipe {
        var recipeUser = user
        
        if recipeUser == nil {
            recipeUser = try User.create(name: "Cameron", username: "mtcameron5", on: database)
        }
        
        let recipe = Recipe(name: name, ingredients: ingredients, servings: servings, prepTime: prepTime, cookTime: cookTime, directions: directions, userID: recipeUser!.id!)
        try recipe.save(on: database).wait()
        return recipe
    }
}

extension UserRatesRecipePivot {
    static func create(
        user: User? = nil,
        recipe: Recipe? = nil,
        rating: Float = 5.0,
        on database: Database
    ) throws -> UserRatesRecipePivot {
        var userRatingRecipe = user
        if userRatingRecipe == nil {
            userRatingRecipe = try User.create(name: "Cameron", username: "mtcameron5", on: database)
        }
        var recipeBeingRated = recipe
        if recipeBeingRated == nil {
            recipeBeingRated = try Recipe.create(name: "Chicken Curry", ingredients: ["Curry Powder"], directions: ["Cook Food"], user: userRatingRecipe, servings: 5, prepTime: "20 Minutes", cookTime: "30 Minutes", on: database)
        }
        
        let userRating = try UserRatesRecipePivot(user: userRatingRecipe!, recipe: recipeBeingRated!, rating: rating)
        try userRating.save(on: database).wait()
        return userRating
    }
}


extension UserLikesRecipePivot {
    static func create(
        user: User? = nil,
        recipe: Recipe? = nil,
        on database: Database
    ) throws -> UserLikesRecipePivot {
        var userWhoLikesRecipe = user
        if userWhoLikesRecipe == nil {
            userWhoLikesRecipe = try User.create(name: "Cameron", username: "mtcameron5", on: database)
        }
        var likedRecipe = recipe
        if likedRecipe == nil {
            likedRecipe = try Recipe.create(name: "Chicken Curry", ingredients: ["Curry Powder"], directions: ["Cook Food"], user: userWhoLikesRecipe, servings: 5, prepTime: "20 Minutes", cookTime: "30 Minutes", on: database)
        }
        
        let userLikesRecipe = try UserLikesRecipePivot(user: userWhoLikesRecipe!, recipe: likedRecipe!)
        try userLikesRecipe.save(on: database).wait()
        return userLikesRecipe
    }
}

extension App.Category {
    static func create(name: String? = nil, on database: Database) throws -> App.Category {
        var categoryName: String
        if let suppliedName = name {
            categoryName = suppliedName
        } else {
            categoryName = "Indian"
        }
        
        let category = Category(name: categoryName)
        try category.save(on: database).wait()
        return category
    }
}
