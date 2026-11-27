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
	env = Environment.new()
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
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.95, 0.72, 0.55)
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-11, -25, 0)
	sun.light_color = Color(1.0, 0.6, 0.32)
	sun.light_energy = 2.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)

	var road_m := StandardMaterial3D.new()
	road_m.albedo_texture = _tex("res://assets/asphalt_d.jpg")
	road_m.normal_enabled = true
	road_m.normal_texture = _tex("res://assets/asphalt_n.jpg")
	road_m.uv1_scale = Vector3(2.0, 10.0, 1.0)
	road_m.roughness = 0.38
	road_m.metallic_specular = 0.9
	road_mat = road_m
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
	var hill_m := StandardMaterial3D.new()
	hill_m.albedo_color = Color(0.3, 0.42, 0.28)
	hill_m.roughness = 1.0
	var pole_m := StandardMaterial3D.new()
	pole_m.albedo_color = Color(0.35, 0.3, 0.26)
	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 0.9
	bush_mesh.height = 1.3
	bush_mesh.radial_segments = 8
	bush_mesh.rings = 4
	var bush_m := StandardMaterial3D.new()
	bush_m.albedo_color = Color(0.17, 0.36, 0.13)
	bush_m.roughness = 1.0
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
		var bm := MultiMesh.new()
		bm.transform_format = MultiMesh.TRANSFORM_3D
		bm.mesh = bush_mesh
		bm.instance_count = 30
		for n in range(30):
			var sd := 1.0 if rng.randf() < 0.5 else -1.0
			var bs := rng.randf_range(0.7, 1.8)
			bm.set_instance_transform(n, Transform3D(Basis().scaled(Vector3(bs, bs * 0.8, bs)), Vector3(sd * rng.randf_range(6.6, 14.0), 0.4, rng.randf_range(-TILE / 2.0, TILE / 2.0))))
		var bmi := MultiMeshInstance3D.new()
		bmi.multimesh = bm
		bmi.material_override = bush_m
		t.add_child(bmi)
		for hh in range(2):
			var hl := MeshInstance3D.new()
			var hs := SphereMesh.new()
			hs.radius = 1.0
			hs.height = 1.0
			hs.radial_segments = 14
			hs.rings = 6
			hl.mesh = hs
			hl.material_override = hill_m
			var hsd := -1.0 if hh == 0 else 1.0
			hl.scale = Vector3(rng.randf_range(60.0, 130.0), rng.randf_range(18.0, 50.0), rng.randf_range(40.0, 70.0))
			hl.position = Vector3(hsd * rng.randf_range(120.0, 200.0), -3.0, rng.randf_range(-TILE / 2.0, TILE / 2.0))
			t.add_child(hl)
		if i % 2 == 0:
			var pl := MeshInstance3D.new()
			var pb := CylinderMesh.new()
			pb.top_radius = 0.1
			pb.bottom_radius = 0.14
			pb.height = 9.0
			pb.radial_segments = 6
			pl.mesh = pb
			pl.material_override = pole_m
			pl.position = Vector3(7.2, 4.5, 0)
			t.add_child(pl)
			var arm := MeshInstance3D.new()
			var ab2 := BoxMesh.new()
			ab2.size = Vector3(2.2, 0.12, 0.12)
			arm.mesh = ab2
			arm.material_override = pole_m
			arm.position = Vector3(6.2, 8.8, 0)
			t.add_child(arm)
		var mm2 := MultiMesh.new()
		mm2.transform_format = MultiMesh.TRANSFORM_3D
		mm2.mesh = broad_mesh
		mm2.instance_count = 40
		for n in range(40):
			var side2 := 1.0 if rng.randf() < 0.5 else -1.0
			var s2 := rng.randf_range(0.9, 1.5)
			var b2 := Basis().rotated(Vector3.UP, rng.randf() * 6.28).scaled(Vector3(s2, s2 * rng.randf_range(0.9, 1.3), s2))
			mm2.set_instance_transform(n, Transform3D(b2, Vector3(side2 * rng.randf_range(13.0, 60.0), 0, rng.randf_range(-TILE / 2.0, TILE / 2.0))))
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
			var x := side * (rng.randf_range(13.0, 70.0))
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
		cab_pos = Vector3(-0.55, 2.75, -1.3)
		truck_model = m
		_apply_paint(m, PAINTS[paint_i][1])
		_make_trailer()
	_engine_setup()
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 500
	add_child(cam)
	var svp := SubViewport.new()
	svp.size = Vector2i(256, 160)
	svp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	svp_node = svp
	add_child(svp)
	rcam = Camera3D.new()
	rcam.fov = 55
	rcam.far = 300
	svp.add_child(rcam)
	var svp2 := SubViewport.new()
	svp2.size = Vector2i(256, 160)
	svp2.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(svp2)
	svp_node2 = svp2
	rcam2 = Camera3D.new()
	rcam2.fov = 55
	rcam2.far = 300
	svp2.add_child(rcam2)
	var vtex2 := svp2.get_texture()
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
		mm2.albedo_texture = vtex if sx < 0 else vtex2
		mm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm2.uv1_scale = Vector3(-1, 1, 1)
		mm2.uv1_offset = Vector3(1, 0, 0)
		mr.material_override = mm2
		mr.position = Vector3(-0.55 if sx < 0 else 1.45, 0.05, -1.0)
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
	var im2 := StandardMaterial3D.new()
	im2.albedo_color = Color(0.1, 0.1, 0.11)
	im2.roughness = 0.9
	var parts := [[Vector3(2.9, 0.14, 1.8), Vector3(0.5, 0.78, -0.6), 0.0, 0.0], [Vector3(0.12, 1.5, 0.12), Vector3(-0.78, 0.1, -1.1), 0.0, 0.22], [Vector3(0.12, 1.5, 0.12), Vector3(1.78, 0.1, -1.1), 0.0, -0.22], [Vector3(0.08, 0.6, 1.0), Vector3(-0.8, -0.62, -0.7), 0.0, 0.0], [Vector3(0.08, 0.6, 1.0), Vector3(1.8, -0.62, -0.7), 0.0, 0.0]]
	for pp in parts:
		var pm := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = pp[0]
		pm.mesh = pb
		pm.material_override = im2
		pm.position = pp[1]
		pm.rotation.z = pp[3]
		dash.add_child(pm)
	var cl := MeshInstance3D.new()
	var cb2 := BoxMesh.new()
	cb2.size = Vector3(0.34, 0.1, 0.03)
	cl.mesh = cb2
	var clm := StandardMaterial3D.new()
	clm.albedo_color = Color(0.1, 0.5, 0.25)
	clm.emission_enabled = true
	clm.emission = Color(0.1, 0.7, 0.3)
	cl.material_override = clm
	cl.position = Vector3(-0.3, -0.5, -1.15)
	cl.rotation.x = 0.4
	dash.add_child(cl)
	dash.visible = false
	_weather_setup()
	var ui := CanvasLayer.new()
	add_child(ui)
	_load()
	gate = Node3D.new()
	add_child(gate)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.96, 0.7, 0.05)
	gm.emission_enabled = true
	gm.emission = Color(0.5, 0.3, 0.0)
	for sx in [-1, 1]:
		var gp := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.6, 9.0, 0.6)
		gp.mesh = gb
		gp.material_override = gm
		gp.position = Vector3(sx * 6.5, 4.5, 0)
		gate.add_child(gp)
	var gt := MeshInstance3D.new()
	var gtb := BoxMesh.new()
	gtb.size = Vector3(14.0, 2.4, 0.5)
	gt.mesh = gtb
	gt.material_override = gm
	gt.position = Vector3(0, 8.4, 0)
	gate.add_child(gt)
	gate.visible = false
	hud = Label.new()
	hud.position = Vector2(1000, 150)
	hud.custom_minimum_size = Vector2(250, 0)
	hud.add_theme_stylebox_override("normal", _sbox(Color(0.05, 0.07, 0.1, 0.75), Color(0.3, 0.9, 0.4), 6))
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud.add_theme_constant_override("outline_size", 6)
	ui.add_child(hud)
	toast_lbl = Label.new()
	toast_lbl.position = Vector2(300, 600)
	toast_lbl.add_theme_font_size_override("font_size", 34)
	toast_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	toast_lbl.add_theme_constant_override("outline_size", 8)
	ui.add_child(toast_lbl)
	menu_root = PanelContainer.new()
	menu_root.position = Vector2(60, 40)
	menu_root.size = Vector2(1160, 640)
	menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 10)
	menu_root.add_child(menu_box)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.97)
	sb.border_color = Color(0.98, 0.62, 0.1)
	sb.border_width_top = 5
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	menu_root.add_theme_stylebox_override("panel", sb)
	var ml := CanvasLayer.new()
	ml.layer = 5
	add_child(ml)
	ml.add_child(menu_root)
	_make_offers()
	_build_menu()
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
	dial.position = Vector2(780, 520)
	dial.size = Vector2(320, 200)
	dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dial)
	var pb1 := PedalCtl.new()
	pb1.main = self
	pb1.key = "brake"
	pb1.position = Vector2(1060, 540)
	pb1.size = Vector2(90, 150)
	ui.add_child(pb1)
	var pb2 := PedalCtl.new()
	pb2.main = self
	pb2.key = "gas"
	pb2.position = Vector2(1165, 500)
	pb2.size = Vector2(90, 190)
	ui.add_child(pb2)
	var pill := PanelContainer.new()
	pill.position = Vector2(840, 14)
	pill.add_theme_stylebox_override("panel", _sbox(Color(0.05, 0.07, 0.1, 0.8), Color(0.3, 0.85, 0.35), 0))
	money_lbl = _lbl("", 26, Color.WHITE)
	pill.add_child(money_lbl)
	ui.add_child(pill)
	var ik := 0
	for kind in ["gear", "camera", "pause"]:
		var ib := MenuBtn.new()
		ib.main = self
		ib.kind = kind
		ib.rnd = true
		ib.position = Vector2(1000 + ik * 70, 8)
		ib.size = Vector2(58, 58)
		ui.add_child(ib)
		ik += 1
	var mn := MiniCtl.new()
	mn.main = self
	mn.position = Vector2(1120, 8)
	mn.size = Vector2(140, 140)
	mn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mn.position = Vector2(1130, 74)
	ui.add_child(mn)
	var items := [["jobs", "Jobs"], ["garage", "Garage"], ["house", "House"], ["company", "Company"], ["shop", "Shop"]]
	for i in range(items.size()):
		var mb := MenuBtn.new()
		mb.main = self
		mb.kind = items[i][0]
		mb.text = items[i][1]
		mb.position = Vector2(14, 120 + i * 58)
		mb.size = Vector2(190, 50)
		ui.add_child(mb)

var glass_nodes: Array = []
var hide_nodes: Array = []
var eng_play: AudioStreamGeneratorPlayback
var eng_ph := 0.0
var eng_ph2 := 0.0
var eng_noise := 0.0
var dash: Node3D
const CITIES := [["Cairo", 30.04, 31.24], ["Alexandria", 31.20, 29.92], ["Tanta", 30.79, 31.00], ["Mansoura", 31.04, 31.38], ["Suez", 29.97, 32.55], ["Asyut", 27.18, 31.18], ["Luxor", 25.69, 32.64], ["Aswan", 24.09, 32.90]]
const CARGO := ["Vegetables", "Cement", "Bricks", "Furniture", "Fruit", "Steel", "Fuel", "Flour", "Ceramics", "Electronics"]
var money := 500
var fuel := 100.0
var city := 0
var jobs_done := 0
var job: Dictionary = {}
var z0 := 0.0
var tleft := 0.0
var menu_open := true
var menu_root: Control
var menu_box: VBoxContainer
var menu_msg := "Welcome, driver. Pick a load."
var hud: Label
var offers: Array = []
var gate: Node3D
var toast_t := 0.0
var toast_lbl: Label

func _km(a: int, b: int) -> float:
	var la1: float = deg_to_rad(CITIES[a][1])
	var la2: float = deg_to_rad(CITIES[b][1])
	var dl: float = deg_to_rad(CITIES[b][2] - CITIES[a][2])
	var dla: float = la2 - la1
	var h: float = sin(dla / 2.0) * sin(dla / 2.0) + cos(la1) * cos(la2) * sin(dl / 2.0) * sin(dl / 2.0)
	return 6371.0 * 2.0 * asin(sqrt(h))

var env: Environment
var sun: DirectionalLight3D
var svp_node: SubViewport
var svp_node2: SubViewport
var rcam2: Camera3D
var rain: CPUParticles3D
var heads: Array = []
var wmode := 0
var weather_t := 0.0
var night_c := 0.0
var rain_c := 0.0
var road_mat: StandardMaterial3D
var cond := 100.0
var engine_lv := 0
var tune_lv := 0
var paint_i := 0
var energy := 100.0
var page := "jobs"
var truck_model: Node3D
const PAINTS := [["Red", Color(0.75, 0.08, 0.08)], ["Blue", Color(0.08, 0.2, 0.7)], ["White", Color(0.9, 0.9, 0.9)], ["Black", Color(0.06, 0.06, 0.07)], ["Green", Color(0.08, 0.5, 0.18)], ["Orange", Color(0.95, 0.45, 0.05)]]

func _weather_setup() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 1400
	rain.lifetime = 0.9
	rain.local_coords = false
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(14, 0.2, 14)
	rain.direction = Vector3(0, -1, 0)
	rain.spread = 2.0
	rain.gravity = Vector3(0, -12, 0)
	rain.initial_velocity_min = 22.0
	rain.initial_velocity_max = 26.0
	var rm := BoxMesh.new()
	rm.size = Vector3(0.012, 0.7, 0.012)
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(0.75, 0.82, 0.95, 0.5)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.material = rmat
	rain.mesh = rm
	rain.position = Vector3(0, 10, 0)
	rain.emitting = false
	cam.add_child(rain)
	for sx in [-1, 1]:
		var sl := SpotLight3D.new()
		sl.position = Vector3(sx * 0.8, 1.0, -2.7)
		sl.spot_range = 70.0
		sl.spot_angle = 32.0
		sl.light_energy = 0.0
		sl.light_color = Color(1.0, 0.95, 0.8)
		truck.add_child(sl)
		heads.append(sl)

func _weather(dt: float) -> void:
	weather_t += dt
	var tn := 0.0
	var tr := 0.0
	match wmode:
		0:
			tn = 1.0 if fmod(weather_t, 360.0) > 200.0 else 0.0
			tr = 1.0 if fmod(weather_t + 90.0, 300.0) < 70.0 else 0.0
		1:
			tn = 0.0
			tr = 0.0
		2:
			tn = 1.0
		3:
			tr = 1.0
		4:
			tn = 1.0
			tr = 1.0
	night_c = move_toward(night_c, tn, dt * 0.4)
	rain_c = move_toward(rain_c, tr, dt * 0.4)
	if env == null:
		return
	env.background_energy_multiplier = lerpf(1.0, 0.05, night_c) * lerpf(1.0, 0.55, rain_c)
	env.ambient_light_energy = lerpf(0.7, 0.12, night_c) * lerpf(1.0, 0.7, rain_c)
	env.fog_light_color = Color(0.95, 0.72, 0.55).lerp(Color(0.04, 0.05, 0.09), night_c).lerp(Color(0.45, 0.48, 0.52) * (1.0 - 0.8 * night_c), rain_c * 0.7)
	env.fog_density = 0.0045 + rain_c * 0.006
	env.fog_sky_affect = lerpf(0.45, 1.0, night_c)
	env.tonemap_exposure = lerpf(1.0, 0.6, night_c)
	sun.light_energy = lerpf(2.4, 0.04, night_c) * lerpf(1.0, 0.35, rain_c)
	for h in heads:
		h.light_energy = night_c * 14.0 + rain_c * 3.0
	rain.emitting = rain_c > 0.05
	rain.position = Vector3(0, 10, 0)
	if road_mat:
		road_mat.roughness = lerpf(0.38, 0.12, rain_c)

func _vmax() -> float:
	var v := 28.0 + engine_lv * 3.0
	if cond < 25.0:
		v *= 0.7
	if energy < 15.0:
		v *= 0.75
	return v

func _open_page(k: String) -> void:
	page = k
	menu_open = true
	menu_msg = ""
	_build_menu()
	menu_root.visible = true

func _page_btn(txt: String, cb: Callable, w: float = 520.0) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(w, 74)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _sbox(Color(0.13, 0.16, 0.2, 0.95), Color(0.98, 0.62, 0.1), 8))
	b.add_theme_stylebox_override("hover", _sbox(Color(0.2, 0.24, 0.3, 0.95), Color(1.0, 0.75, 0.2), 8))
	b.add_theme_stylebox_override("pressed", _sbox(Color(0.98, 0.62, 0.1, 0.95), Color(1, 1, 1), 8))
	b.pressed.connect(cb)
	return b

func _spend(cost: int, ok_msg: String) -> bool:
	if money < cost:
		menu_msg = "Not enough money (%d EGP needed)." % cost
		_build_menu()
		return false
	money -= cost
	menu_msg = ok_msg
	_save()
	return true

func _build_page() -> void:
	var title := page.to_upper()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	top.add_child(_lbl(title, 40, Color(0.98, 0.7, 0.2)))
	var mm := _lbl(menu_msg, 22, Color(0.75, 0.9, 0.8))
	mm.custom_minimum_size = Vector2(600, 0)
	mm.autowrap_mode = TextServer.AUTOWRAP_WORD
	top.add_child(mm)
	menu_box.add_child(top)
	menu_box.add_child(_lbl("EGP %d     Condition %d%%     Energy %d%%     Engine Lv %d     Tuning Lv %d" % [money, int(cond), int(energy), engine_lv + 1, tune_lv + 1], 22, Color(0.55, 0.9, 0.6)))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 20)
	g.add_theme_constant_override("v_separation", 16)
	menu_box.add_child(g)
	if page == "garage":
		var rc := int(ceil((100.0 - cond) * 4.0))
		g.add_child(_page_btn("Repair  (%d EGP)" % rc, func():
			if rc == 0:
				menu_msg = "Truck is already in perfect shape."
				_build_menu()
			elif _spend(rc, "Truck repaired."):
				cond = 100.0
				_build_menu()))
		var uc := 800 * (engine_lv + 1)
		g.add_child(_page_btn("Upgrade engine  (%d EGP)" % uc if engine_lv < 3 else "Engine maxed", func():
			if engine_lv >= 3:
				return
			if _spend(uc, "Engine upgraded: top speed +11 km/h."):
				engine_lv += 1
				_build_menu()))
		g.add_child(_page_btn("Paint: %s  (150 EGP)" % PAINTS[paint_i][0], func():
			if _spend(150, "Fresh paint job."):
				paint_i = (paint_i + 1) % PAINTS.size()
				_apply_paint(truck_model, PAINTS[paint_i][1])
				_build_menu()))
		var tc := 600 * (tune_lv + 1)
		g.add_child(_page_btn("Tuning: turbo  (%d EGP)" % tc if tune_lv < 3 else "Tuning maxed", func():
			if tune_lv >= 3:
				return
			if _spend(tc, "Turbo installed: faster acceleration."):
				tune_lv += 1
				_build_menu()))
	elif page == "house":
		g.add_child(_page_btn("Sleep  (energy to 100%)", func():
			energy = 100.0
			menu_msg = "You slept well."
			_save()
			_build_menu()))
		g.add_child(_page_btn("Eat  (40 EGP, +30 energy)", func():
			if _spend(40, "Tasty meal."):
				energy = minf(100.0, energy + 30.0)
				_build_menu()))
		g.add_child(_page_btn("Home  (stats)", func():
			menu_msg = "Jobs done: %d. Money: %d EGP. Home city: %s." % [jobs_done, money, CITIES[city][0]]
			_build_menu()))
		g.add_child(_page_btn("Coffee  (10 EGP, +10 energy)", func():
			if _spend(10, "Strong coffee."):
				energy = minf(100.0, energy + 10.0)
				_build_menu()))
	else:
		g.add_child(_lbl("Coming soon.", 30, Color(0.8, 0.85, 0.92)))
	menu_box.add_child(_page_btn("Back to Jobs", func():
		page = "jobs"
		_build_menu(), 300.0))

func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("g", "money", money)
	cf.set_value("g", "fuel", fuel)
	cf.set_value("g", "city", city)
	cf.set_value("g", "jobs", jobs_done)
	cf.set_value("g", "cond", cond)
	cf.set_value("g", "elv", engine_lv)
	cf.set_value("g", "tlv", tune_lv)
	cf.set_value("g", "paint", paint_i)
	cf.set_value("g", "energy", energy)
	cf.save("user://save.cfg")

func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://save.cfg") == OK:
		money = cf.get_value("g", "money", 500)
		fuel = cf.get_value("g", "fuel", 100.0)
		city = cf.get_value("g", "city", 0)
		jobs_done = cf.get_value("g", "jobs", 0)
		cond = cf.get_value("g", "cond", 100.0)
		engine_lv = cf.get_value("g", "elv", 0)
		tune_lv = cf.get_value("g", "tlv", 0)
		paint_i = cf.get_value("g", "paint", 0)
		energy = cf.get_value("g", "energy", 100.0)

func _make_offers() -> void:
	offers.clear()
	var idx: Array = []
	for i in range(CITIES.size()):
		if i != city:
			idx.append(i)
	idx.shuffle()
	for q in range(3):
		var ti: int = idx[q]
		var km := _km(city, ti)
		var d: int = int(clamp(round(km * 10.0 / 50.0) * 50.0, 1200.0, 6500.0))
		var tons: int = randi_range(4, 24)
		var pay: int = int(round(d / 5.0 * (0.45 + tons / 28.0) / 10.0) * 10.0) + randi_range(0, 4) * 10
		offers.append({"to": ti, "d": d, "tons": tons, "pay": pay, "t": int(d / 19.0) + 25, "cargo": CARGO[randi() % CARGO.size()]})

func _sbox(col: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(14)
	s.border_color = border
	s.border_width_left = bw
	s.content_margin_left = 22
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _mk_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(620, 84)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _sbox(Color(0.13, 0.16, 0.2, 0.95), Color(0.98, 0.62, 0.1), 8))
	b.add_theme_stylebox_override("hover", _sbox(Color(0.2, 0.24, 0.3, 0.95), Color(1.0, 0.75, 0.2), 8))
	b.add_theme_stylebox_override("pressed", _sbox(Color(0.98, 0.62, 0.1, 0.95), Color(1, 1, 1), 8))
	b.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	b.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05))
	b.pressed.connect(cb)
	menu_box.add_child(b)
	return b

func _open_menu(msg: String) -> void:
	menu_open = true
	page = "jobs"
	menu_msg = msg
	job = {}
	gate.visible = false
	_make_offers()
	_build_menu()
	menu_root.visible = true
	_save()

var sel := 0
var money_lbl: Label
func _lbl(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

func _build_menu() -> void:
	for c in menu_box.get_children():
		c.queue_free()
	sel = clampi(sel, 0, maxi(0, offers.size() - 1))
	if page != "jobs":
		_build_page()
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	top.add_child(_lbl(CITIES[city][0].to_upper(), 40, Color(0.98, 0.7, 0.2)))
	var msgl := _lbl(menu_msg, 20, Color(0.75, 0.8, 0.88))
	msgl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msgl.custom_minimum_size = Vector2(560, 0)
	msgl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(msgl)
	menu_box.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	menu_box.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)
	var mp := MapCtl.new()
	mp.main = self
	mp.custom_minimum_size = Vector2(600, 300)
	left.add_child(mp)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	left.add_child(tabs)
	for i in range(offers.size()):
		var o: Dictionary = offers[i]
		var ii := i
		var b := Button.new()
		b.text = "%s\n%d EGP" % [CITIES[o["to"]][0], o["pay"]]
		b.custom_minimum_size = Vector2(190, 74)
		b.add_theme_font_size_override("font_size", 22)
		var on := (i == sel)
		b.add_theme_stylebox_override("normal", _sbox(Color(0.2, 0.3, 0.45, 0.95) if on else Color(0.12, 0.14, 0.18, 0.95), Color(0.3, 0.8, 0.4) if on else Color(0.3, 0.32, 0.38), 6))
		b.add_theme_stylebox_override("hover", _sbox(Color(0.2, 0.3, 0.45, 0.95), Color(0.3, 0.8, 0.4), 6))
		b.add_theme_stylebox_override("pressed", _sbox(Color(0.3, 0.45, 0.65, 0.95), Color(1, 1, 1), 6))
		b.pressed.connect(func(): sel = ii; _build_menu())
		tabs.add_child(b)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	var cs := _sbox(Color(0.08, 0.1, 0.14, 0.95), Color(0.3, 0.32, 0.4), 2)
	cs.set_corner_radius_all(16)
	card.add_theme_stylebox_override("panel", cs)
	row.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)
	cv.add_child(_lbl("Cargo Details", 26, Color(0.9, 0.93, 1.0)))
	if offers.size() > 0:
		var o2: Dictionary = offers[sel]
		cv.add_child(_lbl("%s (%d Tons)" % [o2["cargo"], o2["tons"]], 24, Color(1.0, 0.85, 0.5)))
		cv.add_child(_lbl("From: %s" % CITIES[city][0], 22, Color(0.8, 0.85, 0.92)))
		cv.add_child(_lbl("To: %s" % CITIES[o2["to"]][0], 22, Color(0.8, 0.85, 0.92)))
		cv.add_child(_lbl("Distance: %.1f km   Time: %ds" % [o2["d"] / 1000.0, o2["t"]], 20, Color(0.7, 0.75, 0.85)))
		cv.add_child(_lbl("Reward:", 22, Color(0.8, 0.85, 0.92)))
		cv.add_child(_lbl("EGP %d" % o2["pay"], 40, Color(0.5, 0.95, 0.35)))
	var acc := Button.new()
	acc.text = "Accept Job"
	acc.custom_minimum_size = Vector2(340, 70)
	acc.add_theme_font_size_override("font_size", 30)
	acc.add_theme_stylebox_override("normal", _sbox(Color(0.15, 0.62, 0.2), Color(0.5, 0.95, 0.4), 0))
	acc.add_theme_stylebox_override("hover", _sbox(Color(0.2, 0.72, 0.25), Color(0.5, 0.95, 0.4), 0))
	acc.add_theme_stylebox_override("pressed", _sbox(Color(0.1, 0.45, 0.14), Color(1, 1, 1), 0))
	acc.pressed.connect(func(): _start_job(sel))
	cv.add_child(acc)
	var need := int(ceil((100.0 - fuel) * 3.0))
	var rf := Button.new()
	rf.text = "Refuel (%d EGP)" % need
	rf.custom_minimum_size = Vector2(340, 52)
	rf.add_theme_font_size_override("font_size", 22)
	rf.add_theme_stylebox_override("normal", _sbox(Color(0.14, 0.16, 0.2), Color(0.98, 0.62, 0.1), 6))
	rf.pressed.connect(func(): _refuel())
	cv.add_child(rf)
	var st := _lbl("EGP %d    Fuel %d%%    Jobs %d" % [money, int(fuel), jobs_done], 20, Color(0.55, 0.9, 0.6))
	cv.add_child(st)

func _refuel() -> void:
	var need := int(ceil((100.0 - fuel) * 3.0))
	var c := mini(money, need)
	fuel = minf(100.0, fuel + c / 3.0)
	money -= c
	_open_menu("Fuel tank refilled." if c >= need else "Not enough money for a full tank.")

func _start_job(i: int) -> void:
	if fuel < 5.0:
		_open_menu("Out of fuel. Refuel first.")
		return
	job = offers[i]
	z0 = truck.position.z
	tleft = float(job["t"])
	gate.position = Vector3(0, 0, z0 - float(job["d"]))
	gate.visible = true
	menu_root.visible = false
	menu_open = false
	_toast("Deliver %s to %s" % [job["cargo"], CITIES[job["to"]][0]])

func _toast(t: String) -> void:
	toast_lbl.text = t
	toast_t = 3.5

func _game_tick(dt: float) -> void:
	if money_lbl:
		money_lbl.text = "  EGP %d  +" % money
	if not job.is_empty():
		var travelled: float = z0 - truck.position.z
		var rem: float = float(job["d"]) - travelled
		tleft -= dt
		fuel = maxf(0.0, fuel - speed * dt * 0.0045 * (1.0 + float(job["tons"]) / 60.0))
		hud.text = "%s > %s\n%.1f km   %ds\nFuel %d%%" % [CITIES[city][0], CITIES[job["to"]][0], maxf(0.0, rem) / 1000.0, maxi(0, int(tleft)), int(fuel)]
		if rem <= 6.0:
			var late := tleft < 0.0
			var pay: int = int(job["pay"]) / (2 if late else 1)
			money += pay
			jobs_done += 1
			city = job["to"]
			_open_menu(("Late, half pay: %d EGP" if late else "Delivered on time! +%d EGP") % pay)
			return
		if fuel <= 0.0 and speed < 1.0:
			var fee := mini(money, 100)
			money -= fee
			fuel = 20.0
			_open_menu("Out of fuel. Tow fee %d EGP." % fee)
	else:
		hud.text = "No active job\nFuel %d%%" % int(fuel)
	if toast_t > 0.0:
		toast_t -= dt
		toast_lbl.modulate.a = clampf(toast_t, 0.0, 1.0)
	else:
		toast_lbl.modulate.a = 0.0

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

func _apply_paint(n: Node, col: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in range(mi.mesh.get_surface_count()):
			var mt := mi.mesh.surface_get_material(i)
			if mt and String(mt.resource_name) == "paint" and mt is StandardMaterial3D:
				var nm := (mt as StandardMaterial3D).duplicate() as StandardMaterial3D
				nm.albedo_color = col
				nm.metallic = 0.45
				nm.roughness = 0.28
				mi.set_surface_override_material(i, nm)
	for c in n.get_children():
		_apply_paint(c, col)

func _tbox(sz: Vector3, pos: Vector3, col: Color, rough: float = 0.6, met: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "trl_box"
	var b := BoxMesh.new()
	b.size = sz
	mi.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = met
	mi.material_override = m
	mi.position = pos
	truck.add_child(mi)

func _make_trailer() -> void:
	_tbox(Vector3(2.9, 3.0, 12.6), Vector3(0, 2.75, 7.8), Color(0.9, 0.9, 0.88), 0.5)
	_tbox(Vector3(2.95, 0.12, 12.7), Vector3(0, 1.3, 7.8), Color(0.12, 0.12, 0.13))
	_tbox(Vector3(2.94, 0.5, 12.0), Vector3(0, 2.0, 7.8), Color(0.75, 0.08, 0.08), 0.4)
	_tbox(Vector3(2.0, 0.25, 12.4), Vector3(0, 1.0, 7.8), Color(0.08, 0.08, 0.09))
	_tbox(Vector3(2.3, 0.35, 0.1), Vector3(0, 1.45, 14.15), Color(0.9, 0.1, 0.1), 0.3)
	for z in [10.2, 11.4, 12.6]:
		for x in [-1.1, 1.1]:
			var w := MeshInstance3D.new()
			w.name = "trl_wheel"
			var c := CylinderMesh.new()
			c.top_radius = 0.5
			c.bottom_radius = 0.5
			c.height = 0.34
			w.mesh = c
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.05, 0.05, 0.055)
			m.roughness = 0.9
			w.material_override = m
			w.rotation.z = PI / 2.0
			w.position = Vector3(x, 0.5, z)
			truck.add_child(w)

func _find_glass(n: Node) -> void:
	if n is MeshInstance3D and not String(n.name).begins_with("wheel") and not String(n.name).begins_with("trl"):
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
var plan_n := 5
func _demo() -> void:
	var mn := OS.get_model_name().to_lower()
	if not (mn.contains("sdk") or mn.contains("emulator") or OS.has_feature("x86_64")):
		return
	if demo_t0 < 0:
		print("DEMO start model=", mn)
	if demo_t0 < 0:
		demo_t0 = Time.get_ticks_msec()
	var t := (Time.get_ticks_msec() - demo_t0) / 1000.0
	if demo_t0 >= 0 and menu_open and (Time.get_ticks_msec() - demo_t0) / 1000.0 > 9.0 and demo_n >= 1 and demo_n <= plan_n:
		_start_job(0)
	var plan := [[6.0, 0, 0.0], [14.0, 2, 0.0], [20.0, 2, 0.0], [28.0, 0, 0.5], [36.0, 1, 0.5]]
	if demo_n < plan.size():
		var p = plan[demo_n]
		if t >= p[0]:
			camview = p[1]
			gas = demo_n >= 2
			wsteer = p[2]
			var img := get_viewport().get_texture().get_image()
			var er := img.save_png("user://s%d.png" % (demo_n + 1))
			print("DEMO saved ", demo_n + 1, " err=", er)
			demo_n += 1
	elif demo_n == plan.size() and t > 44.0:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("user://s6.png")
		demo_n += 1
		_open_page("garage")
	elif demo_n == plan.size() + 1 and t > 47.0:
		get_viewport().get_texture().get_image().save_png("user://s7.png")
		demo_n += 1
		_open_page("house")
	elif demo_n == plan.size() + 2 and t > 50.0:
		get_viewport().get_texture().get_image().save_png("user://s8.png")
		demo_n += 1
		menu_root.visible = false
		menu_open = false
		page = "jobs"
		wmode = 4
		camview = 0
		gas = true
	elif demo_n == plan.size() + 3 and t > 60.0:
		get_viewport().get_texture().get_image().save_png("user://s9.png")
		demo_n += 1
		wmode = 2
		camview = 2
	elif demo_n == plan.size() + 4 and t > 66.0:
		get_viewport().get_texture().get_image().save_png("user://s10.png")
		demo_n += 1

func _process(dt: float) -> void:
	_demo()
	_weather(dt)
	_engine_fill()
	if menu_open:
		gas = false
		brake = true
	_game_tick(dt)
	if fuel <= 0.0:
		gas = false
	if speed > 1.0:
		cond = maxf(0.0, cond - speed * dt * 0.0006)
		energy = maxf(0.0, energy - dt * 0.012)
	if gas: speed = min(speed + (10.0 + tune_lv * 2.0) * dt, _vmax())
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
		cam.position = truck.position + Vector3(truck.position.x * -0.4 + 13.0, 6.5, 24.0)
		cam.look_at(truck.position + Vector3(0, 2.0, 2.0))
		cam.fov = 62
	elif camview == 1:
		cam.position = truck.position + Vector3(truck.position.x * -0.4, 11.0, 30.0)
		cam.look_at(truck.position + Vector3(0, 1.0, -8.0))
		cam.fov = 62
	else:
		cam.position = truck.position + cab_pos
		cam.rotation = Vector3(-0.05, -steer * 0.05, 0)
		cam.fov = 75
	dash.visible = camview == 2
	svp_node.render_target_update_mode = SubViewport.UPDATE_ALWAYS if camview == 2 else SubViewport.UPDATE_DISABLED
	svp_node2.render_target_update_mode = SubViewport.UPDATE_ALWAYS if camview == 2 else SubViewport.UPDATE_DISABLED
	for hn in hide_nodes:
		hn.visible = camview != 2
	rcam.position = truck.position + Vector3(-1.9, 2.8, -1.0)
	rcam.look_at(truck.position + Vector3(-3.2, 2.2, 40.0))
	rcam2.position = truck.position + Vector3(1.9, 2.8, -1.0)
	rcam2.look_at(truck.position + Vector3(3.2, 2.2, 40.0))
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
		var gtxt := "N"
		if kmh > 1.0:
			gtxt = "D%d" % clampi(1 + int(kmh / 17.0), 1, 8)
		draw_string(f, c + Vector2(34, -22), gtxt, HORIZONTAL_ALIGNMENT_LEFT, 44, 20, Color(0.3, 1.0, 0.4))
		draw_string(f, c + Vector2(-30, -22), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color(0.7, 0.8, 0.9))

class PedalCtl extends Control:
	var main
	var key := "gas"
	var down := false
	func _gui_input(e) -> void:
		if e is InputEventScreenTouch or e is InputEventMouseButton:
			down = e.pressed
			main.set(key, down)
			queue_redraw()
	func _draw() -> void:
		var col := Color(0.55, 0.57, 0.6, 0.95) if not down else Color(0.9, 0.5, 0.2, 0.95)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(14)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var n := 8 if key == "gas" else 6
		for i in range(n):
			var y := 14.0 + i * (size.y - 28.0) / float(n)
			draw_line(Vector2(14, y), Vector2(size.x - 14, y), Color(0.15, 0.15, 0.17, 0.9), 4.0)

class MenuBtn extends Control:
	var main
	var kind := "jobs"
	var text := ""
	var rnd := false
	func _gui_input(e) -> void:
		if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
			match kind:
				"camera":
					main.camview = (main.camview + 1) % 3
				"gear":
					main.wmode = (main.wmode + 1) % 5
					main._toast(["Weather: auto", "Weather: clear day", "Weather: night", "Weather: rain", "Weather: night rain"][main.wmode])
				"pause":
					if main.menu_open:
						return
					main._toast("Finish or cancel your job to open the menu")
				"jobs":
					if main.job.is_empty() and not main.menu_open:
						main._open_menu("Pick a load.")
					elif not main.menu_open:
						main._toast("Finish your current job first")
				_:
					if main.job.is_empty() and not main.menu_open:
						main._open_page(kind)
					elif not main.menu_open:
						main._toast("Finish your current job first")
	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.07, 0.1, 0.78)
		sb.set_corner_radius_all(int(size.y / 2.0) if rnd else 12)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var c := Vector2(26, size.y / 2.0) if not rnd else size / 2.0
		var w := Color(0.92, 0.95, 1.0)
		match kind:
			"jobs":
				draw_rect(Rect2(c + Vector2(-12, -8), Vector2(24, 18)), w, false, 2.5)
				draw_rect(Rect2(c + Vector2(-5, -13), Vector2(10, 5)), w, false, 2.5)
			"garage":
				draw_polyline(PackedVector2Array([c + Vector2(-13, 10), c + Vector2(-13, -4), c + Vector2(0, -12), c + Vector2(13, -4), c + Vector2(13, 10)]), w, 2.5)
				draw_rect(Rect2(c + Vector2(-7, 0), Vector2(14, 10)), w, false, 2.5)
			"house":
				draw_polyline(PackedVector2Array([c + Vector2(-12, 4), c + Vector2(0, -10), c + Vector2(12, 4)]), w, 2.5)
				draw_rect(Rect2(c + Vector2(-8, 4), Vector2(16, 8)), w, false, 2.5)
			"company":
				draw_rect(Rect2(c + Vector2(-9, -12), Vector2(18, 24)), w, false, 2.5)
				for yy in range(3):
					draw_line(c + Vector2(-4, -6 + yy * 7), c + Vector2(4, -6 + yy * 7), w, 2.0)
			"shop":
				draw_polyline(PackedVector2Array([c + Vector2(-13, -10), c + Vector2(-8, -10), c + Vector2(-5, 6), c + Vector2(9, 6), c + Vector2(11, -4), c + Vector2(-7, -4)]), w, 2.5)
				draw_circle(c + Vector2(-3, 11), 2.5, w)
				draw_circle(c + Vector2(7, 11), 2.5, w)
			"gear":
				draw_arc(c, 10, 0, TAU, 24, w, 3.0)
				for k in range(8):
					var a := k * TAU / 8.0
					draw_line(c + Vector2(cos(a), sin(a)) * 10, c + Vector2(cos(a), sin(a)) * 15, w, 4.0)
			"camera":
				draw_rect(Rect2(c + Vector2(-14, -8), Vector2(28, 18)), w, false, 2.5)
				draw_circle(c + Vector2(0, 1), 5, w)
			"pause":
				draw_rect(Rect2(c + Vector2(-8, -10), Vector2(6, 20)), w)
				draw_rect(Rect2(c + Vector2(3, -10), Vector2(6, 20)), w)
		if text != "":
			draw_string(ThemeDB.fallback_font, Vector2(54, size.y / 2.0 + 8), text, HORIZONTAL_ALIGNMENT_LEFT, 130, 24, Color(0.95, 0.97, 1.0))

class MiniCtl extends Control:
	var main
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0 - 2.0
		draw_circle(c, r, Color(0.08, 0.12, 0.1, 0.9))
		draw_arc(c, r, 0, TAU, 40, Color(0.9, 0.93, 0.95), 3.0)
		draw_line(c + Vector2(0, r - 4), c + Vector2(0, -r + 6), Color(0.35, 0.37, 0.4), 12.0)
		if not main.job.is_empty():
			var pts := PackedVector2Array([c + Vector2(0, 14), c + Vector2(0, -8), c + Vector2(14, -26), c + Vector2(22, -r + 10)])
			draw_polyline(pts, Color(1.0, 0.82, 0.1), 5.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, 2), c + Vector2(9, 22), c + Vector2(-9, 22)]), Color(1.0, 0.25, 0.2))

class MapCtl extends Control:
	var main
	const OUT := [[25.0, 31.6], [29.0, 30.9], [31.0, 31.6], [32.3, 31.3], [34.2, 31.3], [34.9, 29.5], [34.3, 27.8], [33.2, 28.0], [33.5, 27.0], [35.5, 23.9], [36.9, 22.0], [25.0, 22.0]]
	func _p(lat: float, lon: float) -> Vector2:
		return Vector2((lon - 24.5) / 12.8 * size.x, (32.0 - lat) / 10.2 * size.y)
	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.2, 0.32)
		sb.set_corner_radius_all(14)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var poly := PackedVector2Array()
		for q in OUT:
			poly.append(_p(q[1], q[0]))
		var tris := Geometry2D.triangulate_polygon(poly)
		if tris.size() > 0:
			draw_colored_polygon(poly, Color(0.62, 0.52, 0.34))
		var nile := [[31.24, 30.04], [31.2, 29.0], [30.8, 28.1], [31.18, 27.18], [31.7, 26.56], [32.72, 26.16], [32.64, 25.69], [32.9, 24.09]]
		var np := PackedVector2Array()
		for q in nile:
			np.append(_p(q[1], q[0]))
		draw_polyline(np, Color(0.2, 0.5, 0.75), 4.0)
		for i in range(CITIES.size()):
			var pp := _p(CITIES[i][1], CITIES[i][2])
			draw_circle(pp, 6.0 if i == main.city else 4.0, Color(1.0, 0.85, 0.2) if i == main.city else Color(0.9, 0.9, 0.9))
			draw_string(ThemeDB.fallback_font, pp + Vector2(8, 4), CITIES[i][0], HORIZONTAL_ALIGNMENT_LEFT, 120, 17, Color.WHITE)
		if main.offers.size() > 0:
			var o: Dictionary = main.offers[main.sel]
			var a := _p(CITIES[main.city][1], CITIES[main.city][2])
			var b := _p(CITIES[o["to"]][1], CITIES[o["to"]][2])
			var mid := (a + b) / 2.0 + Vector2(-26, 0)
			var rp := PackedVector2Array()
			for k in range(21):
				var tt := k / 20.0
				rp.append(a.lerp(mid, tt).lerp(mid.lerp(b, tt), tt))
			draw_polyline(rp, Color(1.0, 0.85, 0.1), 5.0)
			draw_circle(b, 8.0, Color(0.3, 0.9, 0.35))
