extends Control


signal import_palette()


func _enter_tree() -> void:
    AppState.initialize()


func _ready() -> void:
    __setup_dependencies()

    tree_exited.connect(_on_tree_exited)

    Colorist.update_colors(theme, AppState.app_data)
    if AppState.app_data.recent_import_palette != "":
        import_palette.emit(AppState.app_data.recent_import_palette)


func __setup_dependencies() -> void:
    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:import_palette")


func _on_tree_exited() -> void:
    AppState.save_settings(GC.SETTINGS_PATH, AppState.app_data)
