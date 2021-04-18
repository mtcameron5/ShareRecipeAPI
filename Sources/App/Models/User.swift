//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/9/21.
//

import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "admin")
    var admin: Bool?
    
    @Children(for: \.$user)
    var recipes: [Recipe]
    
    @Siblings(through: UserConnectionPivot.self, from: \.$follower, to: \.$followed)
    var followeds: [User]
    
    @Siblings(through: UserConnectionPivot.self, from: \.$followed, to: \.$follower)
    var followers: [User]
    
    @Siblings(through: UserLikesRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipeLikes: [Recipe]
    
    @Siblings(through: UserUsedRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipesFinished: [Recipe]
    
    @Siblings(through: UserWorkingOnRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipesWorkingOn: [Recipe]
    
    @Siblings(through: UserRatesRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipesRated: [Recipe]
    
    
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String, admin: Bool? = false) {
        self.name = name
        self.username = username
        self.password = password
        self.admin = admin
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
    
    // Learning purposes, doesn't actually convert User to User.Public
    func convertToPublic() -> Void {
        print("name", name)
    }
    
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

//extension User {
//    func convertToPublic() -> User.Public {
//        print(id)
//        return User.Public(id: id, name: name, username: username)
//    }
//}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { user in
            return user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { user in
            user.convertToPublic()
        }
    }
}


extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        return self.map { users in
            users.convertToPublic()
        }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
