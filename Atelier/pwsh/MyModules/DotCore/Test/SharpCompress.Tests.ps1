BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1
    $Temp = [IO.Path]::GetTempPath()
}

Describe 'Open all archive types' {
    It 'Checks to see if <ArchiveName> can be extracted and the file <Filename> has expected contents' -TestCases @(
        @{
            # Acquired with this command
            # tar czvf test.tar.gz test.txt
            Base64FileContent        = 'H4sIACdyemkAAytJLS7RK6koYaAhMDAwMDMzUwDRQIBOGxgYGhgrGJoaGpuZmBsaGJkoAAXMTUwZFAxo6SgYKC0uSSwCOoVSc9A9N0RASEZmsUJiUXJGZlmqQkllQaoCkF9cWlCQX1SSmqJQkp+vkIgX8HINtBdGwSgYBaNgFJABAP1m/PoACAAA'
            ArchiveName              = 'test.tar.gz'
            Filename                 = 'test.txt'
            ExpectedFilenameContents = 'This archive type is supported too aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        },
        @{
            # Acquired with this command
            # Get-ChildItem test.txt | Compress-Archive -DestinationPath test.zip
            Base64FileContent        = 'UEsDBBQAAAAIAOhrPFyGsGyBKQAAAEMAAAAIAAAAdGVzdC50eHQLycgsVkgsSs7ILEtVKKksSFXILFYoLi0oyC8qSU1RKMnPV0jEC3i5AFBLAQIUABQAAAAIAOhrPFyGsGyBKQAAAEMAAAAIAAAAAAAAAAAAAAAAAAAAAAB0ZXN0LnR4dFBLBQYAAAAAAQABADYAAABPAAAAAAA='
            ArchiveName              = 'test.zip'
            Filename                 = 'test.txt'
            ExpectedFilenameContents = 'This archive type is supported too aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        }
    ) {
        $archiveFullPath = [IO.Path]::Join($Temp, $ArchiveName)
        $archiveBytes = [convert]::FromBase64String($Base64FileContent)
        [IO.File]::WriteAllBytes($archiveFullPath, $archiveBytes)
        Get-ChildItem $Temp/$ArchiveName | Expand-Everything -Destination $Temp

        $extractedFullPath = [IO.Path]::Join($Temp, $Filename)
        Test-Path $extractedFullPath | Should -BeTrue
        Get-Content $extractedFullPath | Should -BeExactly $ExpectedFilenameContents

        Remove-Item $archiveFullPath, $extractedFullPath
    }
}
