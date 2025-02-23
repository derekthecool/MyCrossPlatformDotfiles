function Invoke-Mysql
{
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [int]$Port = 3306,
        [string]$Server = 'localhost',
        [Parameter(Mandatory)]
        [string]$Database = 'OrionPineappleFota',
        [Parameter(Mandatory)]
        [string]$Query
    )

    try
    {
        Open-MySqlConnection `
            -Port $Port `
            -Server $Server `
            -Credential $(Get-Secret $Name) `
            -ConnectionName $Name `
            -Database $Database `
            -CommandTimeout 10000

        switch -Regex ($Query)
        {
            "(insert|update|delete)"
            {
                Invoke-SqlUpdate -ConnectionName $Name -Query $Query
                | ForEach-Object { Write-Output "Rows affected: $_" }
            }
            default
            {
                Invoke-SqlQuery -ConnectionName $Name -Query $Query
            }
        }
    } catch
    {
        Write-Error "Problem with mysql connection: $_"
    }
}
