class_name Colorist
extends Object


static var theme_list :Dictionary = {
    'bg_color': {
        'ItemList': ['+', 'panel'],
        'Tree': ['-', 'selected', 'selected_focus'],
        'Panel': [],
        'PanelContainer': [],
        'Button': ['-', 'disabled', 'focus'],
        'MenuButton': [],
        # 'Window': [],
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


static func sort_color_list(color_list_ :Array) -> Array:
    color_list_.sort_custom(func(a: Color, b: Color):
        var _a_g_ = a.s < 0.1; var _b_g_ = b.s < 0.1
        if _a_g_ != _b_g_: return _b_g_ # if one is gray, the other is not, gray goes last
        if _a_g_ and _b_g_: return a.v < b.v # if both are gray, sort by value only

        if not is_equal_approx(a.h, b.h):
            return a.h < b.h
        return a.v < b.v
    )
    return color_list_


static func hsl_to_color(h: float, s: float, l: float, a: float = 1.0) -> Color:
    h = clamp(h, 0.0, 360.0)
    s = clamp(s, 0.0, 1.0)
    l = clamp(l, 0.0, 1.0)
    var ap :float = s * min(l, 1.0 - l)
    var f :Callable = func(n :float) -> float:
        var k :float = fmod(n + (h / 30.0), 12.0)
        return l - ap * max(-1.0, min(k - 3.0, 9.0 - k, 1.0))
    return Color(f.call(0.0), f.call(8.0), f.call(4.0), a)


static func color_to_hsl(color_ :Color) -> Dictionary:
    var r :float = color_.r
    var g :float = color_.g
    var b :float = color_.b
    var a :float = color_.a

    var max_val :float = max(r, g, b)
    var min_val :float = min(r, g, b)
    var h :float = 0.0
    var s :float = 0.0
    var l :float = (max_val + min_val) / 2.0

    var c :float = max_val - min_val
    if c > 0.0: match max_val:
        r: h = 60.0 * fmod(((g - b) / c), 6.0)
        g: h = 60.0 * (((b - r) / c) + 2.0)
        b: h = 60.0 * (((r - g) / c) + 4.0)

    if 0.0 < l and l < 1.0: s = c / (1.0 - abs(2.0 * l - 1.0))

    return {'h': h, 's': s, 'l': l, 'a': a}


static func color_to_str(
    color_ :Color,
    inc_alpha_ :bool = false,
    format_ :int = GE.ColorFormat.HEX
) -> String:
    match format_:
        GE.ColorFormat.HEX:
            return '#' + color_.to_html(inc_alpha_)
        GE.ColorFormat.RGB_INT:
            return "rgb%s(%d, %d, %d%s)" % [
                'a' if inc_alpha_ else "",
                int(color_.r * 255.0),
                int(color_.g * 255.0),
                int(color_.b * 255.0),
                ", %.2f" %color_.a if inc_alpha_ else ""
            ]
        GE.ColorFormat.RGB_PERC:
            return "rgb%s(%.1f%%, %.1f%%, %.1f%%%s)" % [
                'a' if inc_alpha_ else "",
                color_.r * 100.0,
                color_.g * 100.0,
                color_.b * 100.0,
                ", %.2f" %color_.a if inc_alpha_ else ""
            ]
        GE.ColorFormat.HSL:
            var _hsl_ = color_to_hsl(color_)
            return "hsl%s(%.1f, %.1f%%, %.1f%%%s)" % [
                'a' if inc_alpha_ else "",
                _hsl_.h,
                _hsl_.s * 100.0,
                _hsl_.l * 100.0,
                ", %.2f" %_hsl_.a if inc_alpha_ else ""
            ]
        GE.ColorFormat.KEYWORD:
            var _str_ = GC.COLOR_KEYWORDS.find_key('#' + color_.to_html(false))
            if _str_ == null: _str_ = '#' + color_.to_html(inc_alpha_)
            return _str_
        _: return "none"




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
