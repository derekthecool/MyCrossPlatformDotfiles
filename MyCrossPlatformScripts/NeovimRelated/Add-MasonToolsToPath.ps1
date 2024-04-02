function Add-MasonToolsToPath {
    ## Add all these tools downloaded from neovim plugin Mason
    ## https://github.com/williamboman/mason.nvim
    if($IsWindows) {
        $mason_bin_path = "$env:LOCALAPPDATA/nvim-data/mason/bin"
    } else {
        $mason_bin_path = "$HOME/.local/share/nvim/mason/bin"
    }

    if(Test-Path $mason_bin_path) {
        $env:Path += ";$mason_bin_path"
    }
}
