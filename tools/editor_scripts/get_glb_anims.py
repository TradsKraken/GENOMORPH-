import json

with open("Models/Water Monitor Lizard/Monitor Lizard FIXED.glb", "rb") as f:
    f.read(12) # GLB header
    json_chunk_len = int.from_bytes(f.read(4), byteorder='little')
    f.read(4) # Chunk type
    json_data = f.read(json_chunk_len)
    
    data = json.loads(json_data.decode("utf-8"))
    if "animations" in data:
        print("Animations found:")
        for anim in data["animations"]:
            print("-", anim.get("name", "Unnamed"))
    else:
        print("No animations found.")
