function Get-YouTubeVideosFromSearch
{
    # Define the search query
    $searchQuery = "death core Jacob Lizzotte"

    # Encode the query for use in the URL
    $encodedQuery = [System.Web.HttpUtility]::UrlEncode($searchQuery)

    # Construct the YouTube search URL
    $searchUrl = "https://www.youtube.com/results?search_query=$encodedQuery"

    # Send the HTTP request to get the search results page
    $response = Invoke-WebRequest -Uri $searchUrl
    # $response
    $response | Get-Member
    $response
    Write-Host "---"
    $response.Content | Select-String 'TtZETmRja78'

    # Convert the response to a string
    $htmlContent = $response.OuterXml

    # Use a regex to extract video IDs and titles from the HTML content
    $videoPattern = '<a href="/watch\?v=(.{11})".*?title="([^"]+)"'

    # Match the pattern against the HTML content
    $matches = [regex]::Matches($htmlContent, $videoPattern)

    # Display the search results
    foreach ($match in $matches)
    {
        $videoId = $match.Groups[1].Value
        $title = $match.Groups[2].Value
        $videoUrl = "https://www.youtube.com/watch?v=$videoId"
        Write-Output "Title: $title"
        Write-Output "URL: $videoUrl"
        Write-Output ""
    }
}

# Recursive function to iterate over child nodes
function Iterate-ChildNodes
{
    param (
        [HtmlAgilityPack.HtmlNode]$node
    )

    # Output the current node's name and value
    if($node.InnerText.Contains('TtZETmRja78'))
    {
        Write-Output "The node $($node.Name) contains a match"

        # ConvertFrom-Text '\/TtZETmRja78\/'
        $node.InnerText | ConvertFrom-Text '\/(?<Link>[A-Za-z0-9]{11})\/'
    }

    Write-Output "Node Name: $($node.Name)"
    Write-Output "Node Value: $($node.InnerText)"

    # Check if the node has child nodes
    if ($node.HasChildNodes)
    {
        Write-Output "Node has child nodes."

        # Iterate over each child node
        foreach ($childNode in $node.ChildNodes)
        {
            Iterate-ChildNodes -node $childNode
        }
    } else
    {
        Write-Output "Node does not have child nodes."
    }
}
