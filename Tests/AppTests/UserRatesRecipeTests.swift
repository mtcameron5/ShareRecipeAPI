//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/12/21.
//




@testable import App
import XCTVapor

final class UserRatesRecipeTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let userRatingsURI = "/api/ratings/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testSaveRatingToAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: app.db)
        let recipe = try Recipe.create(on: app.db)
        let rating = Rating(rating: 5.0)
        try app.test(.POST, "\(userRatingsURI)\(user.id!)/rates/\(recipe.id!)", beforeRequest: { request in
            try request.content.encode(rating)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(userRatingsURI)", afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings.count, 1)
            XCTAssertEqual(ratings[0].$user.id, user.id)
            XCTAssertEqual(ratings[0].$recipe.id, recipe.id)
        })
    }
    
    func testGetRatingsFromAPI() throws {
        let rating = try UserRatesRecipePivot.create(on: app.db)
        
        try app.test(.GET, "\(userRatingsURI)", afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings.count, 1)
            XCTAssertEqual(ratings[0].id, rating.id)
            XCTAssertEqual(ratings[0].rating, rating.rating)
        })
    }
    
    func testUpdateRatingFromAPI() throws {
        let rating = try UserRatesRecipePivot.create(on: app.db)
        let newRating = Rating(rating: 4.0)
        try app.test(.PUT, "\(userRatingsURI)\(rating.id!)", beforeRequest: { request in
            try request.content.encode(newRating)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        try app.test(.GET, userRatingsURI, afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings[0].rating, 4.0)
        })
    }
    
    func testGetARecipesRatings() throws {
        let user = try User.create(on: app.db)
        let secondUser = try User.create(name: "cameron", username: "theCameron", on: app.db)
        let recipe = try Recipe.create(on: app.db)
        let rating = try UserRatesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        let anotherRating = try UserRatesRecipePivot.create(user: secondUser, recipe: recipe, on: app.db)
        
        try app.test(.GET, "\(userRatingsURI)recipes/\(recipe.id!)", afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings.count, 2)
            XCTAssertEqual(ratings[0].id, rating.id)
            XCTAssertEqual(ratings[1].id, anotherRating.id)
            XCTAssertEqual(ratings[0].$user.id, user.id)
            XCTAssertEqual(ratings[1].$user.id, secondUser.id)
            XCTAssertEqual(ratings[0].$recipe.id, recipe.id)
            XCTAssertEqual(ratings[1].$recipe.id, recipe.id)
        })
    }
    
    func testGetAUsersRatings() throws {
        let user = try User.create(on: app.db)
        let rating = try UserRatesRecipePivot.create(user: user, on: app.db)
        let anotherRating = try UserRatesRecipePivot.create(user: user, on: app.db)
        
        try app.test(.GET, "\(userRatingsURI)user/\(user.id!)", afterResponse: { response in
            let ratings = try response.content.decode([UserRatings].self)
            XCTAssertEqual(ratings.count, 2)
            XCTAssertEqual(ratings[0].id, rating.id)
            XCTAssertEqual(ratings[1].id, anotherRating.id)
            XCTAssertEqual(ratings[0].id, rating.id)
            XCTAssertEqual(ratings[0].userID, user.id)
            XCTAssertEqual(ratings[1].userID, user.id)
        })
    }
    
    func testGetUsersWhoRatedARecipeFromAPI() throws {
        let user = try User.create(on: app.db)
        let anotherUser = try User.create(name: "cameron", username: "theCameron", on: app.db)
        let recipe = try Recipe.create(on: app.db)
        
        let _ = try UserRatesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        let _ = try UserRatesRecipePivot.create(user: anotherUser, recipe: recipe, on: app.db)
        
        try app.test(.GET, "\(userRatingsURI)recipes/\(recipe.id!)/users", afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[0].id, user.id)
            XCTAssertEqual(users[1].id, anotherUser.id)
        })
    }
    
    func testRemoveARatingFromRecipeFromAPI() throws {
        
        let rating = try UserRatesRecipePivot.create(on: app.db)
        
        try app.test(.GET, userRatingsURI, afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings.count, 1)
        })
        try app.test(.DELETE, "\(userRatingsURI)\(rating.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        try app.test(.GET, userRatingsURI, afterResponse: { response in
            let ratings = try response.content.decode([UserRatesRecipePivot].self)
            XCTAssertEqual(ratings.count, 0)
        })
        
    }
    
    func testGetRecipesAUserRatedFromAPI() throws {
        let user = try User.create(on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)
        let anotherRecipe = try Recipe.create(user: user, on: app.db)

        _ = try UserRatesRecipePivot.create(user: user, recipe: recipe, on: app.db)
        _ = try UserRatesRecipePivot.create(user: user, recipe: anotherRecipe, on: app.db)

        try app.test(.GET, "\(userRatingsURI)user/\(user.id!)/recipes", afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 2)
            XCTAssertEqual(recipes[0].id, recipe.id)
            XCTAssertEqual(recipes[1].id, anotherRecipe.id)
            XCTAssertEqual(recipes[0].$user.id, user.id)
            XCTAssertEqual(recipes[1].$user.id, user.id)
        })
    }
    

    // TODO


    ////        ratingsRoutes.get("user", ":userID", "recipes", use: getRecipesAUserRatedHandler)


                     
    // Completed
    //ratingsRoutes.get("recipes", ":recipeID", use: getRecipesRatings)
    //ratingsRoutes.get("recipes", ":recipeID", "users", use: getUsersThatRatedRecipe)
    //ratingsRoutes.get("user", ":userID", "recipes", use: getUsersRatings)
    //ratingsRoutes.post(":userID", "rates", ":recipeID", use: createUserRatesRecipeHandler)
    //ratingsRoutes.put(":ratingID", use: updateRatingHandler)
    //ratingsRoutes.delete(":ratingID", use: deleteHandler)
    //ratingsRoutes.get(use: getRatingsHandler)
        
}

