$Script:CGA_Url = 'https://exchange.prx.org/series/31235-classical-guitar-alive'

function Get-ClassicalGuitarAlive
{
    [Alias('cga')]
    param ()
    Get-Site -Url $Script:CGA_Url

    # From the top page, get all the links to the individual weeks program
    scrape https://exchange.prx.org/series/31235-classical-guitar-alive -QuerySelectorFilter 'div.title a'
}
