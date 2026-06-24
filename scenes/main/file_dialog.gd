extends FileDialog


signal parse_icon_directory(dir_path :String)
signal verify_save_image_options()
signal import_palette(file_path :String)
signal export_palette(file_path :String)

var _DirectoryLabel_ :Label


func _ready() -> void:
    __setup_dependencies()

    dir_selected.connect(_on_dir_selected)
    file_selected.connect(_on_file_selected)
    close_requested.connect(_save_favourite_directories)
    focus_exited.connect(_save_favourite_directories)

    set_favorite_list(AppState.app_data.favorite_directories)


func __setup_dependencies() -> void:
    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:parse_icon_directory")
    _conn_.register("sig:verify_save_image_options")
    _conn_.register("sig:import_palette")
    _conn_.register("sig:export_palette")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("FileDialog", self)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("DirectoryLabel", func(service): _DirectoryLabel_ = service)


func _on_dir_selected(dir_path_ :String) -> void:
    _save_favourite_directories()
    match AppState.file_dialog_state:
        GE.File_Dialog.PARSE: parse_icon_directory.emit(dir_path_)
        GE.File_Dialog.SAVE:
            _DirectoryLabel_.text = dir_path_
            verify_save_image_options.emit()
        _: return


func _on_file_selected(file_path_ :String) -> void:
    _save_favourite_directories()
    match AppState.file_dialog_state:
        GE.File_Dialog.IMPORT: import_palette.emit(file_path_)
        GE.File_Dialog.EXPORT: export_palette.emit(file_path_)
        _: return


func _save_favourite_directories() -> void:
    var _dirs_ :PackedStringArray = get_favorite_list()
    AppState.app_data.favorite_directories = _dirs_
