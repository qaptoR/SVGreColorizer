class_name Colorist
extends Object


static var theme_list :Dictionary = {
    'bg_color': {
        'ItemList': ['+', 'panel'],
        'Tree': ['-', 'selected', 'selected_focus'],
        'Panel': [],
        'Button': ['-', 'disabled', 'focus'],
        'MenuButton': [],
        'Window': [],
        'OptionButton': [],
    },
    'border_color': {
        'Window': []
    },
}

static var accent_list :Dictionary = {
    'bg_color': {
        'ItemList': ['+', 'focus'],
        'Window': [],
        'PopupPanel': [],
        'Button': ['+', 'disabled', 'focus'],
    }
}

static var preview_frame_references :Array = []


static func create_colored_icon(texture_ :Texture2D, color_ :String):
    var _new_image_ :Image = texture_.get_image()
    _new_image_.fill(color_)

    return ImageTexture.create_from_image(_new_image_)


static func get_icon_texture(path_ :String) -> ImageTexture:
    var _new_image_ := Image.new()
    if _new_image_.load(path_):
        MessageLogger.error('Error loading icon image', 'colorist.gd')
        return ImageTexture.new()

    var _size_ = _new_image_.get_size()
    if _size_ != Vector2i(16, 16):
        var smaller = _size_.x if (_size_.x < _size_.y) else _size_.y
        _new_image_ = _new_image_.get_region(Rect2(0, 0, smaller, smaller))
        _new_image_.resize(16, 16, Image.INTERPOLATE_NEAREST)

    return ImageTexture.create_from_image(_new_image_)


static func update_colors(theme_ :Theme, app_data_ :AppData) -> void:
    update_preview_color(app_data_)
    update_font_color(theme_, Color(app_data_.color_state['font_color']))
    update_theme_color(theme_, Color(app_data_.color_state['theme_color']))
    update_accent_color(theme_, Color(app_data_.color_state['accent_color']))


static func update_font_color (theme_ :Theme, color_ :Color):
    var _types_ = theme_.get_theme_item_type_list(Theme.DATA_TYPE_COLOR)
    for _Type in _types_:
        var _items_ = theme_.get_theme_item_list(Theme.DATA_TYPE_COLOR, _Type)
        for _Name in _items_:
            theme_.set_color(_Name, _Type, color_)


static func update_preview_color(app_data_ :AppData) -> void:
    for _Preview in preview_frame_references:
        _Preview.color = app_data_.color_state.preview_color


static func update_theme_color(theme_ :Theme, color_ :Color) -> void:
    __update_theme_color(theme_, color_, theme_list)


static func update_accent_color(theme_ :Theme, color_ :Color) -> void:
    __update_theme_color(theme_, color_, accent_list)


static func __update_theme_color(theme_ :Theme, color_ :Color, list_ :Dictionary) -> void:
    for _Property in list_:
        for _Type in list_[_Property]:

            var _styleboxes_ = theme_.get_stylebox_list(_Type)
            var _opt_arr_ :Array = list_[_Property][_Type]
            var _used_ :Array = []
            if not _opt_arr_.is_empty(): match _opt_arr_[0]:
                '+': for _Name in _styleboxes_: if _Name in _opt_arr_: _used_.append(_Name)
                '-': for _Name in _styleboxes_: if not _Name in _opt_arr_: _used_.append(_Name)
            else: _used_.append_array(_styleboxes_)

            for _Name in _used_:
                var stylebox = theme_.get_stylebox(_Name, _Type)
                if not stylebox is StyleBoxFlat: continue
                stylebox[_Property] = color_
