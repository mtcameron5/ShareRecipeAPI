//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

final class UserRatesRecipePivot: Model, Content {
    static let schema = "user-rates-recipe-pivot"
    
    @ID
    var id: UUID?
    
    @Field(key: "rating")
    var rating: Float
    
    @Parent(key: "userID")
    var user: User
    
    @Parent(key: "recipeID")
    var recipe: Recipe
    
    init() { }
    
    init(id: UUID? = nil, user: User, recipe: Recipe, rating: Float) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$recipe.id = try recipe.requireID()
        self.rating = rating
    }

}
