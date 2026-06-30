class_name SaveImageDialog
extends Window


@onready var _SvgButton_ :CheckBox = %ImageOptions/Svg
@onready var _PngButton_ :CheckBox = %ImageOptions/Png
@onready var _LineEdit_ :LineEdit = %Suffix/LineEdit
@onready var _ScaleOptionLabel_ :Label = %ScaleOption/Label
@onready var _Slider_ :HSlider = %ScaleOption/HSlider
@onready var _DirectoryButton_ :Button = %Directory/Button
@onready var _DirectoryLabel_ :Label = %Directory/Label
@onready var _SaveButton_ :Button = %Buttons/Save
@onready var _CancelButton_ :Button = %Buttons/Cancel

var _FileDialog_ :FileDialog
var _DirPathLabel_ :Label


func _ready() -> void:
    __setup_dependencies()

    _DirectoryButton_.pressed.connect(_on_directory_button_pressed)
    _SaveButton_.pressed.connect(_on_save_button_pressed)
    _CancelButton_.pressed.connect(hide)
    _SvgButton_.pressed.connect(verify_save_image_options)
    _PngButton_.pressed.connect(verify_save_image_options)
    _Slider_.value_changed.connect(_on_slider_value_changed)
    close_requested.connect(hide)

    _ScaleOptionLabel_.text = "Scale:  %.f" %_Slider_.value


func __setup_dependencies() -> void:
    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal(
        "sig:verify_save_image_options",
        "verify_save_image_options",
        verify_save_image_options
    )

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("SaveImageDialog", self)
    _gloc_.register("DirectoryLabel", _DirectoryLabel_)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("FileDialog", func(service): _FileDialog_ = service)
    _loc_.connect_service_found("DirPathLabel", func(service): _DirPathLabel_ = service)


func verify_save_image_options() -> void:
    _SaveButton_.disabled = true

    if !DirAccess.dir_exists_absolute(_DirectoryLabel_.text): return
    if not (_SvgButton_.button_pressed or _PngButton_.button_pressed): return

    _SaveButton_.disabled = false


func _on_directory_button_pressed() -> void:
    AppState.file_dialog_state = GE.File_Dialog.SAVE

    _FileDialog_.access = FileDialog.ACCESS_FILESYSTEM
    _FileDialog_.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    _FileDialog_.current_path = _DirPathLabel_.text + '/'
    _FileDialog_.popup_centered()


func _on_slider_value_changed(value_ :float) -> void:
    _ScaleOptionLabel_.text = "Scale:  %.f" %value_


func _on_save_button_pressed() -> void:
    if !DirAccess.dir_exists_absolute(_DirectoryLabel_.text):
        MessageViewer.show_immediate_message("%s is not a valid directory path" %_DirectoryLabel_.text)
        return

    # INFO: deprecated because verify_save_image_options() disables the save button if neither option is selected
    # and is called even after the directory is set
    # if !(_SvgButton_.button_pressed or _PngButton_.button_pressed):
    #     MessageViewer.show_immediate_message("Save As: SVG and/or PNG must be selected")
    #     return

    if AppState.current_preview_item.is_empty():
        MessageViewer.show_immediate_message("No preview item found")
        return

    var _filename_ = AppState.current_preview_item.path.get_file()
    var suffix = _LineEdit_.placeholder_text if _LineEdit_.text.is_empty() else _LineEdit_.text
    # _filename_ = _filename_.left(_filename_.rfind('.'))
    var _new_filename_ = _filename_.get_basename() + suffix

    var _read_file_ = FileAccess.open(AppState.current_preview_item.path, FileAccess.READ)
    if _read_file_ == null:
        MessageViewer.show_immediate_message(
            'file %s could not be opened' %AppState.current_preview_item.path.get_file()
        )
        return

    var _svgtext_ = _read_file_.get_as_text() 
    _read_file_.close()

    _svgtext_ = AppState.use_preview_data(_svgtext_, AppState.current_preview_item.data)

    MessageLogger.clear(MessageLogger.BATCH)
    var _saved_files_ = []
    if _SvgButton_.button_pressed:
        var _svg_filename_ = _new_filename_ + '.svg'
        _saved_files_.append(_svg_filename_)
        var _write_file_ = FileAccess.open(_DirectoryLabel_.text.path_join(_svg_filename_), FileAccess.WRITE)
        if _write_file_ == null:
            MessageLogger.error(
                "File %s did not open for saving" %_svg_filename_,
                get_script().resource_path.get_file(), MessageLogger.BATCH
            ); _saved_files_.erase(_svg_filename_)
        _write_file_.store_string(_svgtext_)

    if _PngButton_.button_pressed:
        var _new_image_ :Image = SvgLoader.load_from_string(_svgtext_, _Slider_.value)
        if _new_image_ == null:
            MessageLogger.error(
                'Failed to load image from updated svg file',
                get_script().resource_path.get_file(), MessageLogger.BATCH
            )
            return

        var _png_filename_ = _new_filename_ + '.png'
        _saved_files_.append(_png_filename_)
        if _new_image_.save_png(_DirectoryLabel_.text.path_join(_png_filename_)):
            MessageLogger.error(
                "File %s did not save" %_png_filename_,
                get_script().resource_path.get_file()
            ); _saved_files_.erase(_png_filename_)

    if not MessageLogger.is_empty(MessageLogger.BATCH):
        MessageViewer.show_batch_message(MessageLogger.get_display_text(MessageLogger.BATCH))
        return

    hide()
    var _saved_files_str_ = ("%s" if _saved_files_.size() == 1 else "%s\nand %s")
    MessageViewer.show_immediate_message(
        "Successfully saved %s to\n%s as: \n%s" % [
        _filename_, _DirectoryLabel_.text,
        _saved_files_str_ % _saved_files_
    ])

