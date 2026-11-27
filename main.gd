extends Node3D
# Truck game v2: real GLB truck, PBR road/grass, HDRI sky, forests. Built in code.
const TILE := 40.0
const NT := 14
var truck: Node3D
var cam: Camera3D
var speed := 0.0
var gas := false
var brake := false
var steer := 0.0
var lbl: Label
var tiles: Array = []
var kl := false
var kr := false
var camview := 0

func _tex(p: String) -> Texture2D:
	if ResourceLoader.exists(p):
		return load(p)
	return null

func _ready() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm: Material
	var hdr := _tex("res://assets/sky.hdr")
	if hdr:
		var pm := PanoramaSkyMaterial.new()
		pm.panorama = hdr
		sm = pm
	else:
		var psm := ProceduralSkyMaterial.new()
		psm.sky_top_color = Color(0.25, 0.45, 0.8)
		sm = psm
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.8, 0.88)
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -40, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	var road_m := StandardMaterial3D.new()
	road_m.albedo_texture = _tex("res://assets/asphalt_d.jpg")
	road_m.normal_enabled = true
	road_m.normal_texture = _tex("res://assets/asphalt_n.jpg")
	road_m.uv1_scale = Vector3(2.0, 10.0, 1.0)
	road_m.roughness = 0.8
	var grass_m := StandardMaterial3D.new()
	grass_m.albedo_texture = _tex("res://assets/grass_d.jpg")
	grass_m.albedo_color = Color(0.75, 0.95, 0.6)
	grass_m.normal_enabled = true
	grass_m.normal_texture = _tex("res://assets/grass_n.jpg")
	grass_m.uv1_scale = Vector3(40.0, 5.0, 1.0)
	grass_m.roughness = 1.0
	var line_m := StandardMaterial3D.new()
	line_m.albedo_color = Color(0.92, 0.92, 0.88)
	line_m.roughness = 0.6
	var edge_m := StandardMaterial3D.new()
	edge_m.albedo_color = Color(0.9, 0.9, 0.85)
	var rail_m := StandardMaterial3D.new()
	rail_m.albedo_color = Color(0.7, 0.72, 0.75)
	rail_m.metallic = 0.8
	rail_m.roughness = 0.35
	var tree_mesh := _make_tree_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(NT):
		var t := Node3D.new()
		t.position = Vector3(0, 0, -i * TILE)
		add_child(t)
		tiles.append(t)
		var r := MeshInstance3D.new()
		var pr := PlaneMesh.new()
		pr.size = Vector2(9.0, TILE)
		r.mesh = pr
		r.material_override = road_m
		r.position.y = 0.02
		t.add_child(r)
		var g := MeshInstance3D.new()
		var pg := PlaneMesh.new()
		pg.size = Vector2(400.0, TILE)
		g.mesh = pg
		g.material_override = grass_m
		t.add_child(g)
		for sx in [-1, 1]:
			var e := MeshInstance3D.new()
			var be := BoxMesh.new()
			be.size = Vector3(0.18, 0.02, TILE)
			e.mesh = be
			e.material_override = edge_m
			e.position = Vector3(sx * 4.1, 0.04, 0)
			t.add_child(e)
			for k in range(8):
				var p := MeshInstance3D.new()
				var bp := BoxMesh.new()
				bp.size = Vector3(0.12, 0.7, 0.12)
				p.mesh = bp
				p.material_override = rail_m
				p.position = Vector3(sx * 5.4, 0.45, -TILE / 2.0 + k * 5.0 + 2.5)
				t.add_child(p)
			var rl := MeshInstance3D.new()
			var br := BoxMesh.new()
			br.size = Vector3(0.1, 0.32, TILE)
			rl.mesh = br
			rl.material_override = rail_m
			rl.position = Vector3(sx * 5.35, 0.7, 0)
			t.add_child(rl)
		for k in range(4):
			var d := MeshInstance3D.new()
			var bd := BoxMesh.new()
			bd.size = Vector3(0.15, 0.02, 3.0)
			d.mesh = bd
			d.material_override = line_m
			d.position = Vector3(0, 0.04, -TILE / 2.0 + k * 10.0 + 5.0)
			t.add_child(d)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree_mesh
		mm.instance_count = 70
		for n in range(70):
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var x := side * (rng.randf_range(9.0, 70.0))
			var z := rng.randf_range(-TILE / 2.0, TILE / 2.0)
			var s := rng.randf_range(0.8, 1.7)
			var b := Basis().rotated(Vector3.UP, rng.randf() * 6.28).scaled(Vector3(s, s * rng.randf_range(0.9, 1.4), s))
			mm.set_instance_transform(n, Transform3D(b, Vector3(x, 0, z)))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _tree_mat()
		t.add_child(mi)

	truck = Node3D.new()
	add_child(truck)
	var ps = null
	if ResourceLoader.exists("res://assets/truck.glb"):
		ps = load("res://assets/truck.glb")
	if ps:
		var m: Node3D = ps.instantiate()
		m.rotation.y = PI
		truck.add_child(m)
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 500
	add_child(cam)
	var ui := CanvasLayer.new()
	add_child(ui)
	lbl = Label.new()
	lbl.position = Vector2(30, 20)
	lbl.add_theme_font_size_override("font_size", 28)
	ui.add_child(lbl)
	_btn(ui, "<", Vector2(40, 560), "l")
	_btn(ui, ">", Vector2(200, 560), "r")
	_btn(ui, "BRAKE", Vector2(920, 570), "brake")
	_btn(ui, "GAS", Vector2(1090, 560), "gas")

func _tree_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	return m

func _add_part(st: SurfaceTool, mesh: Mesh, xf: Transform3D, col: Color) -> void:
	var arr := mesh.surface_get_arrays(0)
	var cols := PackedColorArray()
	for i in range(arr[Mesh.ARRAY_VERTEX].size()):
		cols.append(col)
	arr[Mesh.ARRAY_COLOR] = cols
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	st.append_from(tmp, 0, xf)

func _make_tree_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tr := CylinderMesh.new()
	tr.top_radius = 0.18
	tr.bottom_radius = 0.28
	tr.height = 2.0
	tr.radial_segments = 6
	_add_part(st, tr, Transform3D(Basis(), Vector3(0, 1.0, 0)), Color(0.28, 0.2, 0.13))
	var greens := [Color(0.1, 0.32, 0.12), Color(0.14, 0.4, 0.14), Color(0.2, 0.46, 0.16)]
	for i in range(4):
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 2.0 - i * 0.4
		c.height = 2.4
		c.radial_segments = 8
		_add_part(st, c, Transform3D(Basis(), Vector3(0, 2.2 + i * 1.3, 0)), greens[i % 3])
	st.generate_normals()
	return st.commit()

func _box(parent: Node3D, size: Vector3, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)

func _btn(ui: CanvasLayer, txt: String, pos: Vector2, key: String) -> void:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.custom_minimum_size = Vector2(150, 130)
	b.add_theme_font_size_override("font_size", 32)
	b.modulate = Color(1, 1, 1, 0.7)
	b.button_down.connect(func(): _set(key, true))
	b.button_up.connect(func(): _set(key, false))
	ui.add_child(b)

func _set(k: String, v: bool) -> void:
	match k:
		"gas": gas = v
		"brake": brake = v
		"l": kl = v
		"r": kr = v

func _process(dt: float) -> void:
	if OS.get_model_name().to_lower().contains("sdk") or OS.get_model_name().to_lower().contains("emulator"):
		gas = true
	if gas: speed = min(speed + 10.0 * dt, 28.0)
	elif brake: speed = max(speed - 25.0 * dt, 0.0)
	else: speed = max(speed - 4.0 * dt, 0.0)
	var s := (1.0 if kr else 0.0) - (1.0 if kl else 0.0)
	steer = lerp(steer, s, dt * 6.0)
	truck.position.x = clamp(truck.position.x + steer * speed * 0.12 * dt, -3.0, 3.0)
	truck.position.z -= speed * dt
	truck.rotation.y = -steer * 0.04
	for t in tiles:
		if t.position.z > truck.position.z + 60.0:
			t.position.z -= TILE * NT
	cam.position = truck.position + Vector3(truck.position.x * -0.4, 7.0, 27.0)
	cam.look_at(truck.position + Vector3(0, 2.0, -10.0))
	lbl.text = "%d km/h" % int(speed * 3.6)
