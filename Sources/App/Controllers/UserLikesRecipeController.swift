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
        userLikesRecipeRoutes.post("users", ":userID", "likes", ":recipeID", use: createUserLikesRecipeHandler)
        userLikesRecipeRoutes.get("recipes", ":recipeID", "likedby", "users", use: getUsersWhoLikeRecipe)
        userLikesRecipeRoutes.get("users", ":userID", "recipe", "likes", use: getRecipesUserLikes)
        userLikesRecipeRoutes.delete("users", "unlikes", "recipe", ":likeRecipeObjectID", use: userUnlikesRecipeHandler)
    }
    
    func getAllUserLikesRecipeObjects(_ req: Request) throws -> EventLoopFuture<[UserLikesRecipePivot]> {
        return UserLikesRecipePivot.query(on: req.db).all()
    }
    
    func createUserLikesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))

        return recipeQuery.and(userQuery)
            .flatMap { recipe, user in
                recipe.$usersThatLikeRecipe.attach(user, on: req.db).transform(to: .created)
            }
    }
    
    func getUsersWhoLikeRecipe(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                recipe.$usersThatLikeRecipe.get(on: req.db).convertToPublic()
            }
    }
    
    func getRecipesUserLikes(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$recipeLikes.get(on: req.db)
            }
    }
    
    func userUnlikesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        UserLikesRecipePivot.find(req.parameters.get("likeRecipeObjectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap({ userLikesRecipeObject in
                userLikesRecipeObject.delete(on: req.db).transform(to: .noContent)
            })
    }
    
}
