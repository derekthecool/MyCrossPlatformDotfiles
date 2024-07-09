BeforeAll {
  Import-Module $PSScriptRoot/../../Dots/Dots.psd1
}

Describe 'Profile benchmarks' {
  # BeforeEach {
  #   Remove-Module -Name Dots
  #   Import-Module $PSScriptRoot/../../Dots/Dots.psd1
  # }
  It 'Profile should run' {
    { . $PROFILE | Should -Not -Throw }
  }

  It 'Profile benchmark should not throw an error' {
    {
      $sb = { . $PROFILE }
      Get-Benchmark -ScriptBlock $sb
      | Get-BenchmarkTotalMilliseconds
    }| Should -Not -Throw
  }

  # It 'Profile benchmark should be a Profile.Trace' {
  #   $sb =  { . $PROFILE }
  #   $benchmark = Get-Benchmark -ScriptBlock $sb
  #   $benchmark | Should -BeOfType Profile.Trace
  # }

  It 'Profile benchmark should not be null' {
    $sb =  { . $PROFILE }
    Get-Benchmark -ScriptBlock $sb | Should -Not -BeNullOrEmpty
  }


  It 'Profile should load at least this fast <Time>' -TestCases @(
    @{ Time = 2000 }
    @{ Time = 1500 }
    @{ Time = 1200 }
  ){
    $sb = { . $PROFILE }
    Get-Benchmark -ScriptBlock $sb | Get-BenchmarkTotalMilliseconds | Should -BeLessThan $Time
  }
}
