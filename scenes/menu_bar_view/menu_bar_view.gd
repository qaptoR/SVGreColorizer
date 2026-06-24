class_name MenuBarView
extends Control


@export var color_icon__ :Texture

@onready var _ColorOptions_ :OptionButton = %ColorOptions
@onready var _DirButton_ :Button = %DirButton
@onready var _DirPathLabel_ :Label = %DirPathLabel
@onready var _MenuButton_ :MenuButton = %MenuButton
@onready var _SettingsMenu_ :PopupMenu = _MenuButton_.get_popup()

var _ColorMenu_ :ColorMenu
var _SaveImageDialog_ :SaveImageDialog
var _SwatchView_ :SwatchView
var _Queue_ :ItemList
var _TreeView_ :TreeView
var _FileDialog_ :FileDialog


func _ready() -> void:
    __setup_dependencies()
    __setup_settings_menu()

    _SettingsMenu_.id_pressed.connect(_on_settings_menu_id_pressed)
    _ColorOptions_.item_selected.connect(_on_color_options_item_selected)
    _DirButton_.pressed.connect(_on_dir_button_pressed)


func __setup_dependencies() -> void:
    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal("sig:parse_icon_directory", "parse_icon_directory", parse_icon_directory)

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("DirPathLabel", _DirPathLabel_)
    _gloc_.register("SettingsMenu", _SettingsMenu_)
    _gloc_.register("ColorOptions", _ColorOptions_)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("ColorMenu", func(service): _ColorMenu_ = service)
    _loc_.connect_service_found("SaveImageDialog", func(service): _SaveImageDialog_ = service)
    _loc_.connect_service_found("Queue", func(service): _Queue_ = service)
    _loc_.connect_service_found("TreeView", func(service): _TreeView_ = service)
    _loc_.connect_service_found("SwatchView", func(service): _SwatchView_ = service)
    _loc_.connect_service_found("FileDialog", func(service): _FileDialog_ = service)


func __setup_settings_menu() -> void:
    _SettingsMenu_.hide_on_checkable_item_selection = false

    _SettingsMenu_.add_separator('Dialogs')
    _SettingsMenu_.add_item('Change Colors', GE.MenuId.COLORS)
    _SettingsMenu_.add_item('Save Preview', GE.MenuId.IMAGE)

    _SettingsMenu_.add_separator('Defaults')
    _SettingsMenu_.add_item('Set Currenet Directory as Default', GE.MenuId.DIRECTORY)
    _SettingsMenu_.add_item('Clear Recent Color Palette', GE.MenuId.CLEAR_PALETTE)

    _SettingsMenu_.add_separator('Toggles')
    _SettingsMenu_.add_check_item('Confirm on Commit', GE.MenuId.CONFIRM)
    _SettingsMenu_.set_item_checked(
        _SettingsMenu_.get_item_index(GE.MenuId.CONFIRM),
        AppState.app_data.confirm_commit,
    )

    _SettingsMenu_.add_separator('Logs')
    _SettingsMenu_.add_item('View Logs', GE.MenuId.LOGS)
    _SettingsMenu_.add_item('View Batch Logs', GE.MenuId.BATCH_LOGS)
    _SettingsMenu_.add_item('Commit Batch Logs', GE.MenuId.COMMIT_BATCH_LOGS)
    _SettingsMenu_.add_item('Clear All Logs', GE.MenuId.CLEAR_LOGS)
    _SettingsMenu_.add_item('Overwrite Logs to File', GE.MenuId.OVERWRITE_LOGS)
    _SettingsMenu_.add_item('Append Logs to File', GE.MenuId.APPEND_LOGS)

    _SettingsMenu_.add_separator('Application')
    _SettingsMenu_.add_item('Quit', GE.MenuId.QUIT_PROGRAM)


func parse_icon_directory(dir_ :String, selected_ :bool = true) -> void:
    if selected_: _DirPathLabel_.text = dir_
    if not DirAccess.dir_exists_absolute(_DirPathLabel_.text): return

    ParserData.clear_data()
    AppState.current_preview_changed_list.clear()

    ParserData.refresh_svg_files(dir_)
    if ParserData.icon_list.is_empty(): return

    ParserData.parse_svg_colors()
    update_color_options(ParserData.color_set)
    _SwatchView_.update_current_colors(ParserData.color_set.keys())
    _Queue_.clear()

    var colorGroup = _ColorOptions_.get_selected_metadata()
    if colorGroup == null: return
    _TreeView_.update_tree_view(
        ParserData.icon_coll, ParserData.icon_list, colorGroup, _DirPathLabel_.text,
    )


func update_color_options(set_ :Dictionary):
    _ColorOptions_.clear()

    for _Color in set_.keys():
        var _id_ = _ColorOptions_.get_item_count()
        _ColorOptions_.add_icon_item(
            Colorist.create_colored_icon(color_icon__, _Color.to_html()), ' %s' %set_[_Color].size()
        )
        _ColorOptions_.set_item_metadata(_id_, {'color': _Color, 'icons': set_[_Color]} )


func _on_dir_button_pressed() -> void:
    AppState.file_dialog_state = GE.File_Dialog.PARSE

    _FileDialog_.access = FileDialog.ACCESS_FILESYSTEM
    _FileDialog_.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    _FileDialog_.current_path = AppState.app_data.default_directory
    _FileDialog_.popup_centered()


func _on_color_options_item_selected(_index_ :int) -> void:
    var colorGroup :Dictionary = _ColorOptions_.get_selected_metadata()

    _Queue_.clear()
    AppState.current_preview_changed_list.clear()
    _TreeView_.update_tree_view(
        ParserData.icon_coll,
        ParserData.icon_list,
        colorGroup,
        _DirPathLabel_.text,
    )


func _on_settings_menu_id_pressed(id_ :int) -> void:
    match id_:
        GE.MenuId.QUIT_PROGRAM: get_tree().quit()

        GE.MenuId.COLORS: __show_color_menu_popup()
        GE.MenuId.IMAGE: __show_save_image_dialog()

        GE.MenuId.DIRECTORY: __save_default_directory_setting()
        GE.MenuId.CLEAR_PALETTE: AppState.app_data.recent_import_palette = ''

        GE.MenuId.CONFIRM:
            _SettingsMenu_.toggle_item_checked(_SettingsMenu_.get_item_index(GE.MenuId.CONFIRM))
            AppState.app_data.confirm_commit = _SettingsMenu_.is_item_checked(
                _SettingsMenu_.get_item_index(GE.MenuId.CONFIRM)
            )

        GE.MenuId.LOGS:
            MessageViewer.show_batch_message(MessageLogger.get_display_text())
        GE.MenuId.BATCH_LOGS:
            MessageViewer.show_batch_message(MessageLogger.get_display_text(MessageLogger.BATCH))
        GE.MenuId.COMMIT_BATCH_LOGS: MessageLogger.commit(MessageLogger.CLEAR)
        GE.MenuId.CLEAR_LOGS:
            MessageLogger.clear()
            MessageLogger.clear(MessageLogger.BATCH)
        GE.MenuId.OVERWRITE_LOGS: MessageLogger.flush_messages_to_file()
        GE.MenuId.APPEND_LOGS: MessageLogger.append_messages_to_file()



func __show_color_menu_popup():
    for _Button in ['preview', 'theme', 'accent', 'font']:
        _ColorMenu_.buttons['%s' %_Button].icon = Colorist.create_colored_icon(
            color_icon__,
            AppState.app_data.color_state['%s_color' %_Button]
        )

    _ColorMenu_.popup_centered()


func __show_save_image_dialog():
    AppState.save_image_dialogue_state = GE.SaveImageDialogue.PREVIEW
    _SaveImageDialog_.title = 'Save Image Preview'
    _SaveImageDialog_.popup_centered()


func __save_default_directory_setting():
    if not DirAccess.dir_exists_absolute(_DirPathLabel_.text): return
    AppState.app_data.default_directory = _DirPathLabel_.text + '/'
    AppState.save_settings(GC.SETTINGS_PATH, AppState.app_data)
