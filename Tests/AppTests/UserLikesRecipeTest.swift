//
//  File.swift
//
//
//  Created by Cameron Augustine on 3/12/21.
//

@testable import App
import XCTVapor

final class UserLikesRecipeTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let recipesURI = "/api/recipes/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testSaveUserLikesRecipeToAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        try app.test(.POST, "/api/users/\(user.id!)/likes/\(recipe.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
    }
    

    
    func testGetUsersWhoLikeRecipeFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/likes/\(recipe.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(recipesURI)\(recipe.id!)/likedby/users", afterResponse: { response in
            let usersWhoLikeRecipe = try response.content.decode([User].self)
            XCTAssertEqual(usersWhoLikeRecipe.count, 1)
            XCTAssertEqual(usersWhoLikeRecipe[0].name, user.name)
            XCTAssertEqual(usersWhoLikeRecipe[0].username, user.username)
            XCTAssertEqual(usersWhoLikeRecipe[0].id, user.id)
        })
    }

    func testGetRecipesAUserLikes() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/likes/\(recipe.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "/api/users/\(user.id!)/recipe/likes", afterResponse: { response in
            let recipesAUserLikes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesAUserLikes.count, 1)
            XCTAssertEqual(recipesAUserLikes[0].name, recipe.name)
            XCTAssertEqual(recipesAUserLikes[0].ingredients, recipe.ingredients)
            XCTAssertEqual(recipesAUserLikes[0].directions, recipe.directions)
            XCTAssertEqual(recipesAUserLikes[0].servings, recipe.servings)
            XCTAssertEqual(recipesAUserLikes[0].cookTime, recipe.cookTime)
            XCTAssertEqual(recipesAUserLikes[0].prepTime, recipe.prepTime)
        })
        
        let anotherRecipe = try Recipe.create(user: user, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/likes/\(anotherRecipe.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "/api/users/\(user.id!)/recipe/likes", afterResponse: { response in
            let recipesAUserLikes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesAUserLikes.count, 2)
        })
    }
    
    func testUserUnlikesARecipe() throws {
        let recipe = try Recipe.create(on: app.db)
        let user = try User.create(on: app.db)
        let userLikesRecipeObject = try UserLikesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        
        try app.test(.GET, "\(recipesURI)likes", afterResponse: { response in
            let userLikesRecipeObjects = try response.content.decode([UserLikesRecipePivot].self)
            XCTAssertEqual(userLikesRecipeObjects.count, 1)
        })

        try app.test(.DELETE, "/api/users/unlikes/recipe/\(userLikesRecipeObject.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
            try app.test(.GET, "\(recipesURI)likes", afterResponse: { response in
                let userLikesRecipeObjects = try response.content.decode([UserLikesRecipePivot].self)
                XCTAssertEqual(userLikesRecipeObjects.count, 0)
            })
        })        
    }
}
