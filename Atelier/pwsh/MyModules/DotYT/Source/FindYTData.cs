// Search functionality made possible by nuget library: https://github.com/madeyoga/YoutubeSearchApi.Net
using YoutubeSearchApi.Net.Models.Youtube;
using YoutubeSearchApi.Net.Services;

namespace DotYT;

[Cmdlet("Find", "YTData")]
[OutputType(typeof(YoutubeVideo))]
public class FindYTData : PSCmdlet
{
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true
    )]
    public string SearchQuery { get; set; }

    // This method gets called once for each cmdlet in the pipeline when the pipeline starts executing
    protected override void BeginProcessing()
    {
        WriteVerbose("Begin!");
    }

    // This method will be called for each input received from the pipeline to this cmdlet; if no input is received, this method is not called
    protected override void ProcessRecord()
    {
        new YoutubeSearchClient(new HttpClient())
            .SearchAsync(SearchQuery)
            .GetAwaiter()
            .GetResult()
            .Results.ToList()
            .ForEach(WriteObject);
    }

    // This method will be called once at the end of pipeline execution; if no input is received, this method is not called
    protected override void EndProcessing()
    {
        WriteVerbose("End!");
    }
}
