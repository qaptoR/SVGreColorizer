class_name ParserData
extends Object


static var icon_coll :Dictionary = {}
static var color_set :Dictionary = {}

static var icon_dir :String = ''
static var icon_list :Array = []

static var _css_block_regex :RegEx
static var _css_prop_regex :RegEx
static var _number_regex :RegEx
static var _nonvalue_regexes :Array[RegEx] = []
static var _previous_node_name :String = ''


static func clear_data () -> void:
    icon_coll.clear()
    color_set.clear()
    icon_list.clear()


static func get_preview_data(item_ :TreeItem, _to_commit_ :bool = false) -> TreeItem:
    #TODO: eliminate the need for this function, it is a wasted call
    item_.get_meta(GC.META_DATA)['to_commit'] = _to_commit_
    return item_


static func refresh_svg_files(path_ :String) -> void:
    icon_dir = path_
    icon_list.clear()

    var _dir_ = DirAccess.open(path_)
    if _dir_ == null:
        MessageLogger.error(
            'failure opening directory %s to refresh icon files' %path_,
            'parser_data.gd'
        )
        return

    _dir_.list_dir_begin()
    var _icon_file_ = _dir_.get_next()
    while _icon_file_ != "":
        if _dir_.current_is_dir():
            _icon_file_ = _dir_.get_next()
            continue

        if _icon_file_.get_extension() == 'svg': icon_list.append(_icon_file_)
        _icon_file_ = _dir_.get_next()

    _dir_.list_dir_end()


static func parse_svg_colors() -> void:
    __init_regexes()

    for _I in icon_list.size():
    # use index for looping to track color groups

        var _icon_name_ = icon_list[_I]
        var _xml_ = __get_icon_parser('%s/%s' %[icon_dir, _icon_name_])
        if !_xml_: continue
        icon_coll[_icon_name_] = {}

        var _N :int = 0
        while !_xml_.read():
            __read_icon_xml(_xml_, _icon_name_, _I, _N)
            var _node_type_ :int = _xml_.get_node_type()
            _previous_node_name = "" if _node_type_ == XMLParser.NODE_TEXT else _xml_.get_node_name().to_lower()
            _N += 1


static func __init_regexes() -> void:
    if _css_prop_regex != null: return

    _css_block_regex = RegEx.new()
    _css_block_regex.compile(r"([^{}\s][^{}]*)\s*\{\s*([^{}]*)\s*\}")

    var first_group = '|'.join(GC.COLOR_VALUES)
    _css_prop_regex = RegEx.new()
    _css_prop_regex.compile(r"\b(%s)\s*:\s*([^;\"}]+)" % first_group)

    _number_regex = RegEx.new()
    _number_regex.compile(r"([0-9\.]+)(%?)")

    for pattern in GC.COLOR_NONVALUES:
        var rx = RegEx.new()
        rx.compile(pattern)
        _nonvalue_regexes.append(rx)


static func __get_icon_parser (path_ :String) -> XMLParser:
     var _xml_ := XMLParser.new()
     if _xml_.open(path_):
         MessageLogger.error('could not open file %s for svg parsing' %path_, 'parser_data.gd')
         return null

     return _xml_


static func __read_icon_xml (xml_ :XMLParser, icon_name_ :String, i_ :int, _N :int) -> void:
    var _node_type_ :int = xml_.get_node_type()
    var _node_name_ :String = "" if _node_type_ == XMLParser.NODE_TEXT else xml_.get_node_name()
    var _node_offset_ :int = xml_.get_node_offset()

    if _previous_node_name == 'style' and _node_type_ == XMLParser.NODE_TEXT:
        var _text_content_ = xml_.get_node_data()
        _parse_css_blocks(_text_content_, _node_offset_, icon_name_, i_, _N)
        return

    if _node_type_ != XMLParser.NODE_ELEMENT: return

    for attr_idx in range(xml_.get_attribute_count()):
        var _attribute_ :String = xml_.get_attribute_name(attr_idx).to_lower()
        var _raw_value_ :String = xml_.get_attribute_value(attr_idx).to_lower()

        if _attribute_ == "style":
            _parse_css_properties(_raw_value_, _node_offset_, icon_name_, i_, _N, 'style')

        elif _attribute_ in GC.COLOR_VALUES:
            _register_value(_raw_value_.strip_edges(), _attribute_, _node_offset_, icon_name_, i_, _N)


static func _parse_css_blocks(
    css_string_ :String,
    node_offset_ :int,
    icon_name_ :String,
    i_ :int,
    n_ :int,
) -> void:
    var _matches_ = _css_block_regex.search_all(css_string_.to_lower())
    for _M in _matches_:
        var _selector_ = _M.get_string(1).strip_edges()
        var _selector_offset_ = _M.get_start(1) + node_offset_
        var _properties_ = _M.get_string(2).strip_edges()
        _parse_css_properties(_properties_, _selector_offset_, icon_name_, i_, n_, "css___" + _selector_)


static func _parse_css_properties(
    css_string_ :String,
    node_offset_ :int,
    icon_name_ :String,
    i_ :int,
    n_ :int,
    prefix_ :String,
) -> void:
    var _matches_ = _css_prop_regex.search_all(css_string_.to_lower())
    for _M in _matches_:
        var _prop_ = _M.get_string(1)
        var _color_val_ = _M.get_string(2).strip_edges()

        var _pseudo_attribute_ = "%s:::%s" %[prefix_, _prop_]
        _register_value(_color_val_, _pseudo_attribute_, node_offset_, icon_name_, i_, n_)


static func _register_value(
    value_string_ :String,
    attribute_ :String,
    node_offset_ :int,
    icon_name_ :String,
    i_ :int,
    n_ :int
) -> void:
    if value_string_.is_empty(): return
    for rx in _nonvalue_regexes: if rx.search(value_string_): return

    if !icon_coll.has(icon_name_):
        icon_coll[icon_name_] = {}

    if !icon_coll[icon_name_].has(node_offset_):
        icon_coll[icon_name_][node_offset_] = {}

    var _attribute_ :String = attribute_.get_slice(':::', 1)
    var _is_css_ :bool = attribute_.begins_with('css') or attribute_.begins_with('style')

    var _parsed_value_
    if _attribute_ in GC.COLOR_ATTR: _parsed_value_ = __get_color_value(value_string_)
    elif _attribute_ in GC.OPACITY_ATTR: _parsed_value_ = __get_float_value(value_string_)
    else: return

    var _stored_value_ :Dictionary = {
        'attribute': _attribute_,
        'string': value_string_,
        'value': _parsed_value_.value,
        'css': _is_css_,
        'node_id': n_,
    }

    if _attribute_ in GC.COLOR_ATTR:
        if !color_set.has(_parsed_value_.value): color_set[_parsed_value_.value] = []
        if !color_set[_parsed_value_.value].has(i_): color_set[_parsed_value_.value].append(i_)
        _stored_value_['alpha'] = _parsed_value_.alpha
        _stored_value_['format'] = _parsed_value_.format
        _stored_value_['keyword'] = _parsed_value_.keyword

    for _Set in GC.ATTRIBUTE_SETS.keys():
        if not _attribute_ in GC.ATTRIBUTE_SETS[_Set]: continue
        if !icon_coll[icon_name_][node_offset_].has(_Set):
            icon_coll[icon_name_][node_offset_][_Set] = {}

        icon_coll[icon_name_][node_offset_][_Set][_attribute_] = _stored_value_
        return

    icon_coll[icon_name_][node_offset_][_attribute_] = _stored_value_


static func __get_color_value (value_ :String) -> Dictionary:
    var _result_ :Dictionary = {}
    var _is_rgb_ :bool = value_.begins_with("rgb")
    var _is_hsl_ :bool = value_.begins_with("hsl")
    if _is_rgb_ or _is_hsl_:
        var _matches_ = _number_regex.search_all(value_)

        if _matches_.size() >= 3:
            var _values_: Array[float] = []

            for _I in range(_matches_.size()):
                var _num_ = _matches_[_I].get_string(1).to_float()
                var _is_percent_ = _matches_[_I].get_string(2) == "%"
                _num_ = clamp(_num_, 0.0, 100.0) if _is_percent_ else clamp(_num_, 0.0, 255.0 if _is_rgb_ else 360.0)

                if _is_hsl_: match _I:
                    0: _values_.append(_num_)
                    1, 2: _values_.append(_num_ / 100.0)
                    _: _values_.append(_num_ / 100.0 if _is_percent_ else _num_)

                else: match _I:
                    0, 1, 2: _values_.append(_num_ / 100.0 if _is_percent_ else _num_ / 255.0)
                    _: _values_.append(_num_ / 100.0 if _is_percent_ else _num_)

            var _has_alpha_ :bool = _values_.size() > 3
            if !_has_alpha_: _values_.append(1.0)
            _result_['alpha'] = _has_alpha_

            _result_['value'] = Colorist.hsl_to_color(_values_[0], _values_[1], _values_[2], _values_[3]) \
                if _is_hsl_ else Color(_values_[0], _values_[1], _values_[2], _values_[3])

            _result_['format'] = GE.ColorFormat.HSL if _is_hsl_ else GE.ColorFormat.RGB_PERC \
                    if value_.contains('%') else GE.ColorFormat.RGB_INT

            _result_['keyword'] = ""
        return _result_

    if Color.html_is_valid(value_): return {
        value = Color(value_),
        alpha = value_.length() in [9, 5],
        format = GE.ColorFormat.HEX,
        keyword = "",
    }

    match value_:
        'lightgoldenrodyellow': value_ = 'lightgoldenrod'
        'navy': value_ = 'navyblue'
        _: if value_.contains('grey'): value_ = value_.replace('grey', 'gray')

    return {
        value = Color(value_),
        alpha = false,
        format = GE.ColorFormat.KEYWORD,
        keyword = value_,
    }


static func __get_float_value (value_ :String) -> Dictionary:
    var _match_ = _number_regex.search(value_)
    if _match_:
        var num = _match_.get_string(1).to_float()
        var is_percent = _match_.get_string(2) == "%"
        return { value = clamp(num / 100.0, 0.0, 1.0) if is_percent else clamp(num, 0.0, 1.0) }
    return { value = 1.0 }
