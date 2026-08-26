extends SceneTree
func _init():
    var scene = load('res://Models/FINAL TERRAIN LEVEL 1.glb')
    var inst = scene.instantiate()
    var plane = inst.find_child('*Plane_002*', true, false)
    var out = FileAccess.open('res://plane_check5.txt', FileAccess.WRITE)
    if plane and plane.mesh:
        var mdt = MeshDataTool.new()
        var array_mesh = plane.mesh
        if not (array_mesh is ArrayMesh):
            # Convert to ArrayMesh if it's not (e.g. ImporterMesh)
            var temp = ArrayMesh.new()
            temp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.mesh.surface_get_arrays(0))
            array_mesh = temp
            
        mdt.create_from_surface(array_mesh, 0)
        var up_normals = 0
        var down_normals = 0
        for i in range(min(10, mdt.get_vertex_count())):
            var n = mdt.get_vertex_normal(i)
            out.store_line('Vertex ' + str(i) + ' normal: ' + str(n))
            if n.y > 0: up_normals += 1
            if n.y < 0: down_normals += 1
        out.store_line('Up: ' + str(up_normals) + ' Down: ' + str(down_normals))
    out.close()
    quit()
