# Demonstration of Kroger API Integration Workflow
# This script shows how to use the DotWebApi module for Kroger shopping

# Import the module
Import-Module DotWebApi -Force

Write-Host "=== Kroger API Integration Demo ===" -ForegroundColor Green
Write-Host ""

# Example 1: Test conversion functions with mock data
Write-Host "1. Testing conversion functions..." -ForegroundColor Yellow

\$mockProduct = @{
    productId   = '0011200000562'
    upc         = '0011200000562'
    description = 'Kroger Whole Milk'
    brand       = 'Kroger'
    categories  = @('Dairy', 'Milk')
    size        = '1 gal'
    items       = @(
        @{
            price    = @{
                regular = 3.49
                promo   = 2.99
            }
            stock    = @{
                level = 'IN_STOCK'
            }
            location = 'A1-2'
        }
    )
    images      = @()
}

\$product = \$mockProduct | ConvertTo-KrogerProduct
Write-Host "   Product: \$(\$product.Name)" -ForegroundColor Cyan
Write-Host "   Brand: \$(\$product.Brand)" -ForegroundColor Cyan
Write-Host "   Price: \$(\$product.Price)" -ForegroundColor Cyan
Write-Host "   On Sale: \$(\$product.OnSale)" -ForegroundColor Cyan
Write-Host "   In Stock: \$(\$product.InStock)" -ForegroundColor Cyan
Write-Host ""

# Example 2: Demonstrate pipeline workflow
Write-Host "2. Pipeline workflow example..." -ForegroundColor Yellow

\$mockProducts = @(
    @{ productId = '0011200000562'; upc = '0011200000562'; description = 'Kroger Milk'; brand = 'Kroger'; categories = @('Dairy'); size = '1 gal'; items = @(@{price = @{regular = 3.49; promo = 0 }; stock = @{level = 'IN_STOCK' }; location = 'A1' }); images = @() },
    @{ productId = '0011200000563'; upc = '0011200000563'; description = 'Generic Milk'; brand = 'Generic'; categories = @('Dairy'); size = '1 gal'; items = @(@{price = @{regular = 2.99; promo = 0 }; stock = @{level = 'OUT_OF_STOCK' }; location = 'A2' }); images = @() },
    @{ productId = '0011200000564'; upc = '0011200000564'; description = 'Premium Milk'; brand = 'Premium'; categories = @('Dairy'); size = '1 gal'; items = @(@{price = @{regular = 5.99; promo = 4.99 }; stock = @{level = 'IN_STOCK' }; location = 'B1' }); images = @() }
)

Write-Host "   All products:" -ForegroundColor Cyan
\$products = \$mockProducts | ForEach-Object { ConvertTo-KrogerProduct -ApiData \$_ }
\$products | ForEach-Object { Write-Host "     - \$(\$_.Name) (\$(\$_.Brand)): \$(\$_.Price)" }

Write-Host ""
Write-Host "   Filtered to in-stock Kroger brand:" -ForegroundColor Cyan
\$filtered = \$products | Where-Object { \$_.Brand -EQ 'Kroger' -and \$_.InStock }
\$filtered | ForEach-Object { Write-Host "     - \$(\$_.Name): \$(\$_.Price)" }

Write-Host ""
Write-Host "   Find sale items:" -ForegroundColor Cyan
\$saleItems = \$products | Where-Object { \$_.OnSale }
\$saleItems | ForEach-Object { Write-Host "     - \$(\$_.Name): \$(\$_.SalePrice) (was \$(\$_.Price))" }

Write-Host ""

# Example 3: Cart operations with mock data
Write-Host "3. Cart operations example..." -ForegroundColor Yellow

\$mockCartItem = @{
    id          = 'cart_item_1'
    productId   = '0011200000562'
    upc         = '0011200000562'
    quantity    = 2
    price       = @{ regular = 3.49 }
    description = 'Kroger Whole Milk'
}

\$cartItem = \$mockCartItem | ConvertTo-KrogerCartItem
Write-Host "   Cart Item: \$(\$cartItem.Name)" -ForegroundColor Cyan
Write-Host "   Quantity: \$(\$cartItem.Quantity)" -ForegroundColor Cyan
Write-Host "   Unit Price: \$(\$cartItem.Price)" -ForegroundColor Cyan
Write-Host "   Total: \$(\$cartItem.Total)" -ForegroundColor Cyan

Write-Host ""

# Show available functions
Write-Host "4. Available DotWebApi functions:" -ForegroundColor Yellow
Get-Command -Module DotWebApi | ForEach-Object {
    \$functionType = if (\$_.Name -like "*Kroger*") { "Kroger" }
    elseif (\$_.Name -like "*Spoonacular*") { "Spoonacular" }
    elseif (\$_.Name -like "*WebApi*") { "Common" }
    elseif (\$_.Name -like "*ConvertTo*") { "Common" }
    else { "Other" }
    Write-Host "   [\$functionType] \$(\$_.Name)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== Demo Complete ===" -ForegroundColor Green
Write-Host "Note: This demo uses mock data. For actual Kroger API usage:" -ForegroundColor Yellow
Write-Host "  1. Set your secrets: Set-Secret -Name 'KrogerApiKey' -Secret 'your-key'" -ForegroundColor Yellow
Write-Host "  2. Set your secrets: Set-Secret -Name 'KrogerClientId' -Secret 'your-client-id'" -ForegroundColor Yellow
Write-Host "  3. Use: Search-KrogerProduct -SearchTerm 'milk' | Add-KrogerCartItem" -ForegroundColor Yellow
