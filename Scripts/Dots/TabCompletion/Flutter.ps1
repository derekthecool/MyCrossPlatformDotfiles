<#
Auto-complete help for the flutter CLI


bottom results of this command
flutter pub --help
Available subcommands:
  add         Add a dependency to pubspec.yaml.
  cache       Work with the Pub system cache.
  deps        Print package dependencies.
  downgrade   Downgrade packages in a Flutter project.
  get         Get the current package's dependencies.
  global      Work with Pub global packages.
  login       Log into pub.dev.
  logout      Log out of pub.dev.
  outdated    Analyze dependencies to find which ones can be upgraded.
  pub         Pass the remaining arguments to Dart's "pub" tool.
  publish     Publish the current package to pub.dartlang.org.
  remove      Removes a dependency from the current package.
  run         Run an executable from a package.
  test        Run the "test" package.
  token       Manage authentication tokens for hosted pub repositories.
  upgrade     Upgrade the current package's dependencies to latest versions.
  uploader    Manage uploaders for a package on pub.dev.
  version     Print Pub version.


#>
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    Write-Output "Starting completion script block"
    Write-Output "wordToComplete: $wordToComplete"
    Write-Output "commandAst: $commandAst"
    Write-Output "cursorPosition: $cursorPosition"

    # Generate the completion results
    $completionResults = @()

    # if($commandAst -cmatch 'test')
    if($cursorPosition -eq 8)
    {
        $helpOutput = $(flutter --help)
        Write-Output 'Made it to flutter help'
        [regex]::Matches($helpOutput, '^  [a-z0-9-]+\s+([A-Z]\w+)') | ForEach-Object { $completionResults += $_.Groups[1].Value;Write-Output $_.Groups[1].Value }

        # Write-Output $completionResults
        $completionResults | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

}

Register-ArgumentCompleter -Native -CommandName flutter -ScriptBlock $scriptblock
