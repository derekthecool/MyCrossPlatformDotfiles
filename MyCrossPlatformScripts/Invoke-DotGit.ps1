# Function to using my git bare repo for my windows config files
function dot {
    # Create a copy of the arguments array to manipulate
    $arguments = $args

    # Check if the first argument is 'git' and remove it if so
    # This will help steno speed greatly. Now I can just run commands like 'dot git status --short'
    # And it'll work
    if ($arguments.Length -gt 0 -and $arguments[0] -eq 'git') {
        $arguments = $arguments[1..($arguments.Length - 1)]
    }

    # Run git command with modified arguments
    git --git-dir="$HOME/.cfg" --work-tree="$HOME" @arguments
}

# Helpful alias for typos like: dotgit status
New-Alias -Name dotgit -Value dot -ErrorAction SilentlyContinue
