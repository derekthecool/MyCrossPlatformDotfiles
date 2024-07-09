BeforeAll {
  Import-Module $PSScriptRoot/../../Dots/Dots.psd1
}

Describe 'Profile benchmarks' {
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
}
