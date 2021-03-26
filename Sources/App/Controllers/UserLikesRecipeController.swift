//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/16/21.
//

import Vapor
import Fluent

struct UserLikesRecipeController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userLikesRecipeRoutes = routes.grouped("api")
        userLikesRecipeRoutes.get("recipes", "likes", use: getAllUserLikesRecipeObjects)
        userLikesRecipeRoutes.get("recipes", ":recipeID", "likedby", "users", use: getUsersWhoLikeRecipe)
        userLikesRecipeRoutes.get("users", ":userID", "recipe", "likes", use: getRecipesUserLikes)
        
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userLikesRecipeRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        tokenAuthGroup.post("users", ":userID", "likes", ":recipeID", use: createUserLikesRecipeHandler)
        tokenAuthGroup.delete("users", "unlikes", "recipe", ":likeRecipeObjectID", use: userUnlikesRecipeHandler)
    }
    
    func getAllUserLikesRecipeObjects(_ req: Request) throws -> EventLoopFuture<[UserLikesRecipePivot]> {
        return UserLikesRecipePivot.query(on: req.db).all()
    }
    
    func createUserLikesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        return recipeQuery.and(userQuery).flatMap { recipe, user in
                if user.id! == loggedInUser.id || user.admin! {
                    return recipe.$usersThatLikeRecipe.attach(user, on: req.db).transform(to: .created)
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserLikesRecipeRequest.rawValue))
                }
            }
    }
    
    func getUsersWhoLikeRecipe(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { recipe in
                recipe.$usersThatLikeRecipe.get(on: req.db).convertToPublic()
            }
    }
    
    func getRecipesUserLikes(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { user in
                user.$recipeLikes.get(on: req.db)
            }
    }
    
    func userUnlikesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        
        return UserLikesRecipePivot.find(req.parameters.get("likeRecipeObjectID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { userLikesRecipeObject in
                return userLikesRecipeObject.$user.$id.value.flatMap { userThatLikesRecipeID in
                    if userThatLikesRecipeID == loggedInUser.id! || loggedInUser.admin! {
                        return userLikesRecipeObject.delete(on: req.db).transform(to: .noContent)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserUnlikesRecipeRequest.rawValue))
                    }
                }!
            }
    }
    
}
