extends Spatial

# class member variables go here, for example:
var player
var player_script
var time
var count
#start/finish
var finish = false
var start

# test
export var raceline = PoolVector3Array() #[]
var dist = 0
var target_time = 0

export var target = Vector3()

func _ready():
	player_script = load("res://car/vehicle_player.gd")
	count = false
	
	set_process(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func set_finish(val):
	finish = val

func _on_Area_body_enter( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area entered by the player")
			player = body
			
			if finish:
				print("Reached finish marker")
				start.count = false
				
				var msg = body.get_node("Messages")
				#msg.set_initial(false)
				msg.set_text("FINISH TEST RACE!")
				#msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")
				msg.enable_ok(false)
				msg.show()
				
				# prize
				if start.time < target_time: # if we beat calculated target time
					player.money += 80
					player.hud.update_money(player.money)
				
				
				#remove finish
				queue_free()
			else:
				var msg = body.get_node("Messages")
				#msg.set_initial(false)
				msg.set_text("TEST RACE! " + "\n" + "Drive along the road to the finish marker")
				if not msg.get_node("OK_button").is_connected("pressed", self, "_on_ok_click"):
					print("Not connected")
					msg.get_node("OK_button").connect("pressed", self, "_on_ok_click")
					
				else:
					print("Connected")
				msg.enable_ok(true)
				msg.show()
		#else:
		#	print("Area entered by a car " + body.get_parent().get_name())
	#else:
	#	print("Area entered by something else")


func _on_ok_click():
	count = true
	time = 0.0
	player.get_parent().get_node("AnimationPlayer").recording = true
	spawn_finish(self)
	print("Clicked ok!")
	play_replay()
	
	
func _process(delta):
	if count:
		time += delta
		#print("Timer is " + str(time))
		player.get_node("root").get_node("Label timer").show()
		player.get_node("root").update_timer(str(time))
	#else:
	#	print("Count is off")

func _on_Area_body_exit( body ):
	if body is VehicleBody:
		if body is player_script:
			print("Area exited by the player")
			player = body
			if not finish:
				var msg = body.get_node("Messages")
				msg.hide()
				
func spawn_finish(start):
	print("Should be spawning finish")
	
	# because we need distance to calculate target time
	calculate_distance()
	

	
	var loc = target
	var our = preload("res://objects/marker.tscn")
	var finish = our.instance()
	finish.set_name("Finish")
	finish.set_translation(loc)
	finish.finish = true
	finish.start = start
	finish.target_time = target_time()
	print("Target time: " + str(finish.target_time) + " s")
	#finish.set_val(true)
	
	get_parent().add_child(finish)
	
	var minimap = player.find_node("minimap")
	minimap.add_marker(finish.get_global_transform().origin, minimap.blue_flag)
	
	# test
	var track_map = minimap.find_node("track")
	track_map.points = track_map.vec3s_convert(raceline)
	# force redraw
	track_map.update()

	
func calculate_distance():
	#var dist = 0
	# because +1
	for i in range(raceline.size()-2):
		var p = raceline[i]
		dist += p.distance_to(raceline[i+1])
	
	print("Length of race: " + str(dist) + "m")
	
func target_time():
	# we assume we need to beat a time set by avg speed
	# speed limit (60 kph) = 16.7 m/s
	var calc = dist/18
	
	# buffer
	
	return calc*1.4

func play_replay():
	if File.new().file_exists("res://replay/replay.tscn"):
		print("We have a replay")
		
		# load our stuff
		var ghost = preload("res://car/car_replay.tscn")
		var ghost_in = ghost.instance()
		ghost_in.set_name("Ghost")
		
		var repl = load("res://replay/replay.tscn")
		var replay = repl.instance()
		replay.set_name("replay")
		# test
		replay.set_script(preload("res://replay/replay.gd"))
		
		# fix offset
		ghost_in.set_translation(player.get_parent().get_translation())
		
		get_parent().add_child(ghost_in)
		ghost_in.add_child(replay)
		
		# play
		ghost_in.get_node("replay").play("BODY")
		