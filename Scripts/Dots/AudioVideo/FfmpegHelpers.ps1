function ffmpeg-ReduceVideoSize
{
    param (
        [Parameter(Mandatory)]
        [string]$InputVideo,

        [Parameter(Mandatory)]
        [string]$OutputVideo
    )

    ffmpeg -i $InputVideo -vf "scale=640:-1" -b:v 800k -c:a copy $OutputVideo
}
