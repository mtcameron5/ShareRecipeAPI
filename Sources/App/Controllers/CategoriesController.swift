//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoute = routes.grouped("api", "categories")
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", "recipes", use: getRecipesHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":categoryID", use: updateHandler)
        tokenAuthGroup.delete(":categoryID", use: deleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        return Category.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let user = try req.auth.require(User.self)
        guard let userIsAdmin = user.admin else {
            throw Abort(.badRequest)
        }
        
        if !userIsAdmin {
            throw Abort(.forbidden)
        }
        
        let category = try req.content.decode(Category.self)
        return category.save(on: req.db).map { category }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let newCategoryData = try req.content.decode(Category.self)
        let user = try req.auth.require(User.self)
        if !user.admin! {
            throw Abort(.forbidden)
        }

        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { category in
                category.name = newCategoryData.name
                return category.save(on: req.db).map { category }
            }
    }
    
    func getRecipesHandler(_ req: Request) throws -> EventLoopFuture<[Recipe]> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.$recipes.get(on: req.db)
            }
    }
    
    func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        if !user.admin!  {
            throw Abort(.forbidden)
        }
        
        return Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { category in
                category.delete(on: req.db).transform(to: .ok)
            }
    }
    
}
