//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/10/21.
//

import Fluent
import FluentPostgresDriver
import Vapor
struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("password", .string, .required)
            .field("admin", .bool, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}

struct AddPasswordToUserWithDefaultValue: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let sql = database as! SQLDatabase
        return sql.raw("ALTER TABLE users ADD COLUMN password text DEFAULT 'please' NOT NULL").run()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}

struct AddAdminToUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let sql = database as! SQLDatabase
        return sql.raw("ALTER TABLE users ADD COLUMN admin boolean DEFAULT false NOT NULL").run()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}

