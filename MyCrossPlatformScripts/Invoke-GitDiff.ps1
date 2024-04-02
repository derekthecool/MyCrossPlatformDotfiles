function Invoke-GitDiff {
    git diff --no-index --color-words $args
}
