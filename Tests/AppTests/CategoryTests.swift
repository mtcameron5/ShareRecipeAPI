//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    let categoriesURI = "/api/categories/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testCategoryCanBeRetrievedFromAPI() throws {
        let category = try Category.create(on: app.db)
        try app.test(.GET, categoriesURI, afterResponse: { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(categories.count, 1)
            XCTAssertEqual(categories[0].name, category.name)
            XCTAssertEqual(categories[0].id, category.id)
        })
    }
    
    func testAdminUserCanSaveCategoryToAPI() throws {
        let category = App.Category(name: "Indian")
        let user = try User.create(admin: true, on: app.db)
        
        try app.test(.POST, categoriesURI, loggedInUser: user, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            let responseCategory = try response.content.decode(App.Category.self)
            XCTAssertEqual(response.status, .ok)
            XCTAssertEqual(responseCategory.name, category.name)
            XCTAssertNotNil(responseCategory.id)
            
            try app.test(.GET, categoriesURI, afterResponse: { response in
                let categories = try response.content.decode([App.Category].self)
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, category.name)
                XCTAssertEqual(responseCategory.name, categories[0].name)
            })
        })
    }
    
    func testMustBeLoggedInToMakeDestructiveAction() throws {
        let category = App.Category(name: "Indian")
        
        try app.test(.POST, categoriesURI, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            XCTAssert(response.status == .unauthorized)
        })
    }
    
    func testNonAdminCannotSaveCategoryToAPI() throws {
        let category = App.Category(name: "Indian")
        let user = try User.create(admin: false, on: app.db)

        try app.test(.POST, categoriesURI, loggedInUser: user, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .forbidden)
            XCTAssertThrowsError(try response.content.decode(App.Category.self))
        })
        
        try app.test(.GET, categoriesURI, afterResponse: { response in
            XCTAssert(response.status == .ok)
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 0)
        })
        
    }
    
    func testRecipeCreatorCanAddCategoriesToTheirRecipe() throws {
        let userThatCreatedRecipe = try User.create(on: app.db)
        let recipe = try Recipe.create(user: userThatCreatedRecipe, on: app.db)
        let category = try Category.create(on: app.db)
        
        try app.test(.POST, "/api/recipes/\(recipe.id!)/categories/\(category.id!)", loggedInUser: userThatCreatedRecipe, afterResponse: { response in
            XCTAssert(response.status == .created)
        })
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/recipes", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let recipesInCategory = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesInCategory.count, 1)
            XCTAssertEqual(recipesInCategory[0].id, recipe.id)
            XCTAssertEqual(recipesInCategory[0].$user.id, userThatCreatedRecipe.id)
        })
    }
    
    func testAdminCanAddCategoryToRecipe() throws {
        let userThatCreatedRecipe = try User.create(on: app.db)
        let recipe = try Recipe.create(user: userThatCreatedRecipe, on: app.db)
        
        let adminUser = try User.create(admin: true, on: app.db)
        let category = try App.Category.create(name: "Chinese", on: app.db)
        
        try app.test(.POST, "/api/recipes/\(recipe.id!)/categories/\(category.id!)", loggedInUser: adminUser, afterResponse: { response in
            XCTAssert(response.status == .created)
        })
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/recipes/", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let recipesAttachedToCategory = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesAttachedToCategory.count, 1)
            XCTAssertEqual(recipesAttachedToCategory[0].name, recipe.name)
            XCTAssertEqual(recipesAttachedToCategory[0].id, recipe.id)
        })
        
        try app.test(.GET, "/api/recipes/\(recipe.id!)/categories", afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let categoriesOfRecipe = try response.content.decode([App.Category].self)
            XCTAssertEqual(categoriesOfRecipe.count, 1)
            XCTAssertEqual(categoriesOfRecipe[0].id, category.id)
            XCTAssertEqual(categoriesOfRecipe[0].name, category.name)
        })
        
    }
    
    func testMustBeLoggedInToAddCategoryToRecipe() throws {
        let category = try App.Category.create(on: app.db)
        let recipe = try Recipe.create(on: app.db)
        
        try app.test(.POST, "/api/recipes/\(recipe.id!)/categories/\(category.id!)", afterResponse: { response in
            XCTAssert(response.status == .unauthorized)
        })
    }
    
    func testNonAdminOrNonCreatorCannotAddCategoryToRecipe() throws {
        let nonAdminAndNonCreator = try User.create(username: "mtcameron6", admin: false, on: app.db)
        let creatorUser = try User.create(on: app.db)
        
        let category = try App.Category.create(on: app.db)
        let recipe = try Recipe.create(user: creatorUser, on: app.db)
        
        try app.test(.POST, "/api/recipes/\(recipe.id!)/categories/\(category.id!)", loggedInUser: nonAdminAndNonCreator, afterResponse: { response in
            XCTAssert(response.status == .forbidden)
        })
        
        try app.test(.GET, "\(categoriesURI)\(category.id!)/recipes/", afterResponse: { response in
            let recipesAttachedToCategory = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesAttachedToCategory.count, 0)
        })
    }
    
    
}
