class_name TreeView
extends Control


signal open_color_picker()
signal add_change(item :TreeItem, col :int)
signal remove_change(item :TreeItem, col :int, all :bool)
signal perform_all_queue_changes(item :TreeItem, action :int)
signal preview_image(path, data)

@export var color_icon__ :Texture
@export var color_bucket_icon__ :Texture
@export var update_color_icon__ :Texture

@onready var Tree_ :Tree = %Tree
@onready var _Collapse_ :Button = %Collapse
@onready var _Expand_ :Button = %Expand

var _DirPathLabel_ :Label

var root :TreeItem


func _ready():
    __setup_dependencies()

    Tree_.button_clicked.connect(_on_tree_button_clicked)
    Tree_.item_selected.connect(_on_tree_item_selected)
    Tree_.item_mouse_selected.connect(_on_tree_item_mouse_selected)
    Tree_.item_edited.connect(_on_tree_item_edited)

    _Collapse_.pressed.connect(_collapse_all.bind(true))
    _Expand_.pressed.connect(_collapse_all.bind(false))


    root = Tree_.create_item()

    Tree_.hide_root = true
    Tree_.columns = 5
    Tree_.allow_rmb_select = true
    for _I in 5: Tree_.set_column_expand(_I, true)
    for _I in 4: Tree_.set_column_custom_minimum_width(_I, 20)
    Tree_.set_column_custom_minimum_width(4, 50)
    Tree_.select_mode = Tree.SELECT_SINGLE


func __setup_dependencies() -> void:
    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:open_color_picker")
    _conn_.register("sig:add_change")
    _conn_.register("sig:remove_change")
    _conn_.register("sig:perform_all_queue_changes")

    _conn_.register("sig:preview_image")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("TreeView", self)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("DirPathLabel", func(service): _DirPathLabel_ = service)


func _shortcut_input(event: InputEvent):
    if not event.is_action_pressed("ui_accept"):
        return

    var selected_item = Tree_.get_selected()
    if not selected_item:
        print("No item selected")
        return

    var col = Tree_.get_selected_column()
    if not selected_item.get_cell_mode(col) == TreeItem.CELL_MODE_RANGE:
        print("Selected column is not editable")
        return

    var current_focus = get_viewport().gui_get_focus_owner()

    # If we are currently editing, this forces the internal LineEdit to submit
    if not current_focus:
        print("No focus owner")
        return

    if not Tree_.is_ancestor_of(current_focus):
        print("Focus owner is not a child of the Tree")
        return

    current_focus.release_focus()
    # Refocus the tree so the user doesn't lose keyboard navigation
    Tree_.grab_focus()


func update_tree_view(coll_ :Dictionary, list_ :Array, group_ :Dictionary, dir_ :String) -> void:
    Tree_.clear()

    root = Tree_.create_item()
    root.set_meta(GC.META_DATA, {'name': 'root'})

    # show new color root
    var _color_group_ :TreeItem = Tree_.create_item(root)
    _color_group_.set_icon(GE.TreeColumn.ORG_COLOR, color_icon__)
    _color_group_.set_icon_modulate(GE.TreeColumn.ORG_COLOR, group_.color)

    _color_group_.set_icon(GE.TreeColumn.NEW_COLOR, color_icon__)
    _color_group_.set_icon_modulate(GE.TreeColumn.NEW_COLOR, group_.color)
    _color_group_.set_meta(GC.META_DATA, {
        'name': 'group_color',
        'color': {
            'org': group_.color,
            'new': group_.color,
        },
        'unchanged': true,
        'is_queued': false,
        'queue': null,
    })

    _color_group_.add_button(GE.TreeColumn.NEW_COLOR, color_bucket_icon__, GE.TreeButtonId.COLOR, false)
    _color_group_.add_button(GE.TreeColumn.NEW_COLOR, update_color_icon__, GE.TreeButtonId.QUEUE, true)
    for i in 3: _color_group_.set_selectable(i, false)

    # show only icons with chosen color
    for _Index in group_.icons:
        var _icon_name_ = list_[_Index]

        var _icon_item_ :TreeItem = Tree_.create_item(root)
        _icon_item_.set_text(GE.TreeColumn.ORG_COLOR, _icon_name_)
        _icon_item_.set_expand_right(GE.TreeColumn.ORG_COLOR, true)
        _icon_item_.set_icon(GE.TreeColumn.ORG_COLOR, Colorist.get_icon_texture('%s/%s' %[dir_, _icon_name_]))
        _icon_item_.collapsed = true
        _icon_item_.set_meta(GC.META_DATA, {
            'name':'file_name',
        })

        # list nodes in file order
        for _Offset in coll_[_icon_name_].keys():
            var _node_data_ = coll_[_icon_name_][_Offset]

            for _AttributeOrSet in _node_data_:
                var _node_item_ :TreeItem = Tree_.create_item(_icon_item_)
                _node_item_.set_meta(GC.META_DATA, {
                    'name': 'color',
                    'is_queued': false,
                    'unchanged': true,
                    'queue': null,
                })
                for _J in 5: _node_item_.set_selectable(_J, false)
                var _flag_ :bool = false
                if _AttributeOrSet in GC.ATTRIBUTE_SETS: # attribute set node
                    for _attribute_ in GC.ATTRIBUTE_SETS[_AttributeOrSet]:
                        if not _node_data_[_AttributeOrSet].has(_attribute_): continue
                        if _attribute_ in GC.OPACITY_ATTR:
                            __set_opacity(_node_item_, _node_data_[_AttributeOrSet][_attribute_], _Offset)
                        else: __set_color(_node_item_, _node_data_[_AttributeOrSet][_attribute_], _Offset)
                else: # single attribute node
                    if _AttributeOrSet in GC.OPACITY_ATTR:
                        __set_opacity(_node_item_, _node_data_[_AttributeOrSet], _Offset)
                    else: __set_color(_node_item_, _node_data_[_AttributeOrSet], _Offset)

                _node_item_.add_button(GE.TreeColumn.BUTTONS, update_color_icon__, GE.TreeButtonId.QUEUE, true)


func __set_color(item_ :TreeItem, data_ :Dictionary, offset_ :int):
    item_.set_icon(GE.TreeColumn.ORG_COLOR, color_icon__)
    item_.set_icon_modulate(GE.TreeColumn.ORG_COLOR, data_.value)

    item_.set_icon(GE.TreeColumn.NEW_COLOR, color_icon__)
    item_.set_icon_modulate(GE.TreeColumn.NEW_COLOR, data_.value)

    item_.add_button(GE.TreeColumn.BUTTONS, color_bucket_icon__, GE.TreeButtonId.COLOR, false)

    var _data_ :Dictionary = item_.get_meta(GC.META_DATA)
    _data_['color'] = {
        'org': data_.value,
        'new': data_.value,
        'is_same': true,
        'value': data_.string,
        'attribute': data_.attribute,
        'alpha': data_.alpha,
        'css': data_.css,
    }
    _data_['node'] = data_.node_id
    _data_['offset'] = offset_


func __set_opacity(item_ :TreeItem, data_ :Dictionary, offset_ :int):
    item_.set_text(GE.TreeColumn.ORG_OPACITY, '%s'%data_.value)

    item_.set_editable(GE.TreeColumn.NEW_OPACITY, true)
    item_.set_cell_mode(GE.TreeColumn.NEW_OPACITY, TreeItem.CELL_MODE_RANGE)
    item_.set_range_config(GE.TreeColumn.NEW_OPACITY, 0.0, 1.0, 0.001)
    item_.set_range(GE.TreeColumn.NEW_OPACITY, data_.value)

    var _data_ :Dictionary = item_.get_meta(GC.META_DATA)
    _data_['opacity'] = {
        'org': data_.value,
        'new': data_.value,
        'is_same': true,
        'value': data_.string,
        'attribute': data_.attribute,
        'css': data_.css,
    }
    _data_['node'] = data_.node_id
    _data_['offset'] = offset_
    item_.set_selectable(GE.TreeColumn.ORG_OPACITY, true)
    item_.set_selectable(GE.TreeColumn.NEW_OPACITY, true)


func _collapse_all(do_ :bool):
    var _child_items_ = root.get_children()
    for _child_item_ in _child_items_:
        _child_item_.collapsed = do_


func _on_tree_item_edited() -> void:
    var _item_ :TreeItem = Tree_.get_edited()
    var _col_ :int = Tree_.get_edited_column()
    if _col_ != 3: return

    var _new_opacity_ :float = _item_.get_range(_col_)


func __on_update_opacity(item_ :TreeItem, value_ :float):
    item_.get_meta(GC.META_DATA).opacity.new = value_
    check_same(item_)
    update_button_state(item_, GE.TreeColumn.BUTTONS)

    var _icon_ :TreeItem = item_.get_parent()
    preview_image.emit(
        '%s/%s' %[_DirPathLabel_.text, _icon_.get_text(0)],
        ParserData.get_preview_data(_icon_)
    )


func _on_tree_button_clicked(item_ :TreeItem, col_ :int, id_ :int, mouse_button_ :int):
    AppState.current_color_button = {
        'color': item_,
        'col': col_,
        'id': id_,
        'icon': item_.get_parent()
    }

    match id_:
        GE.TreeButtonId.COLOR:
            AppState.color_picker_state = GE.Color_Picker.TREE
            open_color_picker.emit(true if mouse_button_ == MouseButton.MOUSE_BUTTON_RIGHT else false)

        GE.TreeButtonId.QUEUE: match item_.get_meta('data').is_queued:
            true: match item_.get_meta('data').name:
                'color': remove_change.emit(item_, col_, false)
                'group_color': perform_all_queue_changes.emit(item_, GE.QueueChanges.REMOVE)

            false: match item_.get_meta('data').name:
                'color': add_change.emit(item_, col_)
                'group_color': perform_all_queue_changes.emit(item_, GE.QueueChanges.ADD)


func _on_tree_item_selected():
    var _tree_item_ :TreeItem = Tree_.get_selected()

    match _tree_item_.get_meta('data').name:
        'file_name':
            var _path_ :String = '%s/%s' %[_DirPathLabel_.text, _tree_item_.get_text(0)]
            var _data_ :TreeItem = ParserData.get_preview_data(_tree_item_)
            if !AppState.current_preview_changed_list.has(_tree_item_):
                AppState.current_preview_changed_list[_tree_item_] = {}
            AppState.current_preview_item = {
                'path': _path_,
                'data': _data_
            }
            preview_image.emit(_path_, _data_)
        'color':
            var _col_ :int = Tree_.get_selected_column()
            match _col_:
                GE.TreeColumn.ORG_OPACITY:
                    var _original_opacity_ := float(_tree_item_.get_meta('data').opacity.org)
                    _tree_item_.get_meta('data').opacity.new = _original_opacity_
                    _tree_item_.set_range(3, _original_opacity_)
                    check_same(_tree_item_)
                    update_button_state(_tree_item_, GE.TreeColumn.BUTTONS)

                    var _icon_ :TreeItem = _tree_item_.get_parent()
                    preview_image.emit(
                        '%s/%s' %[_DirPathLabel_.text, _icon_.get_text(0)],
                        ParserData.get_preview_data(_icon_)
                    )

                GE.TreeColumn.NEW_OPACITY:
                    _on_new_opacity_column_selected(_tree_item_)

                _: return


func _on_new_opacity_column_selected(item_ :TreeItem):
    var _popup_ :Popup = Tree_.find_child("?Popup*", false, false)
    if not _popup_: return
    var _slider_ :HSlider = _popup_.find_child("?HSlider*", true, false)
    while not _slider_ and is_instance_valid(_popup_):
        await get_tree().process_frame
        _slider_ = _popup_.find_child("?HSlider*", true, false)
    if _slider_.value_changed.is_connected(_on_tree_popup_slider_value_changed):
        _slider_.value_changed.disconnect(_on_tree_popup_slider_value_changed)
    _slider_.value_changed.connect(_on_tree_popup_slider_value_changed.bind(item_))


func _on_tree_popup_slider_value_changed(value_ :float, item_ :TreeItem):
    __on_update_opacity(item_, value_)


func _on_tree_item_mouse_selected(mouse_pos_: Vector2, mouse_idx_: int):
    match mouse_idx_:
        1:
            var _tree_item_ :TreeItem = Tree_.get_item_at_position(mouse_pos_)
            _tree_item_.collapsed = !_tree_item_.collapsed
        _: pass


static func check_same(item_ :TreeItem) -> void:
    var _data_ :Dictionary = item_.get_meta(GC.META_DATA)
    _data_.unchanged = true
    for _Attribute in ['color', 'opacity']:
        if not _data_.has(_Attribute): continue
        var _pack_ = _data_[_Attribute]
        _pack_.is_same = _pack_.org == _pack_.new
        _data_.unchanged = _data_.unchanged and _pack_.is_same

    if _data_.name == 'group_color': return

    var _parent_ :TreeItem = item_.get_parent()
    if !AppState.current_preview_changed_list.has(_parent_):
        AppState.current_preview_changed_list[_parent_] = {}
    if !_data_.unchanged:
        AppState.current_preview_changed_list[_parent_][item_] = _data_
    else: AppState.current_preview_changed_list[_parent_].erase(item_)


static func update_button_state(item_ :TreeItem, col_ :int) -> void:
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)
    var _button_idx_ :int = item_.get_button_by_id(col_, GE.TreeButtonId.QUEUE)

    if _item_data_.unchanged == false:
        item_.set_button_disabled(col_, _button_idx_, false)
    elif _item_data_.is_queued == false:
        item_.set_button_disabled(col_, _button_idx_, true)
