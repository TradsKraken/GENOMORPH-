$bytes = [IO.File]::ReadAllBytes('d:\Godot\controls\Models\Frog.glb')
$str = [Text.Encoding]::ASCII.GetString($bytes)
$matches = [regex]::Matches($str, '[a-zA-Z0-9_]{3,}')
$matches | Select-Object -ExpandProperty Value | Group-Object | Sort-Object Count -Descending | Select-Object -First 100 | Out-File 'd:\Godot\controls\strings.txt'
