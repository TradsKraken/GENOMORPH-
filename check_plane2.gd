extends SceneTree
func _init():
    var scene = load('res://Models/FINAL TERRAIN LEVEL 1.glb')
    var inst = scene.instantiate()
    var plane = inst.find_child('*Plane_002*', true, false)
    var out = FileAccess.open('res://plane_check2.txt', FileAccess.WRITE)
    if plane:
        out.store_line('Has mesh: ' + str(plane.mesh != null))
        if plane.mesh:
            out.store_line('Surface count: ' + str(plane.mesh.get_surface_count()))
            for i in range(plane.mesh.get_surface_count()):
                var mat = plane.mesh.surface_get_material(i)
                out.store_line('Mat name: ' + str(mat.name if mat else 'null'))
    out.close()
    quit()
