BeforeAll {
    # This test lives IN the beets config dir; repo root is two levels up.
    # (Repo root == $HOME on real machines, == checkout root in CI.)
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ConfigYaml = Join-Path $PSScriptRoot 'config.yaml'
    $script:DockerfilePath = Join-Path $PSScriptRoot 'Dockerfile'
    $script:WrapperPath = Join-Path $PSScriptRoot 'Invoke-Beets.ps1'
    $script:ShimPath = Join-Path $RepoRoot 'AppData/Roaming/beets/config.yaml'
    $script:GitignorePath = Join-Path $RepoRoot '.gitignore'
    . $script:WrapperPath
}

Describe 'Beets config.yaml tests' {
    It 'Config file exists' { $script:ConfigYaml | Should -Exist }

    It 'Library database resolves inside /config' {
        (Get-Content $script:ConfigYaml -Raw) | Should -Match '(?m)^library:\s*library\.db\s*$'
    }

    It 'Destination directory is the container path /music' {
        (Get-Content $script:ConfigYaml -Raw) | Should -Match '(?m)^directory:\s*/music\s*$'
    }

    It 'Music Assistant contract keys are set (id3v23, art_filename)' {
        $yaml = Get-Content $script:ConfigYaml -Raw
        $yaml | Should -Match '(?m)^\s*id3v23:\s*yes'
        $yaml | Should -Match '(?m)^art_filename:\s*cover'
    }

    It 'Import copies, skips weak matches, and logs for review' {
        $yaml = Get-Content $script:ConfigYaml -Raw
        $yaml | Should -Match '(?m)^\s*copy:\s*yes'
        $yaml | Should -Match '(?m)^\s*quiet_fallback:\s*skip'
        $yaml | Should -Match '(?m)^\s*incremental:\s*yes'
        $yaml | Should -Match '(?m)^\s*incremental_skip_later:\s*yes'
        $yaml | Should -Match '(?m)^\s*duplicate_action:\s*skip'
        $yaml | Should -Match '(?m)^\s*log:\s*/config/import\.log'
    }

    It 'Quiet is left off so review imports can be interactive (no --noquiet flag exists)' {
        (Get-Content $script:ConfigYaml -Raw) | Should -Not -Match '(?m)^\s*quiet:\s*yes'
    }

    It 'Plugin list keeps musicbrainz and chroma and stays web-free' {
        $pluginsLine = (Get-Content $script:ConfigYaml -Raw) -split "`n" | Where-Object { $_ -match '^plugins:' }
        $pluginsLine | Should -Not -BeNullOrEmpty
        $pluginsLine | Should -Match 'musicbrainz'
        $pluginsLine | Should -Match 'chroma'
        $pluginsLine | Should -Match 'fetchart'
        $pluginsLine | Should -Match 'embedart'
        $pluginsLine | Should -Match 'scrub'
        $pluginsLine | Should -Match 'replaygain'
        $pluginsLine | Should -Not -Match '\bweb\b'
    }

    It 'Slow network plugins are deferred to post-import commands' {
        $yaml = Get-Content $script:ConfigYaml -Raw
        $yaml | Should -Match '(?ms)^replaygain:.*?^\s*auto:\s*no'
        $yaml | Should -Match '(?ms)^lastgenre:.*?^\s*auto:\s*no'
        $yaml | Should -Match '(?ms)^lyrics:.*?^\s*auto:\s*no'
    }

    It 'Replaygain uses the ffmpeg backend' {
        (Get-Content $script:ConfigYaml -Raw) | Should -Match '(?m)^\s*backend:\s*ffmpeg'
    }
}

Describe 'Beets Dockerfile tests' {
    It 'Dockerfile exists' { $script:DockerfilePath | Should -Exist }

    It 'Pins beets 2.13.1 on python 3.13 slim' {
        $dockerfile = Get-Content $script:DockerfilePath -Raw
        $dockerfile | Should -Match 'FROM\s+python:3\.13-slim'
        $dockerfile | Should -Match 'BEETS_VERSION=2\.13\.1'
        $dockerfile | Should -Match 'beets\[fetchart,embedart,lyrics,lastgenre,chroma,scrub\]==\$\{BEETS_VERSION\}'
    }

    It 'Installs fpcalc via libchromaprint-tools and ffmpeg' {
        $dockerfile = Get-Content $script:DockerfilePath -Raw
        $dockerfile | Should -Match 'libchromaprint-tools'
        $dockerfile | Should -Match 'ffmpeg'
    }

    It 'Runs as non-root with BEETSDIR=/config' {
        $dockerfile = Get-Content $script:DockerfilePath -Raw
        $dockerfile | Should -Match 'BEETSDIR=/config'
        $dockerfile | Should -Match '(?m)^USER beets'
    }
}

Describe 'Invoke-Beets wrapper tests' {
    It 'Dot-sources and defines the Invoke-Beets function' {
        Get-Command Invoke-Beets -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'Uses the same image tag the Dockerfile version implies' {
        (Get-Content $script:WrapperPath -Raw) | Should -Match 'beets-derek:2\.13\.1'
    }

    It 'Gates -t on a real TTY' {
        (Get-Content $script:WrapperPath -Raw) | Should -Match 'IsOutputRedirected'
    }

    It 'Mounts the source read-only and uses --rm' {
        $wrapper = Get-Content $script:WrapperPath -Raw
        $wrapper | Should -Match 'modify_source:/import:ro'
        $wrapper | Should -Match '--rm'
    }
}

Describe 'Windows beets shim tests' {
    It 'Shim file exists' { $script:ShimPath | Should -Exist }

    It 'Shim includes the cross-platform config via a YAML list' {
        $shim = Get-Content $script:ShimPath -Raw
        $shim | Should -Match '(?m)^include:\s*\['
        $shim | Should -Match '\.config/beets/config\.yaml'
    }
}

Describe 'Beets mount safety tests' {
    It 'Wrapper never mounts the pristine ~/Music/original backup' {
        # The header comment explicitly documents that original is NOT mounted;
        # effective (non-comment) lines must contain no reference to it.
        $effectiveLines = Get-Content $script:WrapperPath | Where-Object { $_ -notmatch '^\s*#' }
        $effectiveLines | Should -Not -Match 'original'
    }

    It 'Config never references the host source path' {
        # Header comments document the mount layout (which legitimately names
        # the source); effective config lines must not point at it.
        $effectiveLines = Get-Content $script:ConfigYaml | Where-Object { $_ -notmatch '^\s*#' }
        $effectiveLines | Should -Not -Match 'modify_source'
    }

    It 'Gitignore excludes generated beets state (db, log, statefile)' {
        $gitignore = Get-Content $script:GitignorePath -Raw
        $gitignore | Should -Match '\.config/beets/library\.db'
        $gitignore | Should -Match '\.config/beets/import\.log'
        $gitignore | Should -Match '\.config/beets/state\.pickle'
    }
}
