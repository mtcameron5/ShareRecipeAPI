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
//        let sql = database as! SQLDatabase
//        let query = SQLQueryString("INSERT INTO users(name, username, password, admin) VALUES \(raw: user.name), \(raw: user.username), \(raw: user.password), true")
//        return sql.raw(query).run()
        return user.save(on: database)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database).filter(\.$username == "mtcameron5").delete()
    }
}
