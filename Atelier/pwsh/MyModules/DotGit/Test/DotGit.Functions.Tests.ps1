BeforeAll {
    $module = Import-Module $PSScriptRoot/../*.psd1 -Force -PassThru
}

Describe 'DotGit tests' {
    It 'Function Switch-GitWorktree works' {
        $module.ExportedFunctions['Get-GitWorktree'] | Should -Be -Not $null
    }
}

Describe 'Get-LatestGithubRelease' {
    BeforeEach {
        # Use a well-known repository that should have releases
        $testRepo = 'opensteno/plover'
    }

    It 'Returns a PSCustomObject with expected properties' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.TypeNames[0] | Should -Be 'System.Management.Automation.PSCustomObject'
    }

    It 'Returns TagName property with version format' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.TagName | Should -Not -BeNullOrEmpty
        $result.TagName | Should -Match '^v?\d+\.\d+\.\d+'
    }

    It 'Returns Assets array with metadata' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.Assets | Should -Not -BeNullOrEmpty
        $result.Assets.Count | Should -BeGreaterThan 0

        $firstAsset = $result.Assets[0]
        $firstAsset.Name | Should -Not -BeNullOrEmpty
        $firstAsset.BrowserDownloadUrl | Should -Not -BeNullOrEmpty
        $firstAsset.BrowserDownloadUrl | Should -Match '^https://'
        $firstAsset.Size | Should -BeGreaterThan 0
    }

    It 'Maintains backward compatibility with DownloadUrls property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.DownloadUrls | Should -Not -BeNullOrEmpty
        $result.DownloadUrls.GetType().Name | Should -Be 'Object[]'
        $result.DownloadUrls[0] | Should -Match '^https://'
    }

    It 'Returns HtmlUrl property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.HtmlUrl | Should -Not -BeNullOrEmpty
        $result.HtmlUrl | Should -Match '^https://github\.com/'
    }

    It 'Returns PublishedAt property' -Skip:(-not (Test-Connection github.com -Quiet -Count 1)) {
        $result = Get-LatestGithubRelease -Repo $testRepo

        $result.PublishedAt | Should -Not -BeNullOrEmpty
        $result.PublishedAt | Should -BeOfType System.DateTime
    }

    It 'Validates Repo parameter format' {
        # Invalid patterns should throw during parameter validation
        { Get-LatestGithubRelease -Repo 'invalid-format' } | Should -Throw -ErrorId '*ParameterArgumentValidationError*'
        { Get-LatestGithubRelease -Repo 'singleword' } | Should -Throw -ErrorId '*ParameterArgumentValidationError*'

        # Valid pattern should be accepted by parameter validator (will get 404 from API)
        { Get-LatestGithubRelease -Repo 'this/repo-does-not-exist-12345' } | Should -Throw -ErrorId '*WebCmdletWebResponseException*'
    }
}
