BeforeDiscovery {
    # Live tests need the home-lab Kokoro server; they skip themselves everywhere else (CI, other networks).
    $script:kokoroEndpoint = if ($env:KOKORO_ENDPOINT) { $env:KOKORO_ENDPOINT } else { 'http://192.168.1.103:8880' }
    $script:kokoroUp = $false
    try
    {
        $probe = Invoke-WebRequest -Uri "$($script:kokoroEndpoint.TrimEnd('/'))/health" -TimeoutSec 2 -SkipHttpErrorCheck -ErrorAction Stop
        $script:kokoroUp = ($probe.StatusCode -eq 200)
    } catch
    {
        $script:kokoroUp = $false
    }
}

BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
}

Describe 'Kokoro TTS (live server)' -Skip:(-not $script:kokoroUp) {
    It 'exports the generated commands through the manifest alone (lazy-load wiring)' {
        $exported = (Get-Module DotWebApi).ExportedFunctions.Keys
        foreach ($name in 'New-KokoroSpeech', 'Get-KokoroVoice', 'Test-KokoroHealth', 'Get-KokoroModelById', 'New-KokoroDialogue')
        {
            $name | Should -BeIn $exported
        }
    }

    It 'reports the server healthy' {
        (Test-KokoroHealth).status | Should -Be 'healthy'
    }

    It 'lists voices and models' {
        (Get-KokoroVoice).voices.Count | Should -BeGreaterThan 0
        (Get-KokoroModel).data.id | Should -Contain 'kokoro'
        (Get-KokoroModelById -Model kokoro).id | Should -Be 'kokoro'
    }

    It 'reports a missing model with the server message' {
        { Get-KokoroModelById -Model definitely-not-a-model } | Should -Throw '*HTTP 404*not found*'
    }

    It 'synthesises a WAV file from a piped string' {
        $file = Join-Path $TestDrive 'live.wav'
        $result = 'Testing the generated Kokoro client.' | New-KokoroSpeech -ResponseFormat wav -Stream:$false -OutFile $file
        $result | Should -BeOfType [System.IO.FileInfo]
        $result.Length | Should -BeGreaterThan 1000
        [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($file)[0..3]) | Should -Be 'RIFF'
        $result.ResponseHeaders['Content-Type'] | Should -BeLike 'audio/*'
    }

    It 'applies speed and normalisation options' {
        $file = Join-Path $TestDrive 'norm.mp3'
        $options = New-KokoroNormalizationOption -UnitNormalization
        $result = New-KokoroSpeech -InputText 'It is 10KB.' -Speed 1.2 -NormalizationOptions $options -ResponseFormat mp3 -OutFile $file
        $result.Length | Should -BeGreaterThan 500
    }

    It 'synthesises a dialogue from constructed turns' {
        $turns = (New-KokoroDialogueTurn -Voice af_bella -Text 'Hello.'), (New-KokoroDialogueTurn -Voice am_adam -Text 'Hi there.')
        $result = New-KokoroDialogue -Turns $turns -PauseBetweenTurns 0.2 -ResponseFormat wav -Stream:$false -OutFile (Join-Path $TestDrive 'dialogue.wav')
        $result.Length | Should -BeGreaterThan 1000
    }

    It 'rejects bad arguments client-side' {
        { New-KokoroSpeech -InputText x -Speed 99 } | Should -Throw '*maximum*'
    }
}
