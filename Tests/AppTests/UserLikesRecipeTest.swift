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
    
    func testUserLoggedIntoAccountCanLikeRecipe() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: user,  afterResponse: { response in
            XCTAssert(response.status == .created)
        })
    }
    
    func testUserMustBeLoggedInToLikeRecipe() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/",  afterResponse: { response in
            XCTAssert(response.status == .unauthorized)
        })
    }
    
    // Someone logged into another account cannot request to like a recipe for another user, they must be logged into that account
    func testAnotherUserCannotLikeRecipeForUser() throws {
        let anotherUser = try User.create(on: app.db)
        let targetUser = try User.create(on: app.db)
        let recipe = try Recipe.create(on: app.db)
        
        try app.test(.POST, "/api/users/\(targetUser.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: anotherUser, afterResponse: { response in
            XCTAssert(response.status == .forbidden)
        })
    }
    
    func testGetUsersWhoLikeRecipeFromAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: user,  afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(recipesURI)\(recipe.id!)/users/likes/", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let usersWhoLikeRecipe = try response.content.decode([User.Public].self)
            XCTAssertEqual(usersWhoLikeRecipe.count, 1)
            XCTAssertEqual(usersWhoLikeRecipe[0].name, user.name)
            XCTAssertEqual(usersWhoLikeRecipe[0].username, user.username)
            XCTAssertEqual(usersWhoLikeRecipe[0].id, user.id)
        })
    }

    func testGetRecipesAUserLikes() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: user, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "/api/users/\(user.id!)/recipes/likes", afterResponse: { response in
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
        
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(anotherRecipe.id!)/likes/", loggedInUser: user, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "/api/users/\(user.id!)/recipes/likes", afterResponse: { response in
            let recipesAUserLikes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipesAUserLikes.count, 2)
        })
    }
//    userLikesRecipeRoutes.get("users", ":userID", "recipes", ":recipeID", "likes", use: getRecipeUserLikes)
    func testGetRecipeAUserLikes() throws {
        let user = try User.create(on: app.db)
        let recipe = try Recipe.create(on: app.db)
//        _ = try UserLikesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        
        try app.test(.POST, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: user, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        let getRecipeURI = "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes"
        try app.test(.GET, getRecipeURI, afterResponse: { response in
            XCTAssert(response.status == .ok)
            let responseRecipe = try response.content.decode(Recipe.self)
            XCTAssertEqual(responseRecipe.id, recipe.id)
        })
    }
    
    func testUserUnlikesARecipe() throws {
        let recipe = try Recipe.create(on: app.db)
        let user = try User.create(on: app.db)
        _ = try UserLikesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        
        try app.test(.GET, "\(recipesURI)likes", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let userLikesRecipeObjects = try response.content.decode([UserLikesRecipePivot].self)
            XCTAssertEqual(userLikesRecipeObjects.count, 1)
        })
//        "users", ":userID", "likes", "recipes", ":recipeID"
        try app.test(.DELETE, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: user, afterResponse: { response in
            XCTAssert(response.status == .noContent)
            try app.test(.GET, "\(recipesURI)likes", afterResponse: { response in
                let userLikesRecipeObjects = try response.content.decode([UserLikesRecipePivot].self)
                XCTAssertEqual(userLikesRecipeObjects.count, 0)
            })
        })        
    }
    
    func testUserMustBeLoggedInToUnlikeRecipe() throws {
        let recipe = try Recipe.create(on: app.db)
        let user = try User.create(on: app.db)
        _ = try UserLikesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        
        try app.test(.DELETE, "/api/users/\(user.id!)/recipes/\(recipe.id!)/likes/", afterResponse: { response in
            XCTAssert(response.status == .unauthorized)
        })
    }
    
    // Someone logged into another account cannot request to unlike a recipe for another user, they must be logged into that account
    func testAnotherUserCannotUnlikeRecipeForUser() throws {
        let anotherUser = try User.create(on: app.db)
        let targetUser = try User.create(on: app.db)
        let recipe = try Recipe.create(on: app.db)
        _ = try UserLikesRecipePivot.create(user: targetUser, recipe: recipe, on: app.db)
        
        try app.test(.DELETE, "/api/users/\(targetUser.id!)/recipes/\(recipe.id!)/likes/", loggedInUser: anotherUser, afterResponse: { response in
            XCTAssert(response.status == .forbidden)
        })
    }
    
    func testAdminCanUnlikeRecipeOfUser() throws {
        let adminUser = try User.create(admin: true, on: app.db)
        let targetUser = try User.create(on: app.db)
        let recipe = try Recipe.create(on: app.db)
        _ = try UserLikesRecipePivot.create(user: targetUser, recipe: recipe, on: app.db)
        
        try app.test(.DELETE, "/api/users/\(targetUser.id!)/recipes/\(recipe.id!)/likes", loggedInUser: adminUser, afterResponse: { response in
            XCTAssert(response.status == .noContent)
        })
        
        try app.test(.GET, "\(recipesURI)likes", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let userLikesRecipeObjects = try response.content.decode([UserLikesRecipePivot].self)
            XCTAssertEqual(userLikesRecipeObjects.count, 0)
        })
    }
}
