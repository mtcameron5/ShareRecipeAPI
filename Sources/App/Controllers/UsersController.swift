//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        userRoutes.get(use: getAllHandler)
        userRoutes.get(":userID", use: getHandler)
        userRoutes.get(":userID", "recipes", use: getAllRecipesUserCreatedHandler)
        userRoutes.get(":userID", "recipes", ":recipeID", use: getRecipeUserCreatedHandler)
        userRoutes.get("token", ":tokenValue", use: getUserFromTokenHandler)
        userRoutes.post(use: createHandler)
        userRoutes.delete(":userID", use: deleteHandler)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = userRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound)).convertToPublic()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let userData = try req.content.decode(CreateUserData.self)
        let user = User(name: userData.name, username: userData.username, password: userData.password, admin: false)
        user.password = try Bcrypt.hash(user.password)
        
        return user.save(on: req.db).map { user.convertToPublic() }
//        return user.save(on: req.db).map { user.convertToPublic() }
    }
    
    func getAllRecipesUserCreatedHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$recipes.get(on: req.db)
            }
    }
    
    func getRecipeUserCreatedHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound, reason: ErrorReason.notFoundUserRequest.rawValue))
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound, reason: ErrorReason.notFoundRecipeRequest.rawValue))
        return userQuery.and(recipeQuery).flatMap { user, recipe in
            return user.$recipes.get(on: req.db).flatMap { usersRecipes in
                
                for usersRecipe in usersRecipes {
                    if usersRecipe.id! == recipe.id! {
                        return req.eventLoop.future(usersRecipe)
                    }
                }
                return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: ErrorReason.notFoundRecipesUserCreatedRequest.rawValue))
            }
        }
    }
    
    func getUserFromTokenHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let tokenQueryValue = req.parameters.get("tokenValue")
        let tokensAll = Token.query(on: req.db).all()
        return tokensAll.flatMap { tokens in
            for token in tokens {
                if token.value == tokenQueryValue {
                    return token.$user.get(on: req.db).convertToPublic()
                }
            }
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: ErrorReason.notFoundTokenRequest.rawValue))
        }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.delete(on: req.db).transform(to: .noContent)
            }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }
    
}

struct CreateUserData: Content {
    let name: String
    let username: String
    let password: String
}
