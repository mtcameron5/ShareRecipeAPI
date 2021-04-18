import Fluent
import Vapor

func routes(_ app: Application) throws {
//    app.get { req in
//        return "It works!"
//    }
//
//    app.get("hello", "vapor") { req -> String in
//        return "Hello Vapor!"
//    }
    
    let usersController = UsersController()
    try app.register(collection: usersController)
    
    let recipesController = RecipesController()
    try app.register(collection: recipesController)
    
    let userLikeRecipeController = UserLikesRecipeController()
    try app.register(collection: userLikeRecipeController)
    
    let ratingsController = RatingsController()
    try app.register(collection: ratingsController)
    
    let userConnectionsController = UserConnectionsController()
    try app.register(collection: userConnectionsController)
    
    let categoriesController = CategoriesController()
    try app.register(collection: categoriesController)
    
    let userWorkingOnRecipeController = UserWorkingOnRecipeController()
    try app.register(collection: userWorkingOnRecipeController)
    
    let userFinishedRecipeController = UserFinishedRecipeController()
    try app.register(collection: userFinishedRecipeController)
}
