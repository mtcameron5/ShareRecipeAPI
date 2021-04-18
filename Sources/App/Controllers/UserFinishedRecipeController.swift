import Vapor
import Fluent

struct UserFinishedRecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userFinishedRecipeRoutes = routes.grouped("api", "users")
        userFinishedRecipeRoutes.get(":userID", "recipes", "finished", use: recipesUserFinishedHandler)

        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userFinishedRecipeRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)

        tokenAuthGroup.post(":userID", "recipes", ":recipeID", "finished", use: userFinishesRecipeHandler)
//        tokenAuthGroup.delete(":userID", "recipes", ":recipeID", "finished", use: userStopsRecipeHandler)
    }
    
    func recipesUserFinishedHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { user in
                user.$recipesFinished.get(on: req.db)
            }
    }
    
    func userFinishesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeQuery.and(userQuery).flatMap { recipe, user in
            if user.id! == loggedInUser.id || user.admin! {
                return recipe.$usersThatFinishedRecipe.attach(user, on: req.db).transform(to: .created)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserWorksOnRecipeRequest.rawValue))
            }
        }
    }
    
//    func userStopsRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        let loggedInUser = try req.auth.require(User.self)
//        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
//            .unwrap(or: Abort(.notFound))
//        return recipeQuery.and(userQuery).flatMap { recipe, user in
//            if user.id! == loggedInUser.id || user.admin! {
//                return recipe.$usersWorkingOnRecipe.detach(user, on: req.db).transform(to: .created)
//            } else {
//                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserWorksOnRecipeRequest.rawValue))
//            }
//        }
//    }
    
    
}

