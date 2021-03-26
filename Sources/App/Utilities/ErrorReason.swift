//
//  File.swift
//  
//
//  Created by Cameron Augustine on 3/25/21.
//

import Foundation

enum ErrorReason: String {
    case forbiddenCategoryToRecipeRequest = "You must have created the recipe to add it to a category."
    case forbiddenDeleteRecipeRequest = "You must have created the recipe or be an admin to delete the recipe."
    case forbiddenUpdateRecipeRequest = "You must have created the recipe or be an admin to update the recipe."
    case forbiddenFollowUserRequest = "You must be logged in as the user of the account to follow someone."
    case forbiddenUnfollowUserRequest = "You must be logged in as the user of the account or an admin to unfollow someone."
    case forbiddenRateRecipeRequest = "You must be logged in as the user of the account to rate a recipe."
    case forbideenUpdateRatingOfRecipeRequest = "You must be logged in as the user of the account to update a rating of a recipe."
    case forbiddenDeleteRatingRequest = "You must be logged in as the user of the account or an admin to remove the rating of a recipe"
    case forbiddenUserLikesRecipeRequest = "You must be logged in as the user of the account to save a recipe."
    case forbiddenUserUnlikesRecipeRequest = "You must be logged in as the user of the account to unsave a recipe."
    
}
