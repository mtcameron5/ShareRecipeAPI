//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/14/21.
//

import Vapor
import Fluent

struct UserConnectionsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userConnectionRoutes = routes.grouped("api", "users", "connections")
        userConnectionRoutes.get(use: getAllConnectionsHandler)
        userConnectionRoutes.post(":followerID", "follows", ":followedID", use: createConnectionHandler)
        userConnectionRoutes.delete(":connectionID", use: deleteConnectionHandler)
        userConnectionRoutes.get(":userID", "followers", use: getFollowersHandler)
        userConnectionRoutes.get(":userID", "follows", use: getFollowedHandler)
    }
    
    func getAllConnectionsHandler(_ req: Request) throws -> EventLoopFuture<[UserConnectionPivot]> {
        return UserConnectionPivot.query(on: req.db).all()
    }
    
    func createConnectionHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let followerQuery = User.find(req.parameters.get("followerID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let followedQuery = User.find(req.parameters.get("followedID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        return followerQuery.and(followedQuery)
            .flatMap { follower, followed in
                follower.$followed.attach(followed, on: req.db).transform(to: .created)
            }
    }
    
    func deleteConnectionHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        UserConnectionPivot.find(req.parameters.get("connectionID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap({ userConnection in
                userConnection.delete(on: req.db).transform(to: .noContent)
            })
    }
    
    func getFollowersHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$follower.get(on: req.db).convertToPublic()
            }
    }
    
    func getFollowedHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$followed.get(on: req.db).convertToPublic()
            }
    }
}
