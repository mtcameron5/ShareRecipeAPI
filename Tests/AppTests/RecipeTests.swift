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
        _ = try Recipe.create(on: app.db)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 2)
            XCTAssertEqual(recipes[0].name, recipeName)
            XCTAssertEqual(recipes[0].ingredients, recipeIngredients)
            XCTAssertEqual(recipes[0].directions, recipeDirections)
            XCTAssertEqual(recipes[0].cookTime, recipeCookTime)
            XCTAssertEqual(recipes[0].prepTime, recipePrepTime)
            XCTAssertEqual(recipes[0].servings, recipeServings)
            XCTAssertEqual(recipes[0].id, recipe1.id)
        })
    }
    
    func testRecipeCanBeSavedWithAPI() throws {
        user = try User.create(on: app.db)
        let createRecipeData = CreateRecipeData(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, userID: user.id!, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime)
        
        try app.test(.POST, recipesURI, beforeRequest: { request in
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
    
    func testGettingASingleRecipeFromApi() throws {
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)

        try app.test(.GET, "\(recipesURI)\(recipe.id!)", afterResponse: { response in
            let receivedRecipe = try response.content.decode(Recipe.self)
            testRecipeProperties(recipe: receivedRecipe)
        })
    }
    

    
    func testDeletingRecipe() throws {
        let recipe = try Recipe.create(on: app.db)
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let recipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(recipes.count, 1)
        })
        
        try app.test(.DELETE, "\(recipesURI)\(recipe.id!)")
        
        try app.test(.GET, recipesURI, afterResponse: { response in
            let newRecipes = try response.content.decode([Recipe].self)
            XCTAssertEqual(newRecipes.count, 0)
        })
    }
    
    func testUpdatingARecipe() throws {
        user = try User.create(on: app.db)
        
        let recipe = try Recipe.create(name: recipeName, ingredients: recipeIngredients, directions: recipeDirections, user: user, servings: recipeServings, prepTime: recipePrepTime, cookTime: recipeCookTime, on: app.db)
        
        try app.test(.GET, "\(recipesURI)\(recipe.id!)", afterResponse: { response in
            let originalRecipe = try response.content.decode(Recipe.self)
            testRecipeProperties(recipe: originalRecipe)
        })
        
        let updatedRecipe = CreateRecipeData(name: "Gourmet Curry", ingredients: ["Gourmet Ingredients"], directions: ["Cook Gourmet Ingredients"], userID: user.id!, servings: 12, prepTime: "30 Minutes", cookTime: "30 Minutes")
        
        try app.test(.PUT, "\(recipesURI)\(recipe.id!)", beforeRequest: { request in
            try request.content.encode(updatedRecipe)
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

//    func testRecipesCategories() throws {
//        let category = try Category.create(on: app.db)
//        let category2 = try Category.create(name: "Funny", on: app.db)
//        let acronym = try Acronym.create(on: app.db)
//
//        try app.test(.POST, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)")
//        try app.test(.POST, "\(acronymsURI)\(acronym.id!)/categories/\(category2.id!)")
//
//        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories", afterResponse: { response in
//            let categories = try response.content.decode([App.Category].self)
//            XCTAssertEqual(categories.count, 2)
//            XCTAssertEqual(categories[0].id, category.id)
//            XCTAssertEqual(categories[0].name, category.name)
//            XCTAssertEqual(categories[1].id, category2.id)
//            XCTAssertEqual(categories[1].name, category2.name)
//        })
//
//        try app.test(.DELETE, "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)")
//
//        try app.test(.GET, "\(acronymsURI)\(acronym.id!)/categories", afterResponse: { response in
//            let newCategories = try response.content.decode([App.Category].self)
//            XCTAssertEqual(newCategories.count, 1)
//        })
//
//    }
    
    func testRecipeProperties(recipe: Recipe) {
        XCTAssertEqual(recipe.name, recipeName)
        XCTAssertEqual(recipe.ingredients, recipeIngredients)
        XCTAssertEqual(recipe.directions, recipeDirections)
        XCTAssertEqual(recipe.servings, recipeServings)
        XCTAssertEqual(recipe.cookTime, recipeCookTime)
        XCTAssertEqual(recipe.prepTime, recipePrepTime)
        XCTAssertNotNil(recipe.id)
    }
    
}
