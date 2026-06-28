$content = Get-Content 'd:\Godot\controls\player\player.gd' -Raw
$content = $content -replace '    ', "`t"
Set-Content -Path 'd:\Godot\controls\player\player.gd' -Value $content -NoNewline
