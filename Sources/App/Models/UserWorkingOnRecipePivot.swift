//
//  File.swift
//  
//
//  Created by Cameron Augustine on 4/9/21.
//

import Vapor
import Fluent

final class UserWorkingOnRecipePivot: Model, Content {
    static let schema = "user-working-on-recipe-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "userID")
    var user: User
    
    @Parent(key: "recipeID")
    var recipe: Recipe
    
    init() { }
    
    init(id: UUID? = nil, user: User, recipe: Recipe) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$recipe.id = try recipe.requireID()
    }

}
