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
