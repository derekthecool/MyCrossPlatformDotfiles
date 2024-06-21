# 1. Test with numbers first
1..10

# 2. Test with ls with ForEach-Object next exports to markdown nicely (default printing does not have ansi color)
ls | ForEach-Object { $_.Fullname }

# 3. Show PSVersion table
$psversiontable.psVersion.ToString()

# 4. Get ShowDemo module version
(Get-Module -Name ShowDemo | Select-Object -ExpandProperty Version).ToString()

# 5. Exports to mark down with some gross ansi coloring
ls

# 6. Test with some numbers (still bad)
1..10
