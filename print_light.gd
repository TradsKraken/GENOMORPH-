extends SceneTree
func _init():
    var scn = load("res://levels/node_3d.scn")
    if scn:
        var inst = scn.instantiate()
        print("Root node: ", inst.name, " type: ", inst.get_class())
        for c in inst.get_children():
            if c is DirectionalLight3D:
                print("Found DirectionalLight3D as direct child: ", c.name)
                print("Transform: ", c.transform)
                print("Light Color: ", c.light_color)
                print("Light Energy: ", c.light_energy)
                print("Shadow Enabled: ", c.shadow_enabled)
            else:
                _search(c)
    quit()

func _search(node: Node):
    if node is DirectionalLight3D:
        print("Found DirectionalLight3D deep in tree: ", node.get_path())
    for c in node.get_children():
        _search(c)
