class_name Previews
extends Control


const BASE_PREVIEW_SIZE := Vector2(300, 300)
const MAX_OUTPUT_PX :float = 16_384.0

@onready var _OldState_ :ColorRect = %OldState
@onready var _NewState_ :ColorRect = %NewState
@onready var _ScaleLabel_ :Label = %ScaleLabel
@onready var _ScaleSlider_ :HSlider = %ScaleSlider

var _TreeView_ :TreeView
var _DirPathLabel_ :Label


func _ready() -> void:
    __setup_dependencies()

    _ScaleSlider_.value_changed.connect(_on_scale_slider_value_changed)
    _ScaleLabel_.gui_input.connect(_on_scale_label_gui_input)

    for _State in [_OldState_, _NewState_]:
        Colorist.preview_frame_references.append(_State)

    Colorist.update_preview_color(AppState.app_data)


func __setup_dependencies() -> void:
    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal("sig:preview_image", "preview_image", preview_image)
    _gcon_.connect_signal("sig:clear_previews", "clear_previews", clear_previews)

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("ScaleLabel", _ScaleLabel_)
    _gloc_.register("ScaleSlider", _ScaleSlider_)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("TreeView", func(service): _TreeView_ = service)
    _loc_.connect_service_found("DirPathLabel", func(service): _DirPathLabel_ = service)


func clear_previews() -> void:
    for _Frame in [_OldState_, _NewState_]: for _View :TextureRect in _Frame.get_children():
        _View.texture = null


func preview_image(file_path_ :String, preview_data_ :TreeItem) -> void:
    var _file_ = FileAccess.open(file_path_, FileAccess.READ)
    if _file_ == null:
        MessageViewer.show_immediate_message('file %s could not be opened' %file_path_.get_file())
        return

    var _scale_factor_ :float = __get_scale_factor(file_path_)

    var _svgtext_ = _file_.get_as_text()
    _file_.close()
    __update_views(_svgtext_, _OldState_, _scale_factor_)

    # intermediary reColorizing step
    _svgtext_ = AppState.use_preview_data(_svgtext_, preview_data_)
    __update_views(_svgtext_, _NewState_, _scale_factor_)


func __get_scale_factor(file_path_ :String) -> float:
    var _xml_ := XMLParser.new()
    if _xml_.open(file_path_) != OK:
        MessageLogger.error(
            'Failed to open XML parser for file %s' %file_path_.get_file(),
            get_script().resource_path.get_file()
        )
        return 1.0

    var _number_regex_ = RegEx.new()
    _number_regex_.compile(r"([0-9\.]+)")
    var flag :bool = false
    while _xml_.read() == OK:
        var _node_name_ = _xml_.get_node_name().to_lower()
        if _node_name_ == 'svg': flag = true; break

    if not flag:
        MessageLogger.error(
            'No <svg> tag found in file %s' %file_path_.get_file(),
            get_script().resource_path.get_file()
        )
        return 1.0

    var _width_ = _xml_.get_named_attribute_value_safe('width')
    var _height_ = _xml_.get_named_attribute_value_safe('height')
    var viewbox = _xml_.get_named_attribute_value_safe('viewbox')
    if _width_ == "": _width_ = "100%"
    if _height_ == "": _height_ = "100%"

    var clarity :float = _ScaleSlider_.value

    var _w_ :float = _width_.replace('%', '').to_float()
    var _h_ :float = _height_.replace('%', '').to_float()

    var _matches_ = _number_regex_.search_all(viewbox)
    if _matches_.size() == 4:
        if _width_.contains('%'): _w_ = _matches_[2].get_string(1).to_float() * (_w_ / 100.0)
        if _height_.contains('%'): _h_ = _matches_[3].get_string(1).to_float() * (_h_ / 100.0)

    var _target_px_ :float = BASE_PREVIEW_SIZE.x * pow(2.0, clarity)
    var _scale_ :float = _target_px_ / max(_w_, _h_)
    var _output_px_ :float = max(_w_, _h_) * _scale_
    if _output_px_ > MAX_OUTPUT_PX: _scale_ *= MAX_OUTPUT_PX / _output_px_
    return _scale_


func __update_views (svg_ :String, frame_ :ColorRect, scale_ :float) -> void:
    var _image_ := Image.new()
    if _image_.load_svg_from_string(svg_, scale_):
        MessageLogger.error(
            'Failed to load image from string:\n%s' %svg_,
            get_script().resource_path.get_file()
        )
        return

    for _View :TextureRect in frame_.get_children():
        _image_.resize(int(_View.size.x), int(_View.size.y), Image.INTERPOLATE_NEAREST) # Image.INTERPOLATE_LANCZOS
        _View.texture = ImageTexture.create_from_image(_image_)


func _on_scale_slider_value_changed(value_ :float) -> void:
    _ScaleLabel_.text = "Scale: %.1f" %value_
    var _item_ = _TreeView_.Tree_.get_selected()
    if _item_ == null: return
    preview_image('%s/%s' %[_DirPathLabel_.text, _item_.get_text(GC.ICON_NAME_COL)], _item_)


func _on_scale_label_gui_input(event_ :InputEvent) -> void:
    if event_ is InputEventMouseButton \
    and event_.button_index == MOUSE_BUTTON_LEFT\
    and event_.pressed:
        _ScaleSlider_.value = 0.0
