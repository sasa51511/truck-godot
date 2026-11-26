extends Node3D
# Spike: truck on an endless road, touch pedals, built fully in code.
var truck: Node3D
var cam: Camera3D
var speed := 0.0
var gas := false
var brake := false
var steer := 0.0
var lbl: Label
var road_tiles: Array = []

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.25, 0.45, 0.8)
	psm.sky_horizon_color = Color(0.75, 0.82, 0.9)
	psm.ground_horizon_color = Color(0.6, 0.55, 0.45)
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.82, 0.9)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(600, 600)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.72, 0.62, 0.42)
	gmat.roughness = 1.0
	ground.material_override = gmat
	add_child(ground)
	for i in range(12):
		var t := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(8, 0.1, 40)
		t.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.13, 0.13, 0.14)
		m.roughness = 0.85
		t.material_override = m
		t.position = Vector3(0, 0.05, -i * 40.0)
		add_child(t)
		road_tiles.append(t)
		var line := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.25, 0.02, 10)
		line.mesh = lm
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.95, 0.95, 0.9)
		mm.emission_enabled = true
		mm.emission = Color(0.4, 0.4, 0.38)
		line.material_override = mm
		line.position = Vector3(0, 0.12, 0)
		t.add_child(line)
	truck = Node3D.new()
	add_child(truck)
	_box(truck, Vector3(2.5, 2.6, 2.4), Vector3(0, 1.9, -3.0), Color(0.7, 0.1, 0.08))
	_box(truck, Vector3(2.5, 2.0, 2.4), Vector3(0, 2.9, 0.0), Color(0.8, 0.82, 0.85))
	_box(truck, Vector3(2.6, 3.2, 12.0), Vector3(0, 2.4, 6.5), Color(0.9, 0.9, 0.92))
	for z in [-3.0, 3.0, 9.0, 11.0]:
		for x in [-1.3, 1.3]:
			var w := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.55
			cm.bottom_radius = 0.55
			cm.height = 0.4
			w.mesh = cm
			w.rotation_degrees = Vector3(0, 0, 90)
			w.position = Vector3(x, 0.55, z)
			truck.add_child(w)
	cam = Camera3D.new()
	cam.fov = 65
	add_child(cam)
	var ui := CanvasLayer.new()
	add_child(ui)
	lbl = Label.new()
	lbl.position = Vector2(40, 30)
	lbl.add_theme_font_size_override("font_size", 36)
	ui.add_child(lbl)
	_btn(ui, "<", Vector2(40, 560), "l")
	_btn(ui, ">", Vector2(220, 560), "r")
	_btn(ui, "BRAKE", Vector2(900, 560), "brake")
	_btn(ui, "GAS", Vector2(1090, 560), "gas")

func _box(parent: Node3D, size: Vector3, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.3
	m.roughness = 0.45
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)

func _btn(ui: CanvasLayer, txt: String, pos: Vector2, key: String) -> void:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.custom_minimum_size = Vector2(150, 130)
	b.add_theme_font_size_override("font_size", 32)
	b.button_down.connect(func(): _set(key, true))
	b.button_up.connect(func(): _set(key, false))
	ui.add_child(b)

var kl := false
var kr := false
func _set(k: String, v: bool) -> void:
	match k:
		"gas": gas = v
		"brake": brake = v
		"l": kl = v
		"r": kr = v

func _process(dt: float) -> void:
	if gas: speed = min(speed + 12.0 * dt, 30.0)
	elif brake: speed = max(speed - 25.0 * dt, 0.0)
	else: speed = max(speed - 4.0 * dt, 0.0)
	var s := (1.0 if kr else 0.0) - (1.0 if kl else 0.0)
	steer = lerp(steer, s, dt * 6.0)
	truck.position.x = clamp(truck.position.x + steer * speed * 0.12 * dt, -3.0, 3.0)
	truck.position.z -= speed * dt
	truck.rotation.y = -steer * 0.05
	for t in road_tiles:
		if t.position.z > truck.position.z + 60.0:
			t.position.z -= 480.0
	cam.position = truck.position + Vector3(truck.position.x * -0.3, 6.0, 22.0)
	cam.look_at(truck.position + Vector3(0, 2.5, -12.0))
	lbl.text = "%d km/h" % int(speed * 3.6)
