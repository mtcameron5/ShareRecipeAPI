//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/23/21.
//

@testable import App
import XCTVapor

final class CategoryTests: XCTestCase {
    let categoriesURI = "/api/categories/"
    var app: Application!
    
    override func setUp() {
        app = try! Application.testable()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testCategoryCanBeRetrievedFromAPI() throws {
        let category = try Category.create(on: app.db)
        try app.test(.GET, categoriesURI, afterResponse: { response in
            let categories = try response.content.decode([App.Category].self)
            XCTAssertEqual(categories.count, 1)
            XCTAssertEqual(categories[0].name, category.name)
            XCTAssertEqual(categories[0].id, category.id)
        })
    }
    
    func testCategoryCanBeSavedToAPI() throws {
        let category = App.Category(name: "Indian")
        
        try app.test(.POST, categoriesURI, beforeRequest: { request in
            try request.content.encode(category)
        }, afterResponse: { response in
            let responseCategory = try response.content.decode(App.Category.self)
            XCTAssertEqual(responseCategory.name, category.name)
            XCTAssertNotNil(responseCategory.id)
            
            try app.test(.GET, categoriesURI, afterResponse: { response in
                let categories = try response.content.decode([App.Category].self)
                XCTAssertEqual(categories.count, 1)
                XCTAssertEqual(categories[0].name, category.name)
                XCTAssertEqual(responseCategory.name, categories[0].name)
            })
        })
    }
    
    
    
}
