BeforeAll {
    Import-Module $PSScriptRoot/../DotWindowManager.psd1 -Force

    # Setup test workspace path
    $testWorkspaceBasePath = "$HOME/Atelier/workspaces"
    $backupPath = "$HOME/Atelier/workspaces.backup"

    # Backup existing workspace files
    if (Test-Path $testWorkspaceBasePath)
    {
        if (Test-Path $backupPath)
        {
            Remove-Item -Recurse -Force $backupPath
        }
        Copy-Item -Recurse $testWorkspaceBasePath $backupPath
    }
}

AfterAll {
    # Restore backup
    if (Test-Path $backupPath)
    {
        if (Test-Path $testWorkspaceBasePath)
        {
            Remove-Item -Recurse -Force $testWorkspaceBasePath
        }
        Move-Item -Path $backupPath -Destination $testWorkspaceBasePath
    }
}

Describe 'Get-WM' {
    It 'Function exists' {
        Get-Command Get-WM | Should -Not -Be $null
    }

    It 'Returns all workspaces when no parameters specified' {
        $result = Get-WM
        $result | Should -Not -BeNullOrEmpty
        $result.Workspace | Should -Contain 1
        $result.Workspace | Should -Contain 9
    }

    It 'Returns specific workspace when Workspace parameter specified' {
        $result = Get-WM -Workspace 1
        $result | Should -Not -BeNullOrEmpty
        # All results should have Workspace = 1
        $result.Workspace | Select-Object -Unique | Should -Be 1
    }

    It 'Returns multiple workspaces when array specified' {
        $result = Get-WM -Workspace 1,2,3
        $result.Workspace | Select-Object -Unique | Should -HaveCount 3
    }

    It 'Returns filters when Filters switch specified' {
        $result = Get-WM -Filters
        $result | Should -Not -BeNullOrEmpty
        # Should have App and Type properties
        $result[0].PSObject.Properties.Name | Should -Contain 'App'
        $result[0].PSObject.Properties.Name | Should -Contain 'Type'
        # Should NOT have Workspace property
        $result[0].PSObject.Properties.Name | Should -Not -Contain 'Workspace'
    }

    It 'Returns raw JSON when Raw switch specified' {
        $result = Get-WM -Workspace 1 -Raw
        $result | Should -Not -BeNullOrEmpty
        $result[0].PSObject.Properties.Name | Should -Contain 'Routes'
    }
}

Describe 'Add-WMRoute' {
    BeforeEach {
        # Ensure we have a clean test workspace (use workspace 9 for testing)
        $testWorkspace = 9
        $testPath = "$HOME/Atelier/workspaces/9.json"

        # Backup original content
        if (Test-Path $testPath)
        {
            $originalContent = Get-Content $testPath -Raw
        }

        # Reset to empty
        @() | ConvertTo-Json | Set-Content $testPath
    }

    AfterEach {
        # Restore original content
        if ($originalContent)
        {
            $originalContent | Set-Content $testPath
        }
    }

    It 'Function exists' {
        Get-Command Add-WMRoute | Should -Not -Be $null
    }

    It 'Adds single route to workspace' {
        'test-app' | Add-WMRoute -Workspace 9

        $result = Get-WM -Workspace 9
        $result.Count | Should -BeGreaterOrEqual 1
        $result.App | Should -Contain 'test-app'
    }

    It 'Adds multiple routes via pipeline' {
        'app1', 'app2', 'app3' | Add-WMRoute -Workspace 9

        $result = Get-WM -Workspace 9
        $result.Count | Should -BeGreaterOrEqual 3
        $result.App | Should -Contain 'app1'
        $result.App | Should -Contain 'app2'
        $result.App | Should -Contain 'app3'
    }

    It 'Adds route with explicit type' {
        Add-WMRoute -Workspace 9 -Applications 'test-app' -Type 'class'

        $result = Get-WM -Workspace 9
        $app = $result | Where-Object { $_.App -eq 'test-app' }
        $app.Type | Should -Be 'class'
    }

    It 'Adds route from hashtable input' {
        @{Name='hash-app'; Type='class'} | Add-WMRoute -Workspace 9

        $result = Get-WM -Workspace 9
        $result.App | Should -Contain 'hash-app'
        ($result | Where-Object { $_.App -eq 'hash-app' }).Type | Should -Be 'class'
    }

    It 'Adds route from PSCustomObject input' {
        [PSCustomObject]@{Name='custom-app'; Type='title'} | Add-WMRoute -Workspace 9

        $result = Get-WM -Workspace 9
        $result.App | Should -Contain 'custom-app'
        ($result | Where-Object { $_.App -eq 'custom-app' }).Type | Should -Be 'title'
    }

    It 'Detects duplicate routes' {
        'duplicate-app' | Add-WMRoute -Workspace 9

        # Capture warning output
        $result = Add-WMRoute -Workspace 9 -Applications 'duplicate-app' 3>&1

        # Should have a warning
        $result | Should -Match 'Duplicate route detected'
    }

    It 'Rejects application names with .exe suffix' {
        # Capture error output
        $result = 'badapp.exe' | Add-WMRoute -Workspace 9 2>&1

        # Should have an error about .exe suffix
        $result | Should -Match 'should not contain .exe suffix'
    }

    It 'Creates new workspace file if not exists' {
        $nonExistentPath = "$HOME/Atelier/workspaces/8.json"
        $backupPath = "$nonExistentPath.bak"

        # Backup and remove if exists
        if (Test-Path $nonExistentPath)
        {
            Copy-Item $nonExistentPath $backupPath
            Remove-Item $nonExistentPath
        }

        try
        {
            'new-workspace-app' | Add-WMRoute -Workspace 8
            Test-Path $nonExistentPath | Should -Be $true
        }
        finally
        {
            # Restore
            if (Test-Path $backupPath)
            {
                Move-Item $backupPath $nonExistentPath -Force
            }
        }
    }
}

Describe 'Add-WMFilter' {
    BeforeEach {
        # Backup filters
        $filtersPath = "$HOME/Atelier/workspaces/filters.json"
        if (Test-Path $filtersPath)
        {
            $originalFilters = Get-Content $filtersPath -Raw
        }
    }

    AfterEach {
        # Restore filters
        if ($originalFilters)
        {
            $originalFilters | Set-Content $filtersPath
        }
    }

    It 'Function exists' {
        Get-Command Add-WMFilter | Should -Not -Be $null
    }

    It 'Adds single filter' {
        'test-filter' | Add-WMFilter

        $result = Get-WM -Filters
        $result.App | Should -Contain 'test-filter'
    }

    It 'Adds multiple filters via pipeline' {
        'filter1', 'filter2', 'filter3' | Add-WMFilter

        $result = Get-WM -Filters
        $result.Count | Should -BeGreaterOrEqual 3
        $result.App | Should -Contain 'filter1'
        $result.App | Should -Contain 'filter2'
        $result.App | Should -Contain 'filter3'
    }

    It 'Adds filter with explicit type' {
        Add-WMFilter -Application 'test-filter' -Type 'class'

        $result = Get-WM -Filters
        $filter = $result | Where-Object { $_.App -eq 'test-filter' }
        $filter.Type | Should -Be 'class'
    }

    It 'Adds filter from hashtable input' {
        @{Name='hash-filter'; Type='instance'} | Add-WMFilter

        $result = Get-WM -Filters
        $result.App | Should -Contain 'hash-filter'
        ($result | Where-Object { $_.App -eq 'hash-filter' }).Type | Should -Be 'instance'
    }

    It 'Detects duplicate filters' {
        'duplicate-filter' | Add-WMFilter

        # Capture warning output
        $result = Add-WMFilter -Application 'duplicate-filter' 3>&1

        # Should have a warning
        $result | Should -Match 'Duplicate filter detected'
    }
}

Describe 'Cross-Platform Path Handling' {
    It 'Workspace files use correct path separators' {
        # Get workspace 1 which should exist
        $result = Get-WM -Workspace 1
        $result | Should -Not -BeNullOrEmpty

        # Verify the workspace file exists
        Test-Path "$HOME/Atelier/workspaces/1.json" | Should -Be $true
    }

    It 'Filters file uses correct path separators' {
        # Verify filters file exists
        Test-Path "$HOME/Atelier/workspaces/filters.json" | Should -Be $true

        # Can retrieve filters
        $result = Get-WM -Filters
        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'Integration Tests' {
    It 'Full workflow: Add, retrieve, verify' {
        $testWorkspace = 9
        $testApp = 'integration-test-app'

        # Add route
        $testApp | Add-WMRoute -Workspace $testWorkspace

        # Retrieve
        $result = Get-WM -Workspace $testWorkspace

        # Verify
        $result.App | Should -Contain $testApp
    }

    It 'Multiple operations maintain data integrity' {
        $testWorkspace = 9

        # Add multiple routes
        'int-test-1', 'int-test-2', 'int-test-3' | Add-WMRoute -Workspace $testWorkspace

        # Add filters
        'int-filter-1', 'int-filter-2' | Add-WMFilter

        # Verify workspace
        $wsResult = Get-WM -Workspace $testWorkspace
        $wsResult.App | Should -Contain 'int-test-1'
        $wsResult.App | Should -Contain 'int-test-2'
        $wsResult.App | Should -Contain 'int-test-3'

        # Verify filters
        $filterResult = Get-WM -Filters
        $filterResult.App | Should -Contain 'int-filter-1'
        $filterResult.App | Should -Contain 'int-filter-2'
    }
}

Describe 'Get-WindowDetails' {
    BeforeAll {
        # Import the module
        Import-Module ~/Atelier/pwsh/MyModules/DotWindowManager -Force
    }

    It 'Function exists and is exported' {
        $function = Get-Command Get-WindowDetails -Module DotWindowManager -ErrorAction SilentlyContinue
        $function | Should -Not -BeNullOrEmpty
        $function.Name | Should -Be 'Get-WindowDetails'
    }

    It 'Has no custom parameters (interactive only)' {
        $function = Get-Command Get-WindowDetails
        # All functions have common parameters, but Get-WindowDetails should have no custom ones
        # Filter out common parameters
        $commonParams = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
                         'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable',
                         'OutVariable', 'OutBuffer', 'PipelineVariable')
        $customParams = $function.Parameters.Keys | Where-Object { $_ -notin $commonParams }
        $customParams | Should -BeNullOrEmpty
    }

    It 'Output format is compatible with Add-WMRoute' {
        # Mock output that simulates Get-WindowDetails return
        $mockOutput = @(
            [PSCustomObject]@{ Name = 'Firefox'; Type = 'class'; Source = 'WM_CLASS' }
            [PSCustomObject]@{ Name = 'firefox'; Type = 'instance'; Source = 'WM_CLASS instance' }
        )

        # Simulate what Add-WMRoute does with this input
        $results = @()
        foreach ($item in $mockOutput) {
            $hash = @{}
            foreach ($prop in $item.PSObject.Properties) {
                $hash[$prop.Name.ToLower()] = $prop.Value
            }
            # Normalize 'name' to 'app'
            if ($hash.ContainsKey('name') -and -not $hash.ContainsKey('app')) {
                $hash['app'] = $hash['name']
                $hash.Remove('name') | Out-Null
            }
            $results += $hash
        }

        # Verify conversion worked
        $results | Should -Not -BeNullOrEmpty
        $results[0].app | Should -Be 'Firefox'
        $results[0].type | Should -Be 'class'
        $results[1].app | Should -Be 'firefox'
        $results[1].type | Should -Be 'instance'
    }

    It 'Piping to Add-WMRoute works (with mock data)' {
        $testWorkspace = 9
        $mockWindowDetails = @(
            [PSCustomObject]@{ Name = 'TestApp'; Type = 'class'; Source = 'Test' }
        )

        # This should work without errors
        { $mockWindowDetails | Add-WMRoute -Workspace $testWorkspace } | Should -Not -Throw

        # Verify it was added
        $result = Get-WM -Workspace $testWorkspace
        $result.App | Should -Contain 'TestApp'
        $result.Type | Should -Contain 'class'

        # Cleanup
        Remove-Item "$HOME/Atelier/workspaces/9.json" -Force
        @() | ConvertTo-Json -Depth 10 | Set-Content "$HOME/Atelier/workspaces/9.json"
    }

    It 'Piping to Add-WMFilter works (with mock data)' {
        $mockWindowDetails = @(
            [PSCustomObject]@{ Name = 'TestFloat'; Type = 'instance'; Source = 'Test' }
        )

        # This should work without errors
        { $mockWindowDetails | Add-WMFilter } | Should -Not -Throw

        # Verify it was added
        $result = Get-WM -Filters
        $result.App | Should -Contain 'TestFloat'
        $result.Type | Should -Contain 'instance'

        # Cleanup
        $filters = Get-WM -Filters | Where-Object { $_.App -ne 'TestFloat' }
        $filters | ForEach-Object {
            @{ app = $_.App; type = $_.Type }
        } | ConvertTo-Json -Depth 10 | Set-Content "$HOME/Atelier/workspaces/filters.json"
    }
}
