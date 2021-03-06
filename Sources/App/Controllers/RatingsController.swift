//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/14/21.
//

import Vapor
import Fluent

struct RatingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let ratingsRoutes = routes.grouped("api", "ratings")
        ratingsRoutes.get(use: getRatingsHandler)
        ratingsRoutes.get("recipes", ":recipeID", use: getRecipesRatings)
        ratingsRoutes.get("recipes", ":recipeID", "stripped", use: getRecipesRatingsStripped)
        ratingsRoutes.get("users", ":userID", use: getUsersRatings)
        ratingsRoutes.get("users", ":userID", "recipes", use: getRecipesAUserRatedHandler)
        ratingsRoutes.get("recipes", ":recipeID", "users", use: getUsersThatRatedRecipe)
        
        
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = ratingsRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        // "api", "recipes" ":recipeID", "users", ":userID", "ratings"
        tokenAuthGroup.post("users", ":userID", "rates", "recipes", ":recipeID", use: createUserRatesRecipeHandler)
        tokenAuthGroup.put(":ratingID", use: updateRatingHandler)
        tokenAuthGroup.delete("users", ":userID", "rates", "recipes", ":recipeID", use: deleteHandler)
    }
    
    func createUserRatesRecipeHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let ratingData = try req.content.decode(Rating.self)
        
        return recipeQuery.and(userQuery)
            .flatMap { recipe, user in
                if loggedInUser.id! == user.id! || loggedInUser.admin! {
                    let recipeRating = try! UserRatesRecipePivot(user: user, recipe: recipe, rating: ratingData.rating)
                    return recipeRating.save(on: req.db).transform(to: .created)
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenRateRecipeRequest.rawValue))
                }
            }
    }
    
    func updateRatingHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let updateData = try req.content.decode(Rating.self)
        
        return UserRatesRecipePivot.find(req.parameters.get("ratingID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { recipeRating in
                return recipeRating.$user.$id.value.flatMap( { userWhoCreatedRecipeID in
                    if userWhoCreatedRecipeID == loggedInUser.id! || loggedInUser.admin! {
                        recipeRating.rating = updateData.rating
                        return recipeRating.save(on: req.db).transform(to: .noContent)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUpdateRecipeRequest.rawValue))
                    }
                })!
            }
    }
    
    func getRatingsHandler(_ req: Request) throws -> EventLoopFuture<[UserRatesRecipePivot]> {
        UserRatesRecipePivot.query(on: req.db).all()
    }
    
    func getRecipesRatings(_ req: Request) throws -> EventLoopFuture<[UserRatesRecipePivot]> {
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        var recipeRatings = [UserRatesRecipePivot]()
        return UserRatesRecipePivot.query(on: req.db).all().and(recipeQuery).map({ userRatings, recipe -> [UserRatesRecipePivot] in
            for userRating in userRatings {
                if userRating.$recipe.id == recipe.id {
                    recipeRatings.append(userRating)
                }
            }
            return recipeRatings
        })
    }
    
    func getRecipesRatingsStripped(_ req: Request) throws -> EventLoopFuture<[RatingAndUserID]> {
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        var recipeRatings = [RatingAndUserID]()
        return UserRatesRecipePivot.query(on: req.db).all().and(recipeQuery).map({ userRatings, recipe -> [RatingAndUserID] in
            for userRating in userRatings {
                if userRating.$recipe.id == recipe.id {
                    recipeRatings.append(RatingAndUserID(id: userRating.id, userID: userRating.$user.id, rating: userRating.rating))
                }
            }
            return recipeRatings
        })
    }
    
    func getUsersRatings(_ req: Request) throws -> EventLoopFuture<[UserRatings]> {
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        var userRatings = [UserRatings]()
        return UserRatesRecipePivot.query(on: req.db).all().and(userQuery).map({ recipeRatings, user -> [UserRatings] in
            for recipeRating in recipeRatings {
                if recipeRating.$user.id == user.id {
                    userRatings.append(UserRatings(id: recipeRating.id, userID: recipeRating.$user.id, recipeID: recipeRating.$recipe.id, rating: recipeRating.rating))
                }
            }
            return userRatings
        })
    }
    
    func getRecipesAUserRatedHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                return user.$recipesRated.get(on: req.db)
            }
    }
    
    func getUsersThatRatedRecipe(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                return recipe.$usersThatRatesRecipe.get(on: req.db).convertToPublic()
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let loggedInUser = try req.auth.require(User.self)
        let userQuery = User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return userQuery.and(recipeQuery).flatMap { user, recipe in
            if loggedInUser.id! == user.id! || loggedInUser.admin! {
                return user.$recipesRated.detach(recipe, on: req.db).transform(to: .noContent)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenDeleteRatingRequest.rawValue))
            }
        }
    }
}


struct RecipeRating: Content {
    let rating: Float
    let userID: UUID
    let recipeID: UUID
}



struct Rating: Content {
    let rating: Float
}

struct RatingAndUserID: Content {
    let id: UUID?
    let userID: UUID
    let rating: Float
}

struct UserRatings: Content {
    let id: UUID?
    let userID: UUID
    let recipeID: UUID
    let rating: Float
}
