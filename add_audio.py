import os
import re

ui_dir = r'd:\Godot\controls\ui'

# Regex to match a pressed.connect line that doesn't have AudioManager in it.
# It captures the indentation and the button name prefix (everything before .pressed.connect).
pattern = re.compile(r'^(\s*)([a-zA-Z0-9_]+)\.pressed\.connect\((?!.*AudioManager).*$')

for root, _, files in os.walk(ui_dir):
    for file in files:
        if file.endswith('.gd'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_lines = []
            for line in lines:
                match = pattern.match(line)
                if match:
                    indent = match.group(1)
                    btn = match.group(2)
                    new_lines.append(f'{indent}{btn}.pressed.connect(func(): AudioManager.play_sfx("tap_button"))\n')
                new_lines.append(line)
                
            with open(path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)

print('Done')
