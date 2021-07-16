//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Vapor
import Fluent

struct RecipesController: RouteCollection {
    let imageFolder = "RecipeImages/"
    
    func boot(routes: RoutesBuilder) throws {
        let recipeRoutes = routes.grouped("api", "recipes")
        recipeRoutes.get(use: getAllHandler)
        recipeRoutes.get(":recipeID", use: getHandler)
        recipeRoutes.get(":recipeID", "user", use: getUserHandler)
        recipeRoutes.get("first", use: getFirstHandler)
        recipeRoutes.get("search", use: getSearchHandler)
        recipeRoutes.get("sorted", use: getSortedHandler)
        recipeRoutes.get(":recipeID", "categories", use: getCategoriesOfRecipe)
        recipeRoutes.get(":recipeID", "categories", ":categoryID", use: getCategoryOfRecipeHandler)
        
        // find recipe picture and upload recipe picture handlers
        recipeRoutes.get(":recipeID", "recipePicture", use: getRecipePictureHandler)
        recipeRoutes.post(":recipeID", "addRecipePicture", use: addRecipePictureHandler)
        
//        recipeRoutes.on(.POST, ":recipeID", "addRecipePicture", body: .collect(maxSize: "10mb"), use: addRecipePictureHandler)
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = recipeRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
  
        tokenAuthGroup.put(":recipeID", use: updateHandler)
        tokenAuthGroup.delete(":recipeID", use: deleteHandler)
        tokenAuthGroup.post(":recipeID", "categories", ":categoryID", use: addCategoryHandler)
        tokenAuthGroup.delete(":recipeID", "categories", ":categoryID", use: removeCategoryHandler)
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
        let user = try req.auth.require(User.self)
        let recipe = try Recipe(name: data.name, ingredients: data.ingredients, servings: data.servings, prepTime: data.prepTime, cookTime: data.cookTime, directions: data.directions, userID: user.requireID())
        return recipe.save(on: req.db).map { recipe }
    }
    
    func addRecipePictureHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let data = try req.content.decode(ImageUploadData.self)
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                let recipeID: UUID
                do {
                    recipeID = try recipe.requireID()
                } catch {
                    return req.eventLoop.future(error: error)
                }
                
                let name = "\(recipeID)-\(UUID()).jpg"
                
                print("Name: ", name)
                
                let path = req.application.directory.workingDirectory + imageFolder + name
                print("Path: ", path)
                print("===========")
                print("req.application.directory.workingDirectory", req.application.directory.workingDirectory)
                return req.fileio
                    .writeFile(.init(data: data.picture), at: path)
                    .flatMap {
                        recipe.recipePicture = name
                        return recipe.save(on: req.db).map({ recipe })
                    }
            }
    }
    
    func getRecipePictureHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { recipe in
                guard let filename = recipe.recipePicture else {
                    throw Abort(.notFound)
                }
                let path = req.application.directory
                    .workingDirectory + imageFolder + filename
                return req.fileio.streamFile(at: path)
            }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Recipe> {
        let updateData = try req.content.decode(CreateRecipeData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { recipe in
                return recipe.$user.$id.value.flatMap({ recipeUserID in
                    if recipeUserID == user.id! || user.admin! {
                        recipe.name = updateData.name
                        recipe.ingredients = updateData.ingredients
                        recipe.directions = updateData.directions
                        recipe.servings = updateData.servings
                        recipe.cookTime = updateData.cookTime
                        recipe.prepTime = updateData.prepTime
                        recipe.$user.id = userID
                        return recipe.save(on: req.db).map { recipe }
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUpdateRecipeRequest.rawValue))
                    }
                })!
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { recipe in
                return recipe.$user.$id.value.flatMap({ recipeUserID in
                    // recipeUserID == user.id! Checks if the creator of the recipe is the user who logged in via Bearer Token
                    if recipeUserID == user.id! || user.admin! {
                        return recipe.delete(on: req.db).transform(to: .noContent)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenDeleteRecipeRequest.rawValue))
                    }
                })!
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
    
    func getCategoriesOfRecipe(_ req: Request) throws -> EventLoopFuture<[Category]> {
        return Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { recipe in
                return recipe.$categories.get(on: req.db)
            }
    }
    
    func getCategoryOfRecipeHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let recipeQuery = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeQuery.and(categoryQuery).flatMap { recipe, category in
            return recipe.$categories.isAttached(to: category, on: req.db).flatMap { categoryIsAttachedTo in
                if categoryIsAttachedTo {
                    return req.eventLoop.future(category)
                } else {
                    return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: ErrorReason.notFoundCategoryExistsButNotAttachedToRecipeRequest.rawValue))
                }
            }
        }
    }
    
    func addCategoryHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let recipeToAdd = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryToAddRecipeTo = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return recipeToAdd.and(categoryToAddRecipeTo).flatMap { recipe, category in
            let recipeUserID = recipe.$user.$id.wrappedValue
            if recipeUserID == user.id! || user.admin! {
                return recipe.$categories.attach(category, on: req.db).transform(to: .created)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenCategoryToRecipeRequest.rawValue))
            }
//            return recipe.$user.$id.value.flatMap({ recipeUserID in
//                if recipeUserID == user.id! || user.admin!  {
//                    return recipe.$categories.attach(category, on: req.db).transform(to: .created)
//                } else {
//                    return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenCategoryToRecipeRequest.rawValue))
//                }
//            })!
        }
    }

    func removeCategoryHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let recipeToAdd = Recipe.find(req.parameters.get("recipeID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let categoryToAddRecipeTo = Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return recipeToAdd.and(categoryToAddRecipeTo).flatMap { recipe, category in
            recipe.$categories.detach(category, on: req.db).transform(to: .noContent)
        }
    }
    
}

struct CreateRecipeData: Content {
    let name: String
    let ingredients: [String]
    let directions: [String]
    let servings: Int
    let prepTime: String
    let cookTime: String
}

struct ImageUploadData: Content {
    var picture: Data
}
