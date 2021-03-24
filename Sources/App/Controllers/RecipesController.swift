//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

struct RecipesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let recipeRoutes = routes.grouped("api", "recipes")
        recipeRoutes.get(use: getAllHandler)
        recipeRoutes.get(":recipeID", use: getHandler)
        recipeRoutes.get(":recipeID", "user", use: getUserHandler)
        recipeRoutes.post(use: createHandler)
        recipeRoutes.put(":recipeID", use: updateHandler)
        recipeRoutes.delete(":recipeID", use: deleteHandler)
        recipeRoutes.get("first", use: getFirstHandler)
        recipeRoutes.get("search", use: getSearchHandler)
        recipeRoutes.get("sorted", use: getSortedHandler)

    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        Recipe.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func getUserHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                recipe.$user.get(on: req.db).convertToPublic()
            }
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let data = try req.content.decode(CreateRecipeData.self)
        let recipe = Recipe(name: data.name, ingredients: data.ingredients, servings: data.servings, prepTime: data.prepTime, cookTime: data.cookTime, directions: data.directions, userID: data.userID)
        return recipe.save(on: req.db).map { recipe }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let updateData = try req.content.decode(CreateRecipeData.self)
        
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { recipe in
                recipe.name = updateData.name
                recipe.ingredients = updateData.ingredients
                recipe.directions = updateData.directions
                recipe.servings = updateData.servings
                recipe.cookTime = updateData.cookTime
                recipe.prepTime = updateData.prepTime
                recipe.$user.id = updateData.userID
                return recipe.save(on: req.db).map { recipe }
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                recipe.delete(on: req.db).transform(to: .noContent)
            }
    }
    
    func getSearchHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Recipe.query(on: req.db).group(.or) { or in
            or.filter(\.$name == searchTerm)
        }.all()
    }
    
    func getSortedHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        return Recipe.query(on: req.db)
            .sort(\.$name, .ascending)
            .all()
    }
    
    func getFirstHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        return Recipe.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
}

struct CreateRecipeData: Content {
    let name: String
    let ingredients: [String]
    let directions: [String]
    let userID: UUID
    let servings: Int
    let prepTime: String
    let cookTime: String
}

