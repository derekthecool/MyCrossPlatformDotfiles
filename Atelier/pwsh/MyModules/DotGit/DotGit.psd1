@{
  RootModule        = 'DotGit.psm1'
  ModuleVersion     = '0.1.0'
  GUID              = '87cf412c-909a-4f9b-b08f-5f90f6493992'
  Author            = 'Derek Lomax'
  Description       = 'Simple module for making complex git commands easier'
  PrivateData       = @{
    PSData = @{
      Tags = @('dots')
    }
  }
  VariablesToExport = ''

  # For best lazy load performance CmdletsToExport, AliasesToExport, and FunctionsToExport.
  # must be explicitly set! Never use * because the module will not load if that item is called.

  CmdletsToExport   = @()
  AliasesToExport   = @(
    'gwt'
    'swt'
  )
  FunctionsToExport = @(
    'Get-GitWorktree'
    'Switch-GitWorktree'
  )
}

