class_name ColorPickerPopup
extends Window


signal preview_image(path :String, data :Array[TreeItem])
signal add_new_color(color :String)

@export var color_icon__ :Texture

@onready var _PickerShapes_ :OptionButton = %PickerShapes
@onready var _ColorPicker_ :ColorPicker = %ColorPicker
@onready var _CancelButton_ :Button = %Buttons/Cancel
@onready var _AcceptButton_ :Button = %Buttons/Accept

var _Main_ :Control
var _DirPathLabel_ :Label


func _ready() -> void:
    __setup_dependencies()

    _PickerShapes_.item_selected.connect(func(index_):
        AppState.app_data.color_picker_shape = _PickerShapes_.get_item_id(index_)
        _ColorPicker_.picker_shape = AppState.app_data.color_picker_shape as ColorPicker.PickerShapeType
    )
    _ColorPicker_.color_changed.connect(_on_color_changed)
    _CancelButton_.pressed.connect(hide)
    _AcceptButton_.pressed.connect(func():
        if AppState.color_picker_state == GE.Color_Picker.SWATCH:
            add_new_color.emit("#"+_ColorPicker_.color.to_html(false))
        _ColorPicker_.color_changed.emit(_ColorPicker_.color)
        hide()
    )
    close_requested.connect(hide)

    _ColorPicker_.picker_shape = AppState.app_data.color_picker_shape as ColorPicker.PickerShapeType
    _PickerShapes_.select(_PickerShapes_.get_item_index(AppState.app_data.color_picker_shape))


func __setup_dependencies() -> void:
    _Main_ = get_tree().current_scene

    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal( "sig:open_color_picker", "open_color_picker", open_color_picker)

    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:preview_image")
    _conn_.register("sig:add_new_color")

    var _pcon_ := CSConnector.with(_ColorPicker_)
    _pcon_.register("sig:preset_added")
    _pcon_.register("sig:preset_removed")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("ColorPicker", _ColorPicker_)
    _gloc_.register("ColorPickerPopup", self)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("DirPathLabel", func(service): _DirPathLabel_ = service)


func _unhandled_key_input(event_: InputEvent) -> void:
    if event_.is_action_pressed("ui_cancel"): pass
    elif event_.is_action_pressed("ui_accept"):
        _ColorPicker_.color_changed.emit(_ColorPicker_.color)
    hide()


func open_color_picker(alternate_ :bool = false) -> void:
    _ColorPicker_.color = (func(): match AppState.color_picker_state:
        GE.Color_Picker.TREE:
            return AppState.current_color_button.color.get_icon_modulate(
                1 if alternate_ else 0
            )
        GE.Color_Picker.OPTIONS:
            return Color(AppState.app_data.color_state[AppState.current_color_button.state_data])
        GE.Color_Picker.SWATCH:
            return Color.WHITE
    ).call()
    popup()


func _on_color_changed(color_ :Color) -> void:
    match AppState.color_picker_state:
        GE.Color_Picker.TREE: __update_treeitem_color(color_)
        GE.Color_Picker.OPTIONS: __update_interface_colors(color_)
        GE.Color_Picker.SWATCH: return


func __update_treeitem_color(color_ :Color):
    var _button_ = AppState.current_color_button

    _button_.color.set_icon_modulate(GE.TreeColumn.NEW_COLOR, color_ )
    var _button_data_ :Dictionary = _button_.color.get_meta(GC.META_DATA)
    _button_data_.color.new = color_

    TreeView.check_same(_button_.color)
    TreeView.update_button_state(_button_.color, _button_.col)

    match _button_.icon.get_meta(GC.META_DATA).name:
        'file_name': preview_image.emit(
            '%s/%s' %[_DirPathLabel_.text, _button_.icon.get_text(0)],
            ParserData.get_preview_data(_button_.icon)
        )


func __update_interface_colors(color_ :Color):
    var hColor :String = '#%s' %color_.to_html(false)

    AppState.current_color_button.button.icon = \
        Colorist.create_colored_icon(color_icon__, hColor)

    AppState.app_data.color_state[AppState.current_color_button.state_data] = hColor

    match AppState.current_color_button.state_data:
        'font_color': Colorist.update_font_color(_Main_.theme, color_)
        'preview_color': Colorist.update_preview_color(AppState.app_data)
        'theme_color': Colorist.update_theme_color(_Main_.theme, color_)
        'accent_color': Colorist.update_accent_color(_Main_.theme, color_)
