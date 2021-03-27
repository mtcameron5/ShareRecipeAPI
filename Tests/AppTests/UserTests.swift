//
//  File.swift
//
//
//  Created by Cameron Augustine on 3/6/21.
//
@testable import App
import XCTVapor

final class UserTests: XCTestCase {
    
    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersPassword = "password"
    let usersURI = "/api/users/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            password: usersPassword,
            on: app.db)
        _ = try User.create(on: app.db)
        
        try app.test(.GET, usersURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[0].name, usersName)
            XCTAssertEqual(users[0].username, usersUsername)
            XCTAssertEqual(users[0].id, user.id)
        })
    }
    
    func testUsersCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername, password: usersPassword)
        
        try app.test(.POST, usersURI, beforeRequest: { req in
            try req.content.encode(user)
        }, afterResponse: { response in
            let receivedUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(receivedUser.name, usersName)
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertNotNil(receivedUser.id)
            
            try app.test(.GET, usersURI,
                         afterResponse: { secondResponse in
                            let users = try secondResponse.content.decode([User.Public].self)
                            XCTAssertEqual(users.count, 1)
                            XCTAssertEqual(users[0].name, usersName)
                            XCTAssertEqual(users[0].username, usersUsername)
                            XCTAssertEqual(users[0].id, receivedUser.id)
                     })
        })
    }
    
    func testUsersCanRemovedFromAPI() throws {
        let user = User(name: usersName, username: usersUsername, password: usersPassword)
        
        try app.test(.POST, usersURI, beforeRequest: { req in
            try req.content.encode(user)
        }, afterResponse: { response in
            let receivedUser = try response.content.decode(User.Public.self)
            try app.test(.DELETE, "\(usersURI)\(receivedUser.id!)", afterResponse: { deleteResponse in
                XCTAssertEqual(deleteResponse.status, .noContent)
            })
            
            try app.test(.GET, usersURI, afterResponse: { secondResponse in
                let users = try secondResponse.content.decode([User].self)
                XCTAssertEqual(users.count, 0)
             })
        })
    }
    
    func testGettingASingleUserFromTheAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        
        try app.test(.GET, "\(usersURI)\(user.id!)", afterResponse: { response in
            let receivedUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(receivedUser.name, usersName)
            XCTAssertEqual(receivedUser.username, usersUsername)
            XCTAssertEqual(receivedUser.id, user.id)
        })
    }
    
    func testGettingAUsersRecipesFromTheAPI() throws {
        let user = try User.create(on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        
        let recipeName = "Chicken Curry"
        let recipeIngredients = ["Chicken", "Milk", "Curry Powder", "Butter"]
        let recipeDirections = ["Heat Milk", "Cook Chicken"]
        let recipeServings = 4
        let recipePrepTime = "10 Minutes"
        let recipeCookTime = "15 Minutes"
        
        let _ = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        try app.test(.GET, "\(usersURI)\(user.id!)/recipes", afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 2)
            XCTAssertEqual(recipes[0].id, recipe.id)
            XCTAssertEqual(recipes[0].name, recipe.name)
            XCTAssertEqual(recipes[0].ingredients, recipe.ingredients)
        })
    }
    
}
