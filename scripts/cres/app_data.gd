class_name AppData
extends Resource


@export var color_state :Dictionary = {
    'font_color': '#c8c6c3',
    'preview_color': '#19140b',
    'theme_color': '#19140b',
    'accent_color': '#221a0f',
}
@export var color_picker_shape :int = 0

@export var confirm_commit :bool = true

@export var default_directory :String = ''
@export var favorite_directories :PackedStringArray = []
@export var recent_import_palette :String = ''
