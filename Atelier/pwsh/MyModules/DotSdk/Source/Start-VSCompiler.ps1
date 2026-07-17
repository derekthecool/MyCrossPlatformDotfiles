# Hack for running visual Studio for dotnet framework projects with terminal only
# https://intellitect.com/blog/enter-vsdevshell-powershell/
# The better method is to update your project and use dotnet cli
if ($IsWindows)
{
    function Start-VSCompiler
    {
        # First way I found. This way sources a dll then needs a unique GUID from your visual Studio
        # C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -noe -c "&{Import-Module 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'; Enter-VsDevShell 0e7efad8}"

        # This way is better since you just have to run a powershell script
        # Using the -SkipAutomaticLocation keeps you in your current directory instead of changing
        & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation
        Write-Host 'Commands to run to build dotnet framework project'
        Write-Host 'nuget restore'
        Write-Host 'msbuild -p:Configuration=Release # or Debug'
        Write-Host 'msbuild -t:restore # maybe'
    }
}
