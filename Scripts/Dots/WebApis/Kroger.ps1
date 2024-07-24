function Use-Kroger
{
    $KrogerApiKey = Get-Secret -Name KrogerApiKey -AsPlainText
    $KrogerClientId = Get-Secret -Name KrogerClientId -AsPlainText

    Get-Variable
}
