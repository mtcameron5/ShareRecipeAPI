//
//  File.swift
//  
//
//  Created by Cameron Augustine on 4/21/21.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            passwordHash = try Bcrypt.hash("Please89793$$#")
        } catch {
            return database.eventLoop.future(error: error)
        }
        let user = User(name: "Admin", username: "mtcameron5", password: passwordHash)
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$username == "admin").delete()
    }
    
}
