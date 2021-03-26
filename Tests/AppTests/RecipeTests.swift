@testable import App
import XCTVapor

final class RecipeTests: XCTestCase {
    let recipesURI = "/api/recipes/"
    let recipeName = "Chicken Curry"
    let recipeIngredients = ["Chicken", "Milk", "Curry Powder", "Butter"]
    let recipeDirections = ["Heat Milk", "Cook Chicken"]
    let recipeServings = 4
    let recipePrepTime = "10 Minutes"
    let recipeCookTime = "15 Minutes"
    var user: User!

    var app: Application!
    
    override func setUpWithError() throws {
      app = try Application.testable()
    }

    override func tearDown() {
      app.shutdown()
    }
    
    func testRecipesCanBeRetrievedFromAPI() throws {
        user = try User.create(on: app.db)
        let recipe1 = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        _ = try Recipe.create(user: user, on: app.db)
        
        try app.test(.GET, recipesURI, loggedInUser: user, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 2)
            testRecipeProperties(recipe: recipes[0])
            XCTAssertEqual(recipes[0].id, recipe1.id)
        })
    }
    
    func testRecipeCanBeSavedWithAPI() throws {
        user = try User.create(on: app.db)
        let createRecipeData = CreateRecipeData(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime)
        
        try app.test(.POST, recipesURI, loggedInUser: user, beforeRequest: { request in
            try request.content.encode(createRecipeData)
        }, afterResponse: { response in
            let receivedRecipe = try response.content.decode(Recipe.self)
            XCTAssertEqual(receivedRecipe.name, recipeName)
            XCTAssertEqual(receivedRecipe.ingredients, recipeIngredients)
            XCTAssertEqual(receivedRecipe.directions, recipeDirections)
            XCTAssertEqual(receivedRecipe.servings, recipeServings)
            XCTAssertEqual(receivedRecipe.cookTime, recipeCookTime)
            XCTAssertEqual(receivedRecipe.prepTime, recipePrepTime)
            XCTAssertNotNil(receivedRecipe.id)
            
            try app.test(.GET, recipesURI, afterResponse: { allRecipeResponse in
                let recipes = try allRecipeResponse.content.decode([Recipe].self)
                XCTAssertEqual(recipes.count, 1)
                XCTAssertEqual(recipes[0].name, recipeName)
                XCTAssertEqual(recipes[0].ingredients, recipeIngredients)
                XCTAssertEqual(recipes[0].directions, recipeDirections)
            })
        })
    }
    
    func testMustBeLoggedInToSaveToAPI() throws {
        let user = try User.create(on: app.db)
        let recipe = Recipe(name: recipeName, ingredients: recipeIngredients, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, directions: recipeDirections, userID: user.id!)
        
        try app.test(.POST, recipesURI, beforeRequest: { request in
            (try request.content.encode(recipe))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
            XCTAssertThrowsError(try response.content.decode(Recipe.self))
        })
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            
            // MARK: Learning: response can be decoded to [Recipe] despite no recipes being returned from response. type(of: recipes) returns Array<Recipe>
            print("+++++++++++++++++++++++++++++++")
            print("Recipes: ", type(of: recipes))
            print("+++++++++++++++++++++++++++++++")
            
            XCTAssertEqual(recipes.count, 0)
        })
    }
    
    
    func testGettingASingleRecipeFromAPI() throws {
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)

        try app.test(.GET, "\(recipesURI)\(recipe.id!)", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let receivedRecipe = try response.content.decode(Recipe.self)
            testRecipeProperties(recipe: receivedRecipe)
        })
    }

    
    func testAdminUserCanDeleteRecipe() throws {
        let adminUser = try User.create(admin: true, on: app.db)
        let recipe = try Recipe.create(on: app.db)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            XCTAssert(response.status == .ok)
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
        })
        
        try app.test(.DELETE, "\(recipesURI)\(recipe.id!)", loggedInUser: adminUser)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let newRecipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(newRecipes.count, 0)
        })
    }
    
    func testCreatorOfRecipeCanDeleteRecipe() throws {
        let creatorOfRecipeUser = try User.create(on: app.db)
        let recipe = try Recipe.create(user: creatorOfRecipeUser, on: app.db)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
        })
        
        try app.test(.DELETE, "\(recipesURI)\(recipe.id!)", loggedInUser: creatorOfRecipeUser, afterResponse: { response in
            XCTAssertEqual(response.status, .noContent)
        })
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 0)
        })
        
    }
    
    func testNonCreatorAndNonAdminCannotDeleteRecipe() throws {
        let normalUser = try User.create(admin: false, on: app.db)
        let creatorOfRecipeUser = try User.create(on: app.db)
        let recipe = try Recipe.create(user: creatorOfRecipeUser, on: app.db)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
        })
        
        try app.test(.DELETE, "\(recipesURI)\(recipe.id!)", loggedInUser: normalUser, afterResponse: { response in
            XCTAssert(response.status == .forbidden)
        })
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
        })
    }
    
    func testCreatorOfRecipeCanUpdateRecipe() throws {
        let userWhoCreatedRecipe = try User.create(on: app.db)
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: userWhoCreatedRecipe, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        
        // Test cases written in function below
        try updateRecipe(recipe: recipe, user: userWhoCreatedRecipe)
    }
    
    func testAdminCanUpdateRecipe() throws {
        let adminUser = try User.create(admin: true, on: app.db)
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        
        // Test cases written in function below
        try updateRecipe(recipe: recipe, user: adminUser)
        
    }
    
    func testNonCreatorAndNonAdminCannotUpdateRecipe() throws {
        let someUser = try User.create(username: "noncreator", admin: false, on: app.db)
        let recipe = try Recipe.create(on: app.db)
        
        let updatedRecipe = CreateRecipeData(name: "Beef Curry", ingredients: ["Gourmet Ingredients"], directions: ["Cook Gourmet Ingredients"], servings: 12, prepTime: "30 Minutes", cookTime: "30 Minutes")
        try app.test(.PUT, "\(recipesURI)\(recipe.id!)", loggedInUser: someUser, beforeRequest: { request in
            try request.content.encode(updatedRecipe)
        }, afterResponse: { response in
            XCTAssert(response.status == .forbidden)
        })
        
    }
    
    func testGettingARecipesUser() throws {
        let user = try User.create(on: app.db)
        let recipe = try Recipe.create(user: user, on: app.db)

        try app.test(.GET, "\(recipesURI)\(recipe.id!)/user", afterResponse: { response in
            let recipesUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(recipesUser.id, user.id)
            XCTAssertEqual(recipesUser.name, user.name)
            XCTAssertEqual(recipesUser.username, user.username)
        })
    }
    
    func testSearchRecipeName() throws {
        _ = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)

        try app.test(.GET, "\(recipesURI)search?term=Chicken+Curry", afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
            testRecipeProperties(recipe: recipes[0])
        })
    }

    func testGetFirstRecipe() throws {
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        let user = try User.create(on: app.db)
        _ = try Recipe.create(user: user, on: app.db)
        _ = try Recipe.create(user: user, on: app.db)

        try app.test(.GET, "\(recipesURI)first", afterResponse: { response in
            let firstRecipe = try response.content.decode(Recipe.self)
            XCTAssertEqual(firstRecipe.id, recipe.id)
            testRecipeProperties(recipe: firstRecipe)
        })
    }

    func testSortingRecipe() throws {
        let recipe1 = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        let user = try User.create(on: app.db)
        let recipe2 = try Recipe.create(user: user, on: app.db)

        try app.test(.GET, "\(recipesURI)sorted", afterResponse: { response in
            let sortedRecipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(sortedRecipes[0].id, recipe1.id)
            XCTAssertEqual(sortedRecipes[1].id, recipe2.id)
        })
    }

    func testRecipeProperties(recipe: Recipe) {
        XCTAssertEqual(recipe.name, recipeName)
        XCTAssertEqual(recipe.ingredients, recipeIngredients)
        XCTAssertEqual(recipe.directions, recipeDirections)
        XCTAssertEqual(recipe.servings, recipeServings)
        XCTAssertEqual(recipe.cookTime, recipeCookTime)
        XCTAssertEqual(recipe.prepTime, recipePrepTime)
        XCTAssertNotNil(recipe.id)
    }
    
    func updateRecipe(recipe: Recipe, user: User) throws {
        try app.test(.GET, "\(recipesURI)\(recipe.id!)", afterResponse: { response in
            XCTAssert(response.status == .ok)
            let originalRecipe = try response.content.decode(Recipe.self)
            testRecipeProperties(recipe: originalRecipe)
        })

        
        let updatedRecipe = CreateRecipeData(name: "Beef Curry", ingredients: ["Gourmet Ingredients"], directions: ["Cook Gourmet Ingredients"], servings: 12, prepTime: "30 Minutes", cookTime: "30 Minutes")
        
        try app.test(.PUT, "\(recipesURI)\(recipe.id!)", loggedInUser: user,  beforeRequest: { request in
            try request.content.encode(updatedRecipe)
        }, afterResponse: { response in
            XCTAssert(response.status == .ok)
        })
        
        try app.test(.GET, "\(recipesURI)\(recipe.id!)", afterResponse: { response in
            let newRecipe = try response.content.decode(Recipe.self)
            print(newRecipe)
            XCTAssertEqual(newRecipe.name, updatedRecipe.name)
            XCTAssertEqual(newRecipe.ingredients, updatedRecipe.ingredients)
            XCTAssertEqual(newRecipe.directions, updatedRecipe.directions)
            XCTAssertEqual(newRecipe.servings, updatedRecipe.servings)
            XCTAssertEqual(newRecipe.cookTime, updatedRecipe.cookTime)
            XCTAssertEqual(newRecipe.prepTime, updatedRecipe.prepTime)
        })
    }
}
