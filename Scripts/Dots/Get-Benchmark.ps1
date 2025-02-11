#requires -Modules Profiler

function Get-Benchmark
{
  param (
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock
  )

  # Run the Profiler module function Trace-Script and send all verbose printing to null
  $trace = Trace-Script -ScriptBlock $ScriptBlock 6>$null
  return $trace
}

function Get-BenchmarkTotalMilliseconds
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Profiler.Trace]$Benchmark
    )

    $Benchmark.TotalDuration.TotalMilliseconds
}
