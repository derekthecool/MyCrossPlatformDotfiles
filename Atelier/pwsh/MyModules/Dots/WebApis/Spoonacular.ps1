function Use-SpoonacularApi
{
    # # Gets random recipes
    # Invoke-RestMethod -Uri "https://api.spoonacular.com/recipes/random" -Body @{
    #     apiKey = $(Get-Secret -Name SpoonacularApiKey -AsPlainText)
    # }


    # # Gets 10 recipes with an input ingredients list
    # Invoke-RestMethod -Uri "https://api.spoonacular.com/recipes/findByIngredients" -Body @{
    #     apiKey = $(Get-Secret -Name SpoonacularApiKey -AsPlainText)
    #     ingredients = "apples,parsley,chicken"
    # }
    #


    # Gets 10 recipes with an input ingredients list
    Invoke-RestMethod -Method Post -Uri "https://api.spoonacular.com/mealplanner/derekthecool/shopping-list/2024-07-15/2024-07-21" -Body @{
        apiKey = $(Get-Secret -Name SpoonacularApiKey -AsPlainText)
        # username = $(Get-Secret -Name SpoonacularUsername -AsPlainText)
        hash   = $(Get-Secret -Name SpoonacularUsernameHash -AsPlainText)
    }
}
