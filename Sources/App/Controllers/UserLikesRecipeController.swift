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
        userLikesRecipeRoutes.get("recipes", ":recipeID", "users", "likes", use: getUsersWhoLikeRecipe)
        userLikesRecipeRoutes.get("users", ":userID", "recipes", "likes", use: getRecipesUserLikes)
        userLikesRecipeRoutes.get("users", ":userID", "recipes", ":recipeID", "likes", use: getRecipeUserLikes)
        userLikesRecipeRoutes.get("recipes", ":recipeID", "likes", use: getNumberOfRecipeLikes)
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userLikesRecipeRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        tokenAuthGroup.post("users", ":userID", "recipes", ":recipeID", "likes",  use: createUserLikesRecipeHandler)
        tokenAuthGroup.delete("users", ":userID", "recipes", ":recipeID", "likes", use: userUnlikesRecipeHandler)
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
    
    func getRecipeUserLikes(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound, reason: ErrorReason.notFoundUserRequest.rawValue))
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound, reason: ErrorReason.notFoundRecipeRequest.rawValue))

        return recipeQuery.and(userQuery).flatMap { recipe, user in
            return user.$recipeLikes.isAttached(to: recipe, on: req.db).flatMap { userLikesRecipe in
                if userLikesRecipe {
                    return req.eventLoop.future(recipe)
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: ErrorReason.notFoundRecipeUserLikesRequest.rawValue))
                }
            }
        }
        
    }
    
    func getNumberOfRecipeLikes(_ req: Request) throws -> EventLoopFuture<Int> {
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeQuery.flatMap { recipe in
            return recipe.$usersThatLikeRecipe.query(on: req.db).all().flatMap { users in
                return req.eventLoop.future(users.count)
            }
        }
    }

    func userUnlikesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return recipeQuery.and(userQuery).flatMap { recipe, user in
            if loggedInUser.id! == user.id! || loggedInUser.admin! {
                return user.$recipeLikes.detach(recipe, on: req.db).transform(to: .noContent)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserUnlikesRecipeRequest.rawValue))
            }
        }
    }
    
}
