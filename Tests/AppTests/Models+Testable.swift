//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/11/21.
//

@testable import App
import Fluent


extension User {
    static func create(
        name: String = "Cameron",
        username: String = "wacameron5",
        password: String = "password",
        on database: Database
    ) throws -> User {
        let user = User(name: name, username: username, password: password)
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
        var ratingUser = user
        if ratingUser == nil {
            ratingUser = try User.create(name: "Cameron", username: "mtcameron5", on: database)
        }
        var ratedRecipe = recipe
        if ratedRecipe == nil {
            ratedRecipe = try Recipe.create(name: "Chicken Curry", ingredients: ["Curry Powder"], directions: ["Cook Food"], user: ratingUser, servings: 5, prepTime: "20 Minutes", cookTime: "30 Minutes", on: database)
        }
        let userRating = try UserRatesRecipePivot(user: ratingUser!, recipe: ratedRecipe!, rating: rating)
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

extension Category {
    static func create(on database: Database) throws -> Category {
        let category = Category(name: "Indian")
        try category.save(on: database).wait()
        return category
    }
}
