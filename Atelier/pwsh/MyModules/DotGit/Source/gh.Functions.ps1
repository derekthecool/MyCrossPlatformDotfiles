function Get-GHLastRunLog
{
    $id = $((gh run list --limit 1 --json attempt, conclusion, createdAt, databaseId, displayTitle, event, headBranch, headSha, name, number, startedAt, status, updatedAt, url, workflowDatabaseId, workflowName | ConvertFrom-Json).databaseId)
    gh run view $id --log
}
