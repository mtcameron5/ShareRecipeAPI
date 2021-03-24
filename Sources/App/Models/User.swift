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
    
    @Children(for: \.$user)
    var recipes: [Recipe]
    
    @Siblings(through: UserConnectionPivot.self, from: \.$follower, to: \.$followed)
    var follower: [User]
    
    @Siblings(through: UserConnectionPivot.self, from: \.$followed, to: \.$follower)
    var followed: [User]
    
    @Siblings(through: UserLikesRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipeLikes: [Recipe]
    
    @Siblings(through: UserRatesRecipePivot.self, from: \.$user, to: \.$recipe)
    var recipesRated: [Recipe]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
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
