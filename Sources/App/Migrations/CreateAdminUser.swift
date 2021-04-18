//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/25/21.
//

import Fluent
import Vapor
import FluentPostgresDriver

struct CreateAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash("Please89793$$#")
        } catch {
            return database.eventLoop.future(error: error)
        }
        
        let user = User(name: "Cameron Augustine", username: "mtcameron5", password: passwordHash, admin: true)
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$username == "mtcameron5").delete()
    }
}
