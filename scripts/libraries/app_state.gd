class_name AppState
extends Object


const ATTR_STRING :String = r"((?i:%s)\s*=\s*[\"']\s*).*?([\"'])"
const CSS_STRING :String = r"((?i:%s)\s*:\s*).*?([\"';])"

static var current_color_button :Dictionary

static var color_picker_state :int
static var file_dialog_state :int
static var save_image_dialogue_state :int

static var current_preview_item :Dictionary
static var current_preview_changed_list :Dictionary[TreeItem, Dictionary]

static var app_data :AppData


static func initialize() -> void:
    app_data = load_settings(GC.SETTINGS_PATH)
    if app_data == null: 
        MessageLogger.warn(
            'Failed to load user settings. Generating defaults',
            'app_state.gd'
        )
        generate_user_settings()


static func generate_user_settings() -> void:
    app_data = AppData.new()
    app_data.default_directory = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + '/'
    save_settings(GC.SETTINGS_PATH, app_data)


#TODO: this function should not be in AppState
static func use_preview_data(
    text_: String, icon_ :TreeItem,
    commit_list_ :Dictionary[TreeItem, Array] = {}
) -> String:
    var _icon_data_ :Dictionary = icon_.get_meta(GC.META_DATA)
    var _regex_cache_: Dictionary = {}
    var _edits_: Array = [] # [start, end, replacement]

    if current_preview_changed_list.has(icon_): for _item_ in current_preview_changed_list[icon_].keys():
        if not commit_list_.is_empty() and not commit_list_[icon_].has(_item_): continue
        for _Attribute in ['color', 'opacity']:
            var _data_ :Dictionary = _item_.get_meta(GC.META_DATA)
            if not _data_.has(_Attribute): continue
            if _icon_data_.to_commit and !_data_.is_queued: continue

            var _attr_data_ = _data_[_Attribute]
            var _pattern_ :String = (CSS_STRING if _attr_data_.css else ATTR_STRING) %_attr_data_.attribute
            var _regex_: RegEx = _regex_cache_.get(_pattern_)
            if _regex_ == null:
                _regex_ = RegEx.new()
                _regex_.compile(_pattern_)
                _regex_cache_[_pattern_] = _regex_

            var _match_ := _regex_.search(text_, _data_.offset)
            if _match_ == null: continue

            var _is_color_: bool = _Attribute == 'color'
            var _insert_value_: String = ('#' + _attr_data_.new.to_html(_attr_data_.alpha)) \
                if _is_color_ else str(_attr_data_.new)
            var _diff_ :int = _insert_value_.length() - _attr_data_.value.length()
            _edits_.append([_match_.get_end(1), _match_.get_start(2), _insert_value_])

    _edits_.sort_custom(func(a, b): return a[0] < b[0])

    var _parts_: PackedStringArray = []
    var _cursor_ := 0
    for _E in _edits_:
        _parts_.append(text_.substr(_cursor_, _E[0] - _cursor_))
        _parts_.append(_E[2])
        _cursor_ = _E[1]
    _parts_.append(text_.substr(_cursor_))

    return "".join(_parts_)


static func load_settings(file_path_ :String) -> AppData:
    var _config_ := ConfigFile.new()
    var _err_ :int = _config_.load(file_path_)
    if _err_ != OK: MessageLogger.error(
        "Failed to load settings from '%s', error code: %s"
        %[file_path_, error_string(_err_)],
        'app_state.gd'
    ); return null

    var _app_data_ := AppData.new()
    for _Section in _config_.get_sections(): for _Key in _config_.get_section_keys(_Section):
        _app_data_.set(_Key, _config_.get_value(_Section, _Key))

    return _app_data_


static func save_settings(_file_path_ :String, app_data_ :AppData):
    var _config_ := ConfigFile.new()
    _config_.set_value('Visual', 'color_state', app_data_.color_state)
    _config_.set_value('Visual', 'color_picker_shape', app_data_.color_picker_shape)

    _config_.set_value('Config', 'confirm_commit', app_data_.confirm_commit)

    _config_.set_value('FileDialog', 'default_directory', app_data_.default_directory)
    _config_.set_value('FileDialog', 'favorite_directories', app_data_.favorite_directories)
    _config_.set_value('FileDialog', 'recent_import_palette', app_data.recent_import_palette)

    var _result_ :int = _config_.save(GC.SETTINGS_PATH)
    assert(_result_ == OK)
