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
    
    case forbiddenFollowUserRequest = "You must be logged in as the user of the account to follow another user."
    
    case forbiddenUnfollowUserRequest = "You must be logged in as the user of the account or an admin to unfollow someone."
    
    case forbiddenRateRecipeRequest = "You must be logged in as the user of the account to rate a recipe."
    
    case forbideenUpdateRatingOfRecipeRequest = "You must be logged in as the user of the account to update a rating of a recipe."
    
    case forbiddenDeleteRatingRequest = "You must be logged in as the user of the account or an admin to remove the rating of a recipe"
    
    case forbiddenUserLikesRecipeRequest = "You must be logged in as the user of the account to save a recipe."
    
    case forbiddenUserWorksOnRecipeRequest = "You must be logged in as the user of the account to start working on a recipe."
    
    case forbiddenUserUnlikesRecipeRequest = "You must be logged in as the user of the account to unsave a recipe."
    
    case notFoundCategoryExistsButNotAttachedToRecipeRequest = "The recipe does not belong to this category."
    
    case notFoundRecipesUserCreatedRequest = "The recipe exists but the specified user did not create it."
    
    case notFoundRecipeUserLikesRequest = "The recipe exists but the specified user did not save it."
    
    case notFoundRecipeRequest = "A recipe with this ID does not exist."
    
    case notFoundUserRequest = "A user with this ID does not exist."
    
    case notFoundTokenRequest = "A token with that value does not exist."
}
