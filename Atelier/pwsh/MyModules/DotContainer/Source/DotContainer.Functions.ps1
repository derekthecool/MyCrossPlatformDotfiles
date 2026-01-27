function Get-ContainerRunner
{
    if ($Global:ContainerRunner)
    {
        return $Global:ContainerRunner
    }

    if (Get-Command -Name podman -ErrorAction SilentlyContinue)
    {
        $Global:ContainerRunner = 'podman'
        return 'podman'
    } elseif (Get-Command -Name podman -ErrorAction SilentlyContinue)
    {
        $Global:ContainerRunner = 'docker'
        return 'docker'
    } else
    {
        throw "No container runner application found, install podman or docker"
    }
}

function Use-Container
{
    Write-Host "Use-Container args: $args"
    & $(Get-ContainerRunner) @args
}
Set-Alias -Name 'c' -Value Use-Container -Force
Set-Alias -Name 'container' -Value Use-Container -Force

function Get-ComposeContainerRunner
{
    if ($Global:ComposeContainerRunner)
    {
        return $Global:ComposeContainerRunner
    }

    # TODO: (Derek Lomax) 3/6/2025 3:40:03 PM, add better support for podman compose and docker compose without the '-'
    if (Get-Command -Name 'podman-compose' -ErrorAction SilentlyContinue)
    {
        $Global:ComposeContainerRunner = 'podman-compose'
        return $Global:ComposeContainerRunner
    } elseif (Get-Command -Name 'docker-compose' -ErrorAction SilentlyContinue)
    {
        $Global:ComposeContainerRunner = 'docker-compose'
        return $Global:ComposeContainerRunner
    } else
    {
        throw "No compose container runner application found, install podman-compose or docker-compose or docker with compose plugin"
    }
}

function Use-ComposeContainer
{
    Write-Host "Use-ComposeContainer args: $args"
    & $(Get-ComposeContainerRunner) @args
}
Set-Alias -Name 'compose' -Value Use-ComposeContainer -Force

Set-Alias -Name 'mmdc' -Value Use-MermaidCli -Force
function Use-MermaidCli
{
    $DiagramPath = $PWD
    Use-Container run --rm -it -v "${DiagramPath}:/data:z" ghcr.io/mermaid-js/mermaid-cli/mermaid-cli @args
}

function Use-PandocLatexMdToPdf
{
    param (
        [Parameter()]
        [string]$InputMarkdown,
        [string]$OutputPDF,
        [string[]]$AdditionalContainerArgs,
        [string[]]$AdditionalPandocArgs
    )

    Use-Container run --rm `
        -v .:/data `
        -w /data `
        "$AdditionalContainerArgs" `
        rstropek/pandoc-latex `
        -f markdown `
        --template https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/v2.4.0/eisvogel.tex `
        -t latex `
        -o $OutputPDF `
        "$AdditionalPandocArgs" `
        $InputMarkdown
}

function Use-YTDLP
{
    $containerName = "ghcr.io/jauderho/yt-dlp:latest"

    Use-Container run --rm `
        -v $HOME/yt-dlp.conf:/root/yt-dlp.conf `
        -v $HOME/YouTube:/root/YouTube `
        $containerName `
        @args
}
