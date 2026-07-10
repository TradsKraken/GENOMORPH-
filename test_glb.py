import re

with open('d:/Godot/controls/Models/mosquito/mosquito1.glb', 'rb') as f:
    content = f.read()
    
matches = re.findall(b'"name":"([^"]+)"', content)
for m in set(matches):
    print(m.decode('utf-8'))
