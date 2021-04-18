//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

import Vapor
import Fluent

final class Category: Model, Content {
    static let schema = "categories"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: RecipeCategoryPivot.self, from: \.$category, to: \.$recipe)
    var recipes: [Recipe] 
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
