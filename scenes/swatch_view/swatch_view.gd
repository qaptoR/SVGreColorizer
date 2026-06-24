class_name SwatchView
extends Control


signal open_color_picker()

@export var color_icon__ :Texture

@onready var _CurrentSwatch_ :ItemList = %CurrentSwatch
@onready var _AddAll_ :Button = %AddAll
@onready var _AddSelected_ :Button = %AddSelected

@onready var _CustomSwatch_ :ItemList = %CustomSwatch
@onready var _NewColor_ :Button = %NewColor
@onready var _RemoveSelected_ :Button = %RemoveSelected
@onready var _clearAll_ :Button = %ClearAll
@onready var _ImportColors_ :Button = %ImportColors
@onready var _ExportColors_ :Button = %ExportColors
@onready var _SortColors_ :Button = %SortColors

var _ColorPicker_ :ColorPicker
var _FileDialog_ :FileDialog

var current_colors :Array = []


func _ready() -> void:
    __setup_dependencies()

    _AddAll_.pressed.connect(_on_add_all_pressed)
    _AddSelected_.pressed.connect(_on_add_selected_pressed)
    _NewColor_.pressed.connect(_on_new_color_pressed)
    _RemoveSelected_.pressed.connect(_on_remove_selected_pressed)
    _clearAll_.pressed.connect(_on_clear_all_pressed)
    _ImportColors_.pressed.connect(_on_import_colors_pressed)
    _ExportColors_.pressed.connect(_on_export_colors_pressed)
    _SortColors_.pressed.connect(_on_sort_colors_pressed)

    _CurrentSwatch_.item_clicked.connect(_on_swatch_item_clicked.bind(_CurrentSwatch_))
    _CustomSwatch_.item_clicked.connect(_on_swatch_item_clicked.bind(_CustomSwatch_))


func __setup_dependencies() -> void:
    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal("sig:import_palette", "import_palette", import_palette)
    _gcon_.connect_signal("sig:export_palette", "export_palette", export_palette)
    _gcon_.connect_signal("sig:preset_added", "preset_added", _on_color_picker_preset_added)
    _gcon_.connect_signal("sig:preset_removed", "preset_removed", _on_color_picker_preset_removed)
    _gcon_.connect_signal("sig:add_new_color", "add_new_color", add_new_color)

    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:open_color_picker")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("SwatchView", self)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("ColorPicker", func(service): _ColorPicker_ = service)
    _loc_.connect_service_found("FileDialog", func(service): _FileDialog_ = service)


func update_current_colors(color_set_ :Array):
    _CurrentSwatch_.clear()

    for _Color in Colorist.sort_color_list(color_set_.duplicate()):
        var i :int = _CurrentSwatch_.get_item_count()
        _CurrentSwatch_.add_item('#'+_Color.to_html(), color_icon__)
        _CurrentSwatch_.set_item_icon_modulate(i, _Color)


func import_palette(path_ :String) -> void:
    var palette := FileAccess.open(path_, FileAccess.READ)
    if palette == null:
        MessageLogger.error(
            "Could not open palette file for importing: %s" %path_,
            get_script().resource_path.get_file()
        )
        return

    AppState.app_data.recent_import_palette = path_
    AppState.save_settings(GC.SETTINGS_PATH, AppState.app_data)

    while palette.get_position() < palette.get_length():
        var color = palette.get_line()
        if !color.is_valid_html_color(): continue
        add_new_color(color.to_lower())

    palette.close()


func export_palette(path_ :String) -> void:
    var palette := FileAccess.open(path_, FileAccess.WRITE)
    if palette == null:
        MessageLogger.error(
            "Could not open palette file for exporting: %s" %path_,
            get_script().resource_path.get_file()
        )
        return

    for _I in _CustomSwatch_.get_item_count():
        @warning_ignore("integer_division")
        if _I%10 == 0: palette.store_line("; count %s" % (_I))
        palette.store_line(_CustomSwatch_.get_item_text(_I).to_lower())

    palette.close()


func add_new_color(color_ :String, from_picker_ :bool = false) -> void:
    var _count_ :int = _CustomSwatch_.get_item_count()

    for _I in _count_: if _CustomSwatch_.get_item_text(_I) == color_: return

    _CustomSwatch_.add_item(color_, color_icon__)
    _CustomSwatch_.set_item_icon_modulate(_count_, color_)
    if !from_picker_: _ColorPicker_.add_preset(Color(color_))


func _on_color_picker_preset_added(color_ :Color) -> void:
    add_new_color('#%s' %color_.to_html(false), true)


func _on_color_picker_preset_removed(color_ :Color) -> void:
    for _I in _CustomSwatch_.get_item_count():
        if _CustomSwatch_.get_item_icon_modulate(_I).to_html(false) == color_.to_html(false):
            _CustomSwatch_.remove_item(_I)


func _on_add_all_pressed() -> void:
    for _I in _CurrentSwatch_.get_item_count():
        add_new_color(_CurrentSwatch_.get_item_text(_I))


func _on_add_selected_pressed() -> void:
    var _list_ :PackedInt32Array = _CurrentSwatch_.get_selected_items()

    for _I in _list_:
        add_new_color(_CurrentSwatch_.get_item_text(_I))


func _on_sort_colors_pressed() -> void:
    var _colors_ :Array = []

    for _I in _CustomSwatch_.get_item_count():
        _colors_.append(Color(_CustomSwatch_.get_item_text(_I)))

    _colors_ = Colorist.sort_color_list(_colors_)
    _CustomSwatch_.clear()

    for _Color in _colors_: add_new_color(_Color.to_html())


func _on_new_color_pressed() -> void:
    AppState.color_picker_state = GE.Color_Picker.SWATCH
    open_color_picker.emit()


func _on_remove_selected_pressed() -> void:
    var _list_ :PackedInt32Array = _CustomSwatch_.get_selected_items()
    _list_.reverse()

    for _I in _list_:
        for _Color in _ColorPicker_.get_presets():
            if _Color.to_html(false) == _CustomSwatch_.get_item_icon_modulate(_I).to_html(false):
                _ColorPicker_.erase_preset(_Color)
        _CustomSwatch_.remove_item(_I)


func _on_clear_all_pressed() -> void:
    for _I in _CustomSwatch_.get_item_count():
        for _Color in _ColorPicker_.get_presets():
            if _Color.to_html(false) == _CustomSwatch_.get_item_icon_modulate(_I).to_html(false):
                _ColorPicker_.erase_preset(_Color)

    _CustomSwatch_.clear()


func _on_swatch_item_clicked(
    index_ :int, _position_ :Vector2, mouse_button_ :int, swatch_ :ItemList,
) -> void:
    if mouse_button_ != MOUSE_BUTTON_RIGHT: return
    var _color_ :String = swatch_.get_item_text(index_)
    DisplayServer.clipboard_set(_color_)


func _on_import_colors_pressed() -> void:
    AppState.file_dialog_state = GE.File_Dialog.IMPORT

    _FileDialog_.access = FileDialog.ACCESS_FILESYSTEM
    _FileDialog_.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    _FileDialog_.current_path = AppState.app_data.recent_import_palette
    _FileDialog_.popup_centered()


func _on_export_colors_pressed() -> void:
    AppState.file_dialog_state = GE.File_Dialog.EXPORT

    _FileDialog_.access = FileDialog.ACCESS_FILESYSTEM
    _FileDialog_.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    _FileDialog_.current_path = AppState.app_data.recent_import_palette
    _FileDialog_.popup_centered()
