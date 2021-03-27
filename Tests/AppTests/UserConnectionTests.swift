//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/12/21.
//

@testable import App
import XCTVapor

final class UserConnectionTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersConnectionsURI = "/api/users/connections/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testUserFollowsSomeone() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: followerUser, afterResponse: { response in
            XCTAssert(response.status == .created)
        })
    }
    
    func testUserCannotFollowIfNotLoggedIn() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
    
    func testUserCannotFollowFromADifferentAccount() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        let anotherUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: anotherUser, afterResponse: { response in
            XCTAssertEqual(response.status, .forbidden)
        })
    }
    
    func testUserCanUnfollow() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: followerUser, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, usersConnectionsURI, loggedInUser: followerUser, afterResponse: { response in
            let userConnections = try response.content.decode([UserConnectionPivot].self)
            try app.test(.DELETE, "\(usersConnectionsURI)\(userConnections[0].id!)", loggedInUser: followerUser, afterResponse: { response in
                XCTAssertEqual(response.status, .noContent)
            })
        })
        
        try app.test(.GET, usersConnectionsURI, loggedInUser: followerUser, afterResponse: { response in
            let userConnections = try response.content.decode([UserConnectionPivot].self)
            XCTAssertEqual(userConnections.count, 0)
        })
    }
    
    // This test is when a user is logged into an account, but they are trying to make an unfollow action for a different account. The DELETE request should return a forbidden response
    func testUserCannotUnfollowPeopleFromDifferentAccount() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        let someUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: followerUser, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, usersConnectionsURI, loggedInUser: followerUser, afterResponse: { response in
            let userConnections = try response.content.decode([UserConnectionPivot].self)
            try app.test(.DELETE, "\(usersConnectionsURI)\(userConnections[0].id!)", loggedInUser: someUser, afterResponse: { response in
                XCTAssertEqual(response.status, .forbidden)
            })
        })
    }
    
    func testGetFollowersOfUserFromAPI() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: followerUser, afterResponse: { response in
            XCTAssert(response.status == .created)
        })
        
        try app.test(.GET, "\(usersConnectionsURI)\(followedUser.id!)/followers", afterResponse: { response in
            let followedUsers = try response.content.decode([User.Public].self)
            XCTAssertEqual(followedUsers.count, 1)
            XCTAssertEqual(followedUsers[0].name, followerUser.name)
            XCTAssertEqual(followedUsers[0].username, followerUser.username)
            XCTAssertEqual(followedUsers[0].id, followerUser.id)
        })
        
        let anotherFollower = try User.create(name: "Cameron", username: "mtcameron5", on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(anotherFollower.id!)/follows/\(followedUser.id!)", loggedInUser: anotherFollower, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(usersConnectionsURI)\(followedUser.id!)/followers", afterResponse: { response in
            let followedUsers = try response.content.decode([User.Public].self)
            XCTAssertEqual(followedUsers.count, 2)
        })
    }
    
    func testGetUsersAUserFollowsFromAPI() throws {
        let followedUser = try User.create(name: usersName, username: usersUsername, on: app.db)
        let followerUser = try User.create(on: app.db)
        
        try app.test(.POST, "\(usersConnectionsURI)\(followerUser.id!)/follows/\(followedUser.id!)", loggedInUser: followerUser, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        
        try app.test(.GET, "\(usersConnectionsURI)\(followerUser.id!)/follows", afterResponse: { response in
            let usersAUserFollows = try response.content.decode([User.Public].self)
            XCTAssertEqual(usersAUserFollows.count, 1)
            XCTAssertEqual(usersAUserFollows[0].name, followedUser.name)
            XCTAssertEqual(usersAUserFollows[0].username, followedUser.username)
            XCTAssertEqual(usersAUserFollows[0].id, followedUser.id)
        })
    }
    
    
}
