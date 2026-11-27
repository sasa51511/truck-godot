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
var wsteer := 0.0
var camview := 0
var cab_pos := Vector3(-0.5, 2.7, -4.0)
var wheel_ui
var dial

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
	var broad_mesh := _make_broad_mesh()
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
		var mm2 := MultiMesh.new()
		mm2.transform_format = MultiMesh.TRANSFORM_3D
		mm2.mesh = broad_mesh
		mm2.instance_count = 40
		for n in range(40):
			var side2 := 1.0 if rng.randf() < 0.5 else -1.0
			var s2 := rng.randf_range(0.9, 1.5)
			var b2 := Basis().rotated(Vector3.UP, rng.randf() * 6.28).scaled(Vector3(s2, s2 * rng.randf_range(0.9, 1.3), s2))
			mm2.set_instance_transform(n, Transform3D(b2, Vector3(side2 * rng.randf_range(8.0, 60.0), 0, rng.randf_range(-TILE / 2.0, TILE / 2.0))))
		var mi2 := MultiMeshInstance3D.new()
		mi2.multimesh = mm2
		mi2.material_override = _tree_mat()
		t.add_child(mi2)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree_mesh
		mm.instance_count = 45
		for n in range(45):
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
		var ab := _aabb(m, Transform3D.IDENTITY)
		print("TRUCK AABB ", ab)
		_find_glass(m)
		_names(m, 0)
		cab_pos = Vector3(ab.position.x + ab.size.x * 0.5 - 0.5, 2.35, ab.position.z + 2.9)
	_engine_setup()
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 500
	add_child(cam)
	var svp := SubViewport.new()
	svp.size = Vector2i(256, 160)
	svp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(svp)
	rcam = Camera3D.new()
	rcam.fov = 55
	rcam.far = 300
	svp.add_child(rcam)
	var vtex := svp.get_texture()
	dash = Node3D.new()
	cam.add_child(dash)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.07, 0.07, 0.08)
	dm.roughness = 0.6
	var top := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(2.6, 0.5, 0.9)
	top.mesh = tb
	top.material_override = dm
	top.position = Vector3(0, -0.78, -1.05)
	top.rotation.x = 0.25
	dash.add_child(top)
	for sx in [-1, 1]:
		var mr := MeshInstance3D.new()
		var mb := BoxMesh.new()
		mb.size = Vector3(0.32, 0.5, 0.04)
		mr.mesh = mb
		var mm2 := StandardMaterial3D.new()
		var im := Image.create(8, 16, false, Image.FORMAT_RGB8)
		for yy in range(16):
			for xx in range(8):
				im.set_pixel(xx, yy, Color(0.62, 0.74, 0.88).lerp(Color(0.2, 0.28, 0.2), clampf((yy - 6) / 4.0, 0.0, 1.0)) if yy < 11 else Color(0.22, 0.22, 0.24))
		mm2.albedo_texture = ImageTexture.create_from_image(im)
		mm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm2.uv1_scale = Vector3(-1, 1, 1)
		mm2.uv1_offset = Vector3(1, 0, 0)
		mr.material_override = mm2
		mr.position = Vector3(sx * 1.25, -0.05, -1.0)
		mr.rotation.y = -sx * 0.45
		dash.add_child(mr)
		var frm := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.37, 0.55, 0.03)
		frm.mesh = fb
		frm.material_override = dm
		frm.position = mr.position + Vector3(0, 0, -0.03)
		frm.rotation.y = mr.rotation.y
		dash.add_child(frm)
	var sw := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.17
	tm.outer_radius = 0.23
	sw.mesh = tm
	sw.material_override = dm
	sw.position = Vector3(-0.3, -0.62, -0.85)
	sw.rotation.x = 1.0
	dash.add_child(sw)
	dash.visible = false
	var ui := CanvasLayer.new()
	add_child(ui)
	lbl = Label.new()
	lbl.position = Vector2(30, 20)
	lbl.add_theme_font_size_override("font_size", 28)
	ui.add_child(lbl)
	wheel_ui = WheelCtl.new()
	wheel_ui.main = self
	wheel_ui.position = Vector2(50, 470)
	wheel_ui.size = Vector2(240, 240)
	ui.add_child(wheel_ui)
	dial = DialCtl.new()
	dial.main = self
	dial.position = Vector2(480, 520)
	dial.size = Vector2(320, 200)
	dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dial)
	var cb := Button.new()
	cb.text = "CAM"
	cb.position = Vector2(1100, 20)
	cb.custom_minimum_size = Vector2(150, 80)
	cb.add_theme_font_size_override("font_size", 30)
	cb.modulate = Color(1, 1, 1, 0.75)
	cb.pressed.connect(func(): camview = (camview + 1) % 3)
	ui.add_child(cb)
	_btn(ui, "BRAKE", Vector2(920, 570), "brake")
	_btn(ui, "GAS", Vector2(1090, 560), "gas")

var glass_nodes: Array = []
var hide_nodes: Array = []
var eng_play: AudioStreamGeneratorPlayback
var eng_ph := 0.0
var eng_ph2 := 0.0
var eng_noise := 0.0
var dash: Node3D
var rcam: Camera3D
func _names(n: Node, d: int) -> void:
	if n is MeshInstance3D:
		var a: AABB = (n as MeshInstance3D).get_aabb()
		print("MESH ", n.name, " pos=", snapped((n as Node3D).global_position, Vector3(0.01, 0.01, 0.01)), " sz=", snapped(a.size, Vector3(0.01, 0.01, 0.01)))
	for c in n.get_children():
		_names(c, d + 1)
func _engine_setup() -> void:
	var p := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	p.stream = gen
	p.volume_db = -4.0
	add_child(p)
	p.play()
	eng_play = p.get_stream_playback()
func _engine_fill() -> void:
	if eng_play == null:
		return
	var n := eng_play.get_frames_available()
	var rpm := 700.0 + clampf(speed / 28.0, 0.0, 1.0) * 1500.0 + (350.0 if gas else 0.0)
	var f := rpm / 60.0 * 2.0
	for i in range(n):
		eng_ph += f / 22050.0
		eng_ph2 += (f * 0.5) / 22050.0
		eng_noise = lerp(eng_noise, randf() * 2.0 - 1.0, 0.25)
		var s := sin(eng_ph * TAU) * 0.45 + sin(eng_ph * 2.0 * TAU) * 0.25 + sin(eng_ph2 * TAU) * 0.35 + signf(sin(eng_ph * 0.5 * TAU)) * 0.08 + eng_noise * (0.1 + (0.1 if gas else 0.0))
		var amp := 0.28 + (0.18 if gas else 0.0)
		var v := Vector2(s * amp, s * amp)
		eng_play.push_frame(v)

func _find_glass(n: Node) -> void:
	if n is MeshInstance3D and (n.name == "body"):
		hide_nodes.append(n)
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in range(mi.mesh.get_surface_count()):
			var mt := mi.mesh.surface_get_material(i)
			if mt == null and mi.get_surface_override_material(i):
				mt = mi.get_surface_override_material(i)
			if mt and String(mt.resource_name).to_lower().contains("glass"):
				glass_nodes.append(mi)
				print("GLASS ", mi.name)
	for c in n.get_children():
		_find_glass(c)

func _aabb(n: Node, xf: Transform3D) -> AABB:
	var res := AABB()
	var first := true
	var stack := [[n, xf]]
	while stack.size() > 0:
		var it = stack.pop_back()
		var node: Node = it[0]
		var t: Transform3D = it[1]
		if node is Node3D:
			t = t * (node as Node3D).transform
		if node is MeshInstance3D:
			var a: AABB = t * (node as MeshInstance3D).get_aabb()
			if first:
				res = a
				first = false
			else:
				res = res.merge(a)
		for c in node.get_children():
			stack.push_back([c, t])
	return res

func _tree_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	return m

func _add_part(st: SurfaceTool, mesh: Mesh, xf: Transform3D, col: Color, jit: float = 0.0) -> void:
	var arr := mesh.surface_get_arrays(0)
	var cols := PackedColorArray()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var h := 1.0
	for v in vs:
		h = max(h, abs(v.y) * 2.0)
	for i in range(vs.size()):
		var v := vs[i]
		var k := clampf(v.y / h + 0.5, 0.0, 1.0)
		cols.append(Color(col.r, col.g, col.b) * (0.55 + 0.6 * k))
		if jit > 0.0:
			var hs: float = float(hash(Vector3i(int(v.x * 50.0), int(v.y * 50.0), int(v.z * 50.0))) % 1000) / 1000.0
			vs[i] = v + Vector3(hs - 0.5, (hs * 3.7 - int(hs * 3.7)) - 0.5, (hs * 7.3 - int(hs * 7.3)) - 0.5) * jit
	arr[Mesh.ARRAY_VERTEX] = vs
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
	for i in range(6):
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 2.1 - i * 0.28
		c.height = 2.0
		c.radial_segments = 11
		c.rings = 2
		_add_part(st, c, Transform3D(Basis().rotated(Vector3.UP, i * 0.9), Vector3(0, 1.8 + i * 0.95, 0)), greens[i % 3], 0.55)
	st.generate_normals()
	return st.commit()

func _make_broad_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tr := CylinderMesh.new()
	tr.top_radius = 0.2
	tr.bottom_radius = 0.34
	tr.height = 3.2
	tr.radial_segments = 6
	_add_part(st, tr, Transform3D(Basis(), Vector3(0, 1.6, 0)), Color(0.3, 0.22, 0.15))
	var gc := [Color(0.22, 0.45, 0.14), Color(0.28, 0.52, 0.16), Color(0.18, 0.4, 0.13), Color(0.34, 0.55, 0.2)]
	var offs := [Vector3(0, 4.6, 0), Vector3(1.3, 3.9, 0.4), Vector3(-1.2, 4.0, -0.5), Vector3(0.3, 5.5, -0.9), Vector3(-0.4, 4.2, 1.3), Vector3(0.6, 3.6, -1.4)]
	for i in range(offs.size()):
		var s := SphereMesh.new()
		s.radius = 1.5 - (i % 3) * 0.15
		s.height = s.radius * 1.8
		s.radial_segments = 10
		s.rings = 6
		_add_part(st, s, Transform3D(Basis(), offs[i]), gc[i % 4], 0.5)
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

var demo_t0 := -1
var demo_n := 0
func _demo() -> void:
	var mn := OS.get_model_name().to_lower()
	if not (mn.contains("sdk") or mn.contains("emulator") or OS.has_feature("x86_64")):
		return
	if demo_t0 < 0:
		print("DEMO start model=", mn)
	if demo_t0 < 0:
		demo_t0 = Time.get_ticks_msec()
	var t := (Time.get_ticks_msec() - demo_t0) / 1000.0
	var plan := [[6.0, 0, 0.0], [12.0, 1, 0.0], [18.0, 2, 0.0], [26.0, 0, 0.6], [34.0, 2, 0.6]]
	if demo_n < plan.size():
		var p = plan[demo_n]
		if t >= p[0]:
			camview = p[1]
			gas = demo_n >= 3
			wsteer = p[2]
			if demo_n >= 1:
				var img := get_viewport().get_texture().get_image()
				var er := img.save_png("user://s%d.png" % demo_n)
				print("DEMO saved ", demo_n, " err=", er, " ", OS.get_user_data_dir())
			demo_n += 1
	elif demo_n == plan.size() and t > 40.0:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("user://s%d.png" % demo_n)
		demo_n += 1

func _process(dt: float) -> void:
	_demo()
	_engine_fill()
	if gas: speed = min(speed + 10.0 * dt, 28.0)
	elif brake: speed = max(speed - 25.0 * dt, 0.0)
	else: speed = max(speed - 4.0 * dt, 0.0)
	var s := wsteer + (1.0 if kr else 0.0) - (1.0 if kl else 0.0)
	steer = lerp(steer, s, dt * 6.0)
	truck.position.x = clamp(truck.position.x + steer * speed * 0.12 * dt, -3.0, 3.0)
	truck.position.z -= speed * dt
	truck.rotation.y = -steer * 0.04
	for t in tiles:
		if t.position.z > truck.position.z + 60.0:
			t.position.z -= TILE * NT
	if camview == 0:
		cam.position = truck.position + Vector3(truck.position.x * -0.4 + 7.5, 4.2, 15.0)
		cam.look_at(truck.position + Vector3(0, 2.0, -6.0))
		cam.fov = 62
	elif camview == 1:
		cam.position = truck.position + Vector3(truck.position.x * -0.4, 4.6, 17.0)
		cam.look_at(truck.position + Vector3(0, 2.2, -8.0))
		cam.fov = 62
	else:
		cam.position = truck.position + cab_pos
		cam.rotation = Vector3(-0.05, -steer * 0.05, 0)
		cam.fov = 75
	dash.visible = camview == 2
	for hn in hide_nodes:
		hn.visible = camview != 2
	rcam.position = truck.position + Vector3(2.0 if camview == 2 else 0.0, 3.0, -4.0)
	rcam.look_at(truck.position + Vector3(0, 2.0, 40.0))
	for gn in glass_nodes:
		gn.visible = camview != 2
	if wheel_ui:
		wheel_ui.queue_redraw()
	if dial:
		dial.queue_redraw()
	lbl.text = ""

class WheelCtl extends Control:
	var main
	var down := false
	var ang := 0.0
	func _gui_input(e) -> void:
		if e is InputEventScreenTouch or e is InputEventMouseButton:
			down = e.pressed
			if down:
				_set(e.position)
			else:
				main.wsteer = 0.0
		elif (e is InputEventScreenDrag or e is InputEventMouseMotion) and down:
			_set(e.position)
	func _set(p: Vector2) -> void:
		var c := size / 2.0
		main.wsteer = clampf((p.x - c.x) / (size.x * 0.35), -1.0, 1.0)
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * 0.46
		ang = lerp(ang, main.steer * 1.6, 0.3)
		draw_set_transform(c, ang, Vector2.ONE)
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.08, 0.08, 0.09, 0.8), 22.0, true)
		draw_arc(Vector2.ZERO, r + 10, 0, TAU, 48, Color(0.5, 0.5, 0.52, 0.5), 2.0, true)
		draw_line(Vector2.ZERO, Vector2(-r, r * 0.3), Color(0.08, 0.08, 0.09, 0.85), 14.0)
		draw_line(Vector2.ZERO, Vector2(r, r * 0.3), Color(0.08, 0.08, 0.09, 0.85), 14.0)
		draw_line(Vector2.ZERO, Vector2(0, r), Color(0.08, 0.08, 0.09, 0.85), 14.0)
		draw_circle(Vector2.ZERO, r * 0.2, Color(0.16, 0.16, 0.18, 0.95))
		draw_rect(Rect2(-8, -r - 10, 16, 20), Color(0.95, 0.78, 0.1))

class DialCtl extends Control:
	var main
	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y - 20.0)
		var r := 130.0
		draw_circle(c, r + 8, Color(0.05, 0.05, 0.06, 0.85))
		draw_arc(c, r, PI * 0.95, PI * 2.05, 40, Color(0.3, 0.3, 0.33), 4.0, true)
		for i in range(0, 11):
			var a := PI * 0.95 + (PI * 1.1) * i / 10.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * (r - 16), c + d * r, Color(0.9, 0.9, 0.9), 3.0)
		var kmh: float = main.speed * 3.6
		var a2 := PI * 0.95 + (PI * 1.1) * clampf(kmh / 140.0, 0.0, 1.0)
		var d2 := Vector2(cos(a2), sin(a2))
		draw_line(c, c + d2 * (r - 12), Color(1.0, 0.25, 0.15), 4.0)
		draw_circle(c, 9, Color(0.2, 0.2, 0.22))
		var f := ThemeDB.fallback_font
		draw_string(f, c + Vector2(-45, -45), "%d" % int(kmh), HORIZONTAL_ALIGNMENT_CENTER, 90, 40, Color.WHITE)
		draw_string(f, c + Vector2(-30, -22), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color(0.7, 0.8, 0.9))
