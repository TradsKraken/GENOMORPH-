$bytes = [IO.File]::ReadAllBytes('d:\Godot\controls\Models\Frog.glb')
$jsonLen = [BitConverter]::ToUInt32($bytes, 12)
$jsonStr = [Text.Encoding]::UTF8.GetString($bytes, 20, $jsonLen)
$jsonStr | Out-File 'd:\Godot\controls\gltf.json'
