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
        userConnectionRoutes.get(":userID", "followers", use: getFollowersHandler)
        userConnectionRoutes.get(":userID", "follows", use: getFollowedHandler)
        
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userConnectionRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        tokenAuthGroup.post(":followerID", "follows", ":followedID", use: createConnectionHandler)
        tokenAuthGroup.delete(":connectionID", use: deleteConnectionHandler)
    }
    
    func getAllConnectionsHandler(_ req: Request) throws -> EventLoopFuture<[UserConnectionPivot]> {
        return UserConnectionPivot.query(on: req.db).all()
    }
    
    func createConnectionHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let followerQuery = User.find(req.parameters.get("followerID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        let followedQuery = User.find(req.parameters.get("followedID"), on: req.db)
            .unwrap(or: Abort(.notFound))
        
        return followerQuery.and(followedQuery).flatMap { follower, followed in
            if follower.id! == user.id {
                return followed.$followers.attach(follower, on: req.db).transform(to: .created)
            } else {
                return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenFollowUserRequest.rawValue))
            }
        }
    }
    
    func deleteConnectionHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        
        return UserConnectionPivot.find(req.parameters.get("connectionID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { userConnection in
                return userConnection.$follower.$id.value.flatMap({ followerID in
                    if followerID == user.id! || user.admin! {
                        return userConnection.delete(on: req.db).transform(to: .noContent)
                    } else {
                        return req.eventLoop.makeFailedFuture(Abort(.forbidden, reason: ErrorReason.forbiddenUnfollowUserRequest.rawValue))
                    }
                })!
            }
    }
    
    func getFollowersHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$followers.get(on: req.db).convertToPublic()
            }
    }
    
    func getFollowedHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$followeds.get(on: req.db).convertToPublic()
            }
    }
}
