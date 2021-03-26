import Fluent
import Vapor

final class Recipe: Model {
    static let schema = "recipes"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "ingredients")
    var ingredients: [String]
    
    @Field(key: "directions")
    var directions: [String]
    
    @Parent(key: "userID")
    var user: User
    
    @Field(key: "servings")
    var servings: Int
    
    @Field(key: "prepTime")
    var prepTime: String
    
    @Field(key: "cookTime")
    var cookTime: String
    
    @Siblings(through: UserLikesRecipePivot.self, from: \.$recipe, to: \.$user)
    var usersThatLikeRecipe: [User]
    
    @Siblings(through: UserRatesRecipePivot.self, from: \.$recipe, to: \.$user)
    var usersThatRatesRecipe: [User]
    
    @Siblings(through: RecipeCategoryPivot.self, from: \.$recipe, to: \.$category)
    var categories: [Category]

    init() { }
    
//    init(id: UUID? = nil, name: String, ingredients: [String], directions: [String], userID: User.IDValue) {
//        self.id = id
//        self.name = name
//        self.ingredients = ingredients
//        self.directions = directions
//        self.$user.id = userID
//    }

    init(id: UUID? = nil, name: String, ingredients: [String], servings: Int, prepTime: String, cookTime: String, directions: [String], userID: User.IDValue) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.directions = directions
        self.$user.id = userID
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
    }
}

extension Recipe: Content { }
