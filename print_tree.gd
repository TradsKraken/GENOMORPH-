extends SceneTree

func _init():
    var packed = load("res://levels/node_3d.scn")
    if packed:
        var scene = packed.instantiate()
        _print_node(scene, "")
    quit()

func _print_node(node: Node, indent: String):
    var script_path = ""
    if node.get_script():
        script_path = " [" + node.get_script().resource_path + "]"
    print(indent + node.name + " (" + node.get_class() + ")" + script_path)
    for c in node.get_children():
        _print_node(c, indent + "  ")
