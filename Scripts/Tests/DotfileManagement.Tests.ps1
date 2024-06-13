BeforeAll {
  # Extract just the filename without extension and replace '.Tests' with nothing, assuming the test script ends with '.Tests.ps1'
  $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
  $scriptName = $fileNameWithoutExtension -replace '\.Tests$', ''
  $scriptFileName = "$scriptName.ps1"
  $scriptBase = ([regex]::Match($PSCommandPath, '(.*[/\\]Scripts)')).Groups[1].Value

  # Search for the script within the base directory, excluding any paths that still include 'Tests'
  $scriptPath = Get-ChildItem -Path $scriptBase -Recurse -Filter $scriptFileName |
    Where-Object { $_.FullName -notmatch 'Tests' } |
    Select-Object -First 1 -ExpandProperty FullName

  if ($scriptPath)
  {
    . $scriptPath
  } else
  {
    Write-Error "Expected script not found for: $scriptFileName"
    Write-Error "Script base: $scriptBase"
  }
}

Describe 'dot Tests' {
  It 'Can call dot' {
    { dot } | Should -Not -Throw
  }

  It 'Can call dot with an argument' {
    { dot @('status') 2> $null } | Should -Not -Throw
  }
}
