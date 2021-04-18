//
//  File.swift
//  
//
//  Created by Cameron Augustine on 4/9/21.
//

import Vapor
import Fluent

struct UserWorkingOnRecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userWorksOnRecipeRoutes = routes.grouped("api", "users")
        userWorksOnRecipeRoutes.get(":userID", "recipes", "started", use: recipesUserStartedHandler)

        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userWorksOnRecipeRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)

        tokenAuthGroup.post(":userID", "recipes", ":recipeID", "started", use: userStartsRecipeHandler)
        tokenAuthGroup.delete(":userID", "recipes", ":recipeID", "started", use: userStopsRecipeHandler)
    }
    
    func recipesUserStartedHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { user in
                user.$recipesWorkingOn.get(on: req.db)
            }
    }
    
    func userStartsRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeQuery.and(userQuery).flatMap { recipe, user in
            if user.id! == loggedInUser.id || user.admin! {
                return recipe.$usersWorkingOnRecipe.attach(user, on: req.db).transform(to: .created)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserWorksOnRecipeRequest.rawValue))
            }
        }
    }
    
    func userStopsRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeQuery.and(userQuery).flatMap { recipe, user in
            if user.id! == loggedInUser.id || user.admin! {
                return recipe.$usersWorkingOnRecipe.detach(user, on: req.db).transform(to: .created)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUserWorksOnRecipeRequest.rawValue))
            }
        }
    }
    
    
}

