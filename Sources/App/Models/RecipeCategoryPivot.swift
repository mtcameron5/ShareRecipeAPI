//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

import Fluent
import Foundation

final class RecipeCategoryPivot: Model {
    static let schema = "recipe-category-pivot"
    
    @ID
    var id: UUID?
    
    @Parent(key: "recipeID")
    var recipe: Recipe
    
    @Parent(key: "categoryID")
    var category: Category
    
    init() { }
    
    init(id: UUID? = nil, recipe: Recipe, category: Category) throws {
        self.id = id
        self.$recipe.id = try recipe.requireID()
        self.$category.id = try category.requireID()
    }
}

