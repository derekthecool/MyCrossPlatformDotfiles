function Invoke-SeleniumBasics  
{
    <#
        .SYNOPSIS
        Go to GitHub and click the login button
    #>
    $Driver = Start-SeDriver -Browser Firefox -StartURL 'https://github.com/adamdriscoll/selenium-powershell'
    Get-SeElement -By ClassName -All 'd-inline-block' | Where-Object { $_.Text }
    Invoke-SeClick -Element $element
}
# TODO: (Derek Lomax) 5/26/2024 9:55:30 PM, See what else Selenium can do
