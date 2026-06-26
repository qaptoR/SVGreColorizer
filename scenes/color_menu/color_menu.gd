class_name ColorMenu
extends Window


signal open_color_picker()

@onready var _PreviewButton_ :Button = %PreviewButton
@onready var _ThemeButton_ :Button = %ThemeButton
@onready var _AccentButton_ :Button = %AccentButton
@onready var _FontButton_ :Button = %FontButton
@onready var _SaveButton_ :Button = %SaveButton
@onready var _ResetButton_ :Button = %ResetButton

@onready var buttons :Dictionary = {
    'preview': _PreviewButton_,
    'theme':   _ThemeButton_,
    'accent':  _AccentButton_,
    'font':    _FontButton_,
}

var _Main_ :Control


func _ready() -> void:
    __setup_dependencies()

    _PreviewButton_.pressed.connect(_on_color_button_pressed.bind(_PreviewButton_, 'preview_color'))
    _ThemeButton_.pressed.connect(_on_color_button_pressed.bind(_ThemeButton_, 'theme_color'))
    _AccentButton_.pressed.connect(_on_color_button_pressed.bind(_AccentButton_, 'accent_color'))
    _FontButton_.pressed.connect(_on_color_button_pressed.bind(_FontButton_, 'font_color'))
    _SaveButton_.pressed.connect(_on_save_button_pressed)
    _ResetButton_.pressed.connect(_on_reset_button_pressed)
    close_requested.connect(hide)


func __setup_dependencies() -> void:
    _Main_ = get_tree().current_scene

    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:open_color_picker")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("ColorMenu", self)


func _on_color_button_pressed(button_ :Button, state_data_ :String) -> void:
    AppState.color_picker_state = GE.Color_Picker.OPTIONS
    AppState.current_color_button = {'button': button_, 'state_data': state_data_}
    open_color_picker.emit()


func _on_save_button_pressed() -> void:
    AppState.save_settings(GC.SETTINGS_PATH, AppState.app_data)
    hide()


func _on_reset_button_pressed() -> void:
    AppState.generate_user_settings(GE.SettintsReset.THEME)
    Colorist.update_colors(_Main_.theme, AppState.app_data)
    hide()
