$json = Get-Content 'd:\Godot\controls\gltf.json' -Raw
[regex]::Matches($json, '\"name\"\s*:\s*\"([^\"]+)\"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique | Set-Content 'd:\Godot\controls\names_utf8.txt' -Encoding UTF8
