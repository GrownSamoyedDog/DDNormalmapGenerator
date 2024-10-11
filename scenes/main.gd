extends Control

@onready var file_dialog: FileDialog = $FilepathDialog
@onready var filepath_line_edit: LineEdit = $Panel/ScrollContainer/VBoxContainer/HSC/FilepathLineEdit

@onready var export_name_dialog: ConfirmationDialog = $ExportNameDialog
@onready var export_name_line_edit_2: LineEdit = $ExportNameDialog/ExportNameLineEdit2

@onready var export_name_line_edit: LineEdit = $Panel/ScrollContainer/VBoxContainer/HSC2/ExportNameLineEdit

@onready var texture_rect: TextureRect = $Panel/ScrollContainer/VBoxContainer/TextureRect
@onready var texture_rect_2: TextureRect = $Panel/ScrollContainer/VBoxContainer/TextureRect2

@onready var performing_screen: ColorRect = $PerformingScreen
@onready var saved_screen: ColorRect = $"SavedScreen"
@onready var error_screen: ColorRect = $ErrorScreen
@onready var error_screen_2: ColorRect = $ErrorScreen2

@onready var h_split_container: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer
@onready var h_split_container_2: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer2
@onready var h_split_container_3: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer3
@onready var h_split_container_4: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer4
@onready var h_split_container_5: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer5
@onready var h_split_container_6: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer6

@onready var h_split_container_7: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer7
@onready var h_split_container_8: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer8
@onready var h_split_container_9: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer9
@onready var h_split_container_10: HSplitContainer = $Panel/ScrollContainer/VBoxContainer/HSplitContainer10

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

var is_tilesheet = false
var is_forcing_edge = false

var filepath = ""
# file name is obtained with: filepath.get_file() [Note: This comes with the extension]
# file dir is obtained with: filepath.get_base_dir()
# file end is obtained with: filepath.get_extension()

var filename_export = "Example Normal.png"

var image
var image_intermediary
var image_normal
var texture
var texture2

var image_of_tile
var image_intermediary_of_tile
var image_normal_of_tile


# TODO
# Add Bleed Padding on both input and output
# Context: Atlas Textures, and 3D Textures in general need padding around the edge to prevent Bleed
# 1 Pixel around all tiles will do it for most resolutions... For super large more might be requires
# Simple to implement, but I am just very sleepy right now


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
	
	# Generate export filename
	filename_export = filepath.get_file().split(".")[0]+" Normal.png"
	export_name_line_edit.text = filename_export
	
	# Load Image and set Texture to Image
	image = Image.new()
	var err = image.load(filepath)
	if err != OK:
		#Open Error Screen
		error_screen.show()
		
		# Reset the filepath and image files
		reset_file_values()
	else:
		texture = ImageTexture.new()
		texture = ImageTexture.create_from_image(image)
		texture_rect.texture = texture

func _on_generate_button_pressed() -> void:
	if(filepath == ""):
		error_screen_2.show()
		return
	
	performing_screen.show()
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	# This is the only way I can relaibly get the performing_screen to show()??
	# Very hacky, but 2 frames appears to be the magic number(???) regarldess of FPS(???)
	# Likely needs more testing to prove/disprove
	
	# Do the actual drawing - slightly different for non-tilesheet vs tilesheet since tiles have to be done in isolation
	if(not is_tilesheet): # Not a tilesheet
		var images_from_func = make_normal_image(image)
		image                = images_from_func[0]
		image_normal         = images_from_func[2]
	else: # A tilesheet
		var size_original = image.get_size()
		image_normal = Image.create(size_original.x*2, size_original.y*2, false, Image.FORMAT_RGBA8)
		
		# calculate tilesheet size
		var tilesize_x = h_split_container.get_node("SpinBox").value
		var tilesize_y = h_split_container_2.get_node("SpinBox").value
		var tiles_x = floor(image.get_width()/tilesize_x)
		var tiles_y = floor(image.get_height()/tilesize_y)
		
		for y in range(tiles_y):
			for x in range(tiles_x):
				image_of_tile = image.get_region(Rect2i(Vector2i(x*tilesize_x, y*tilesize_y), Vector2i(tilesize_x, tilesize_y)))
				var b
				var c
				var images_from_func = make_normal_image(image_of_tile)
				for sub_y in range(tilesize_y*2): #*2 because scaled up
					for sub_x in range(tilesize_x*2): #*2 because scaled up
						image_normal.set_pixelv(Vector2i(x*tilesize_x*2+sub_x, y*tilesize_y*2+sub_y), images_from_func[2].get_pixelv(Vector2i(sub_x, sub_y)))
	
	image_normal.save_png(filepath.get_base_dir()+"/"+filename_export)
	performing_screen.hide()
	saved_screen.show()
	
	#Set TextureRect2
	texture2 = ImageTexture.new()
	texture2 = ImageTexture.create_from_image(image_normal)
	texture_rect_2.texture = texture2

func make_normal_image(image):
	var image_intermediary
	var image_normal
	
	# =Paint a scaled up version of Image onto Intermediary Image=
	
	var size_original = image.get_size()
	image_intermediary = Image.create(size_original.x*2+2, size_original.y*2+2, false, Image.FORMAT_RGBA8)
	
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
	if(not is_forcing_edge):
		for x in range(image_intermediary.get_width()):
			image_intermediary.set_pixelv(Vector2i(x, 0), image_intermediary.get_pixelv(Vector2i(x, 0+1)))
		for x in range(image_intermediary.get_width()):
			image_intermediary.set_pixelv(Vector2i(x, image_intermediary.get_height()-1), image_intermediary.get_pixelv(Vector2i(x, image_intermediary.get_height()-2)))
		for y in range(image_intermediary.get_height()):
			image_intermediary.set_pixelv(Vector2i(0, y), image_intermediary.get_pixelv(Vector2i(0+1, y)))
		for y in range(image_intermediary.get_height()):
			image_intermediary.set_pixelv(Vector2i(image_intermediary.get_width()-1, y), image_intermediary.get_pixelv(Vector2i(image_intermediary.get_width()-2, y)))
	else:
		for x in range(image_intermediary.get_width()):
			image_intermediary.set_pixelv(Vector2i(x, 0), Color.BLACK)
		for x in range(image_intermediary.get_width()):
			image_intermediary.set_pixelv(Vector2i(x, image_intermediary.get_height()-1), Color.BLACK)
		for y in range(image_intermediary.get_height()):
			image_intermediary.set_pixelv(Vector2i(0, y), Color.BLACK)
		for y in range(image_intermediary.get_height()):
			image_intermediary.set_pixelv(Vector2i(image_intermediary.get_width()-1, y), Color.BLACK)
	
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
	
	return ([image, image_intermediary, image_normal])

const EXAMPLE = preload("res://assets/example.png")
const EXAMPLE_NORMAL = preload("res://assets/example Normal.png")
func reset_file_values() -> void:
	filepath = ""
	filepath_line_edit.text = "C:/Example.png"
	texture_rect.texture = EXAMPLE
	texture_rect_2.texture = EXAMPLE_NORMAL
	
	filename_export = "Example Normal.png" #filepath.get_file().split(".")[0]+" Normal.png"
	export_name_line_edit.text = "Example Normal.png"

func _on_continue_button_pressed() -> void:
	error_screen.hide()

func _on_ok_button_pressed() -> void:
	saved_screen.hide()

func _on_tilesheet_check_box_toggled(toggled_on: bool) -> void:
	if(toggled_on):
		is_tilesheet = true
		h_split_container.show()
		h_split_container_2.show()
		#h_split_container_3.show() #Bleed-Related
		#h_split_container_4.show() #Bleed-Related
		h_split_container_5.show()
		h_split_container_6.show()
		#h_split_container_7.show() #Bleed-Related
		#h_split_container_8.show() #Bleed-Related
		#h_split_container_9.hide() #Bleed-Related
		#h_split_container_10.hide() #Bleed-Related
	else:
		is_tilesheet = false
		h_split_container.hide()
		h_split_container_2.hide()
		#h_split_container_3.hide() #Bleed-Related
		#h_split_container_4.hide() #Bleed-Related
		h_split_container_5.hide()
		h_split_container_6.hide()
		#h_split_container_7.hide() #Bleed-Related
		#h_split_container_8.hide() #Bleed-Related
		#h_split_container_9.show() #Bleed-Related
		#h_split_container_10.show() #Bleed-Related


func _on_qs_16_and_0b_button_pressed() -> void:
	h_split_container.get_node("SpinBox").value   = 16
	h_split_container_2.get_node("SpinBox").value = 16
	h_split_container_3.get_node("SpinBox").value = 0
	h_split_container_4.get_node("SpinBox").value = 0


func _on_qs_16_and_1b_button_pressed() -> void:
	h_split_container.get_node("SpinBox").value   = 16
	h_split_container_2.get_node("SpinBox").value = 16
	h_split_container_3.get_node("SpinBox").value = 1
	h_split_container_4.get_node("SpinBox").value = 1


func _on_qs_32_and_0b_button_pressed() -> void:
	h_split_container.get_node("SpinBox").value   = 32
	h_split_container_2.get_node("SpinBox").value = 32
	h_split_container_3.get_node("SpinBox").value = 0
	h_split_container_4.get_node("SpinBox").value = 0


func _on_qs_32_and_1b_button_pressed() -> void:
	h_split_container.get_node("SpinBox").value   = 32
	h_split_container_2.get_node("SpinBox").value = 32
	h_split_container_3.get_node("SpinBox").value = 1
	h_split_container_4.get_node("SpinBox").value = 1


func _on_qs_0eb_button_pressed() -> void:
	h_split_container_7.get_node("SpinBox").value  = 0
	h_split_container_8.get_node("SpinBox").value  = 0
	h_split_container_9.get_node("SpinBox").value  = 0
	h_split_container_10.get_node("SpinBox").value = 0

func _on_qs_1eb_button_pressed() -> void:
	h_split_container_7.get_node("SpinBox").value  = 1
	h_split_container_8.get_node("SpinBox").value  = 1
	h_split_container_9.get_node("SpinBox").value  = 1
	h_split_container_10.get_node("SpinBox").value = 1

func _on_continue_2_button_pressed() -> void:
	error_screen_2.hide()

func _on_tilesheet_check_box_2_toggled(toggled_on: bool) -> void:
	is_forcing_edge = toggled_on
	
	print(is_forcing_edge)

func _on_filepath_line_edit_focus_entered() -> void:
	file_dialog.show()

func _on_export_name_dialog_confirmed() -> void:
	var new_text = export_name_line_edit_2.text
	
	# Generate export filename
	filename_export = new_text
	filename_export = filename_export#.get_file().split(".")[0]+" Normal.png"
	export_name_line_edit.text = filename_export

func _on_change_button_pressed() -> void:
	file_dialog.show()

func _on_change_button_2_pressed() -> void:
	export_name_line_edit_2.text = filename_export
	export_name_dialog.show()
