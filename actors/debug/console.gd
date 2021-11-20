extends Control

onready var logger = $Logger
onready var input_line = $Input
onready var singleton = $"/root/Singleton"
onready var serializer = singleton.serializer

var history : PoolStringArray = []
var hist_index = 0


func output(msg):
	logger.text += "\n" + str(msg)
	print(msg)


func run_command(cmd):
	hist_index = 0
	history.append(cmd)
	var args : PoolStringArray = cmd.split(" ")
	match args[0].to_lower():
		"w":
			var path
			if len(args) == 1:
				output("No second argument.")
				return
			match args[1]:
				"basin":
					path = "res://scenes/test/basin.tscn"
				"main":
					path = "res://main.tscn"
				"t1":
					path = "res://scenes/tutorial_1/tutorial_1_1.tscn"
				"t1r2":
					path = "res://scenes/tutorial_1/tutorial_1_2.tscn"
				"t1r3":
					path = "res://scenes/tutorial_1/tutorial_1_3.tscn"
				"t1r4":
					path = "res://scenes/tutorial_1/tutorial_1_4.tscn"
				"custom":
					path = "res://scenes/digtest/digtest.tscn"
				"ldtest":
					path = "res://scenes/test/ld_level_test.tscn"
				_:
					path = ""
			if path == "":
				output("Scene does not exist.")
			else:
				var err = singleton.warp_to(path)
				if err == OK:
					output("Warped to " + path)
				else:
					output("Error: " + err)
		"scene":
			var scene = "res://" + args[1] + ".tscn"
			var file_check = File.new()
			if file_check.file_exists(scene):
				var err = singleton.warp_to(scene)
				if err == OK:
					output("Warped to " + scene)
				else:
					output("Error: " + err)
			else:
				output("Scene does not exist.")
		"water":
			if args[1].to_lower() == "inf":
				singleton.water = INF
				output("Water is now infinite.")
			else:
				singleton.water = int(args[1])
				output("Water set to %d" % int(args[1]))
		"ref":
			singleton.water = max(singleton.water, 100)
			output("Water refilled" % int(args[1]))
		"c":
			singleton.classic = !singleton.classic
			if singleton.classic:
				output("Classic mode enabled.")
			else:
				output("Classic mode disabled.")
		"die":
			$"/root/Main/Player".take_damage(8)
			output("Dead.")
		"dmg":
			$"/root/Main/Player".take_damage(int(args[1]))
			output("Took %d damage." % int(args[1]))
		"fdmg":
			singleton.hp -= int(args[1])
			output("Forced %d damage." % int(args[1]))
		"kris":
			singleton.kris = !singleton.kris
		"designer", "ld":
			output("Entered Level Designer.")
			#warning-ignore:RETURN_VALUE_DISCARDED
			singleton.warp_to("res://level_designer.tscn")
		_:
			output("Unknown command \"%s\"." % args[0])


func _process(_delta):
	if Input.is_action_just_pressed("debug"):
		visible = !visible
		input_line.grab_focus()
		input_line.text = input_line.text.replace("/", "")
	if visible:
		if Input.is_action_just_pressed("ui_accept"):
			run_command(input_line.text)
			input_line.text = ""
		if Input.is_action_just_pressed("ui_up"):
			if hist_index < history.size():
				input_line.text = history[hist_index]
				hist_index += 1
