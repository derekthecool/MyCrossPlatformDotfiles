namespace FT

open System.Management.Automation

// Define the FavoriteStuff class
type FavoriteStuff() =
    member val FavoriteNumber = 0 with get, set
    member val FavoritePet = "" with get, set

// Define the cmdlet class
[<Cmdlet("þverbþ", "þnounþ")>]
[<OutputType(typeof<FavoriteStuff>)>]
type TestFsharpSampleCmdletCommand() =
    inherit PSCmdlet()

    // Define the parameters
    [<Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true)>]
    member val FavoriteNumber = 0 with get, set

    [<Parameter(Position = 1, ValueFromPipelineByPropertyName = true)>]
    [<ValidateSet("Cat", "Dog", "Horse")>]
    member val FavoritePet = "Dog" with get, set

    // This method gets called once for each cmdlet in the pipeline when the pipeline starts executing
    override this.BeginProcessing() =
        this.WriteVerbose("Begin!")

    // This method will be called for each input received from the pipeline to this cmdlet
    // If no input is received, this method is not called
    override this.ProcessRecord() =
        this.WriteObject(FavoriteStuff(FavoriteNumber = this.FavoriteNumber, FavoritePet = this.FavoritePet))

    // This method will be called once at the end of pipeline execution; if no input is received, this method is not called
    override this.EndProcessing() =
        this.WriteVerbose("End!")
