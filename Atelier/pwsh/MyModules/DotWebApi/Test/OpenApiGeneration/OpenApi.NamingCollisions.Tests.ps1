BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
}

Describe 'Resolve-OpenApiFunctionName when two operations want the same name' {
    BeforeAll {
        function Resolve-Names
        {
            param([object[]]$Operation)
            $named = InModuleScope DotWebApi -Parameters @{ Operation = $Operation } { Resolve-OpenApiFunctionName -Operation $Operation -Prefix 'Demo' }
            $named | ForEach-Object { $_.Name }
        }
        function New-Op
        {
            param([string]$Method, [string]$Path, [string]$Summary)
            [pscustomobject]@{ Method = $Method; Path = $Path; Summary = $Summary; OperationId = $null }
        }
    }

    It 'gives the plain name to the shorter path and the words the path adds to the other' {
        $names = Resolve-Names @(
            (New-Op GET '/event_ids' 'Get events by ids')
            (New-Op GET '/events' 'Get events')
        )
        $names | Should -Be @('Get-DemoEventIds', 'Get-DemoEvent')
    }

    It 'tells apart two operations that differ only in their trailing words' {
        $names = Resolve-Names @(
            (New-Op POST '/replay/start_from_export' 'Start replay')
            (New-Op POST '/replay/start' 'Start replay')
        )
        $names | Should -Be @('Start-DemoReplayFromExport', 'Start-DemoReplay')
    }

    It 'uses the file extension to separate two formats of the same resource' {
        $names = Resolve-Names @(
            (New-Op GET '/preview/{name}/thumbnail.webp' 'Preview Thumbnail')
            (New-Op GET '/preview/{name}/thumbnail.jpg' 'Preview Thumbnail')
        )
        $names | Should -Be @('Get-DemoPreviewThumbnailWebp', 'Get-DemoPreviewThumbnail')
    }

    It 'names the per-key variant By<Key> when the path starts with a parameter' {
        $names = Resolve-Names @(
            (New-Op GET '/{camera_name}/recordings/summary' 'Recordings Summary')
            (New-Op GET '/recordings/summary' 'All Recordings Summary')
        )
        $names | Should -Be @('Get-DemoRecordingsSummaryByCameraName', 'Get-DemoRecordingsSummary')
    }

    It 'only falls back to the HTTP method name when the path has nothing to add' {
        $names = Resolve-Names @(
            (New-Op GET '/things' 'Get things')
            (New-Op POST '/things/' 'Get things')
        )
        $names[0] | Should -Be 'Get-DemoThing'
        $names[1] | Should -Match '^Get-DemoThing(Post|2)$'
    }

    It 'keeps ById for a lookup by key' {
        $names = Resolve-Names @(
            (New-Op GET '/gadgets/{gadget_id}' 'Get gadget')
            (New-Op GET '/gadgets' 'Get gadgets')
        )
        $names | Should -Be @('Get-DemoGadgetById', 'Get-DemoGadget')
    }
}

Describe 'Get-OpenApiPathSuffix' {
    It 'returns the path words the noun does not already say' -ForEach @(
        @{ Path = '/preview/{file_name}/thumbnail.webp'; Noun = 'PreviewThumbnail'; Expected = 'Webp' }
        @{ Path = '/debug_replay/start_from_export'; Noun = 'DebugReplay'; Expected = 'FromExport' }
        @{ Path = '/v1/events'; Noun = 'Event'; Expected = '' }
        @{ Path = '/events/{id}/thumbnail.{extension}'; Noun = 'EventThumbnail'; Expected = '' }
    ) {
        InModuleScope DotWebApi -Parameters @{ Path = $Path; Noun = $Noun; Expected = $Expected } {
            Get-OpenApiPathSuffix -Path $Path -Noun $Noun | Should -Be $Expected
        }
    }
}

Describe 'Get-OpenApiVerbNoun' {
    It 'does not repeat the verb in the noun' -ForEach @(
        @{ Method = 'POST'; Path = '/users'; Summary = 'Create new user'; Expected = 'New/User' }
        @{ Method = 'POST'; Path = '/restart'; Summary = 'Restart'; Expected = 'Restart/' }
        @{ Method = 'GET'; Path = '/stats'; Summary = 'Stats'; Expected = 'Get/Stats' }
    ) {
        $parts = InModuleScope DotWebApi -Parameters @{ Method = $Method; Path = $Path; Summary = $Summary } {
            Get-OpenApiVerbNoun -Path $Path -Method $Method -Summary $Summary
        }
        "$($parts.Verb)/$($parts.Noun)" | Should -Be $Expected
    }
}
