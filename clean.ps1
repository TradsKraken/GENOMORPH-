$files = @("D:\Godot\controls\ui\hud.tscn", "D:\Godot\controls\levels\node_3d.tscn")

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..."
        $content = Get-Content -Path $file -Raw
        
        # Remove cache/... lines
        $content = $content -replace '(?m)^cache/.*$\r?\n', ''
        
        # Remove large Image data blocks inside SystemFonts.
        $content = $content -replace '"data": PackedByteArray\("[a-zA-Z0-9+/=]+"\)', '"data": PackedByteArray()'
        
        Set-Content -Path $file -Value $content -NoNewline
        Write-Host "Cleaned $file"
    }
}
