function Get-ContainerRunner
{
    if($Global:ContainerRunner)
    {
        return $Global:ContainerRunner
    }

    if(Get-Command -Name podman -ErrorAction SilentlyContinue)
    {
        $Global:ContainerRunner = 'podman'
        return 'podman'
    } elseif(Get-Command -Name podman -ErrorAction SilentlyContinue)
    {
        $Global:ContainerRunner = 'docker'
        return 'docker'
    } else
    {
        throw "No container runner application found, install podman or docker"
    }
}

Set-Alias -Name 'c' -Value Use-Container
Set-Alias -Name 'container' -Value Use-Container
function Use-Container
{
    Write-Host "Use-Container args: $args"
    & $(Get-ContainerRunner) @args
}

Set-Alias -Name 'mmdc' -Value Use-MermaidCli
function Use-MermaidCli
{
    $DiagramPath = $PWD
    Use-Container run --rm -it -v "${DiagramPath}:/data:z" ghcr.io/mermaid-js/mermaid-cli/mermaid-cli @args
}
