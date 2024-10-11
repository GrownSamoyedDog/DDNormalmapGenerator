extends Control

@onready var file_dialog: FileDialog = $FilepathDialog
@onready var filepath_line_edit: LineEdit = $Panel/ScrollContainer/VBoxContainer/FilepathLineEdit

@onready var texture_rect: TextureRect = $Panel/ScrollContainer/VBoxContainer/TextureRect
@onready var texture_rect_2: TextureRect = $Panel/ScrollContainer/VBoxContainer/TextureRect2

@onready var performing_screen: ColorRect = $PerformingScreen
@onready var saved_screen: ColorRect = $"Saved Screen"
@onready var error_screen: ColorRect = $ErrorScreen

var filepath = ""
# file name is obtained with: filepath.get_file() [Note: This comes with the extension]
# file dir is obtained with: filepath.get_base_dir()
# file end is obtained with: filepath.get_extension()

@onready var COLOR_WHITE_NEUTRAL = Color.hex(0x7f7fffff)
@onready var COLOR_WHITE_N       = Color.hex(0x7fff80ff)
@onready var COLOR_WHITE_NE      = Color.hex(0xdada80ff)
@onready var COLOR_WHITE_E       = Color.hex(0xff7f80ff)
@onready var COLOR_WHITE_SE      = Color.hex(0xda2580ff)
@onready var COLOR_WHITE_S       = Color.hex(0x7f0080ff)
@onready var COLOR_WHITE_SW      = Color.hex(0x252580ff)
@onready var COLOR_WHITE_W       = Color.hex(0x007f80ff)
@onready var COLOR_WHITE_NW      = Color.hex(0x25da80ff)
# Reminder that for hex "0x" means nothing and "ff"/"FF" means full opacity
# 0xRRGGBBAA = Color.hex Format

var image
var texture
var texture2

var image_intermediary
var image_normal

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func _on_filepath_button_pressed() -> void:
	file_dialog.show()

func _on_filepath_dialog_file_selected(path: String) -> void:
	# Save the filepath
	filepath = path
	filepath_line_edit.text = filepath
	
	# Load Image and set Texture to Image
	image = Image.new()
	var err = image.load(filepath)
	if err != OK:
		#Open Error Screen
		error_screen.show()
		
		# Reset the filepath
		filepath = "C:/example.png"
		filepath_line_edit.text = filepath
	else:
		texture = ImageTexture.new()
		texture = ImageTexture.create_from_image(image)
		texture_rect.texture = texture

func _on_generate_button_pressed() -> void:
	performing_screen.show()
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	# This is the only way I can relaibly get the performing_screen to show()??
	# Very hacky, but 2 frames appears to be the magic number(???) regarldess of FPS(???)
	# Likely needs more testing to prove/disprove
	
	# Create Intermediary Image
	image_intermediary = Image.new()
	var size_original = image.get_size()
	image_intermediary = Image.create(size_original.x*2+2, size_original.y*2+2, false, Image.FORMAT_RGBA8)
	#image_intermediary = Image.create(size_original.x*2, size_original.y*2, false, Image.FORMAT_RGBA8)
	
	# =Paint a scaled up version of Image onto Intermediary Image=
	
	# Paint the Interior First
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			for sub_y in range(2):
				for sub_x in range(2): #Sub_X and Sub_Y are exclusively for the 2x Normal Image and not the 1x Image
					var pixel = image.get_pixelv(Vector2i(x, y))
					
					if pixel == Color.WHITE:
						image_intermediary.set_pixelv(Vector2i(1+x*2+sub_x, 1+y*2+sub_y), Color.WHITE)
					elif pixel == Color.BLACK:
						image_intermediary.set_pixelv(Vector2i(1+x*2+sub_x, 1+y*2+sub_y), Color.BLACK)
					else: # This shouldn't happen if the Heightmap was made correctly
						pass
	
	#Paint the Edges of the Intermediary Image
	for x in range(image_intermediary.get_width()):
		image_intermediary.set_pixelv(Vector2i(x, 0), image_intermediary.get_pixelv(Vector2i(x, 0+1)))
	for x in range(image_intermediary.get_width()):
		image_intermediary.set_pixelv(Vector2i(x, image_intermediary.get_height()-1), image_intermediary.get_pixelv(Vector2i(x, image_intermediary.get_height()-2)))
	for y in range(image_intermediary.get_height()):
		image_intermediary.set_pixelv(Vector2i(0, y), image_intermediary.get_pixelv(Vector2i(0+1, y)))
	for y in range(image_intermediary.get_height()):
		image_intermediary.set_pixelv(Vector2i(image_intermediary.get_width()-1, y), image_intermediary.get_pixelv(Vector2i(image_intermediary.get_width()-2, y)))
	
	# Create Normal Image
	image_normal = Image.new()
	image_normal = Image.create(size_original.x*2, size_original.y*2, false, Image.FORMAT_RGBA8)
	
	# Paint the Interior First
	var image_intermediary_offset = Vector2i(1,1)
	for y in range(image_normal.get_height()):
		for x in range(image_normal.get_width()):
			var pixel = image_intermediary.get_pixelv(Vector2i(x+image_intermediary_offset.x, y+image_intermediary_offset.y))
			
			# Save all pixels around current pixel
			var arr = [] # This 2D array will hold true/false vars for each color around the White Pixel
			match pixel:
				Color.BLACK:
					image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_NEUTRAL)
				Color.WHITE:
					for sub_y in range(-1,2): #Range = [-1,0,+1]
						arr.append([])
						for sub_x in range(-1,2): #Range = [-1,0,+1]
							var adj_pixel = image_intermediary.get_pixelv(Vector2i(x+image_intermediary_offset.x+sub_x, y+image_intermediary_offset.y+sub_y))
							if(adj_pixel == Color.WHITE):
								arr[sub_y+1].append(true)
							else:
								arr[sub_y+1].append(false)
					
					# Determine what sides are there - Corners don't matter
					var is_top   = true
					var is_right = true
					var is_bot   = true
					var is_left  = true
					if(arr[0][1]): #Remember that it is [y][x] NOT [x][y] (annoying)
					#if(arr[1][0]):
						is_top   = false
					#if(arr[2][1]):
					if(arr[1][2]):
						is_right = false
					#if(arr[1][2]):
					if(arr[2][1]):
						is_bot   = false
					#if(arr[0][1]):
					if(arr[1][0]):
						is_left  = false
					
					# Paint onto Normal Image
					if(is_top): # Reminder: Because it is scaled up, it is impossible to have situations where a 1 wide or tall pixel has both a TOP and a BOT
						if(is_right):
							#NE
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_NE)
						elif(is_left):
							#NW
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_NW)
						else:
							#N
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_N)
					elif(is_bot):
						if(is_right):
							#SE
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_SE)
						elif(is_left):
							#SW
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_SW)
						else:
							#S
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_S)
					else:
						if(is_right):
							#E
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_E)
						elif(is_left):
							#W
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_W)
						else:
							#NEUTRAL
							image_normal.set_pixelv(Vector2i(x,y), COLOR_WHITE_NEUTRAL)
	
	image_normal.save_png(filepath.get_base_dir()+"/"+filepath.get_file().split(".")[0]+" Normal.png")
	performing_screen.hide()
	saved_screen.show()
	
	#Set TextureRect2
	texture2 = ImageTexture.new()
	texture2 = ImageTexture.create_from_image(image_normal)
	texture_rect_2.texture = texture2

func _on_continue_button_pressed() -> void:
	error_screen.hide()

func _on_ok_button_pressed() -> void:
	saved_screen.hide()
