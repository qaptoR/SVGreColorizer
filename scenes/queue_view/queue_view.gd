class_name QueueView
extends Control


signal parse_icon_directory(dir_path :String, selected :bool)
signal preview_image(path :String, data :TreeItem)
signal clear_previews()

const MAX_COLUMNS :int = 5
const FIRST_ITEMCOL :int = 0
const TEXT_COL :int = 0

@export var color_icon__ :Texture
@export var icon_reload__ :Texture
@export var update_color_icon__ :Texture
@export var _ConfirmCommitDialog__ :ConfirmationDialog

@onready var _Queue_ :ItemList = %Queue
@onready var _ClearAll_ :Button = %ClearAll
@onready var _ClearSelected_ :Button = %ClearSelected
@onready var _CommitAll_ :Button = %CommitAll
@onready var _CommitSelected_ :Button = %CommitSelected

var _TreeView_ :TreeView
var _DirPathLabel_ :Label
var _SettingsMenu_ :PopupMenu
var _ColorOptions_ :OptionButton


func _ready() -> void:
    __setup_dependencies()

    _ClearAll_.pressed.connect(_on_clear_all_pressed)
    _ClearSelected_.pressed.connect(_on_clear_selected_pressed)
    _CommitAll_.pressed.connect(_on_commit_all_pressed.bind(false))
    _CommitSelected_.pressed.connect(_on_commit_selected_pressed.bind(false))
    _Queue_.item_clicked.connect(_on_queue_item_clicked)

    _Queue_.max_columns = MAX_COLUMNS


func __setup_dependencies() -> void:
    var _gcon_ := CSConnector.with(get_tree().current_scene)
    _gcon_.connect_signal("sig:add_change", "add_change", add_change)
    _gcon_.connect_signal("sig:remove_change", "remove_change", remove_change)
    _gcon_.connect_signal("sig:perform_all_queue_changes", "perform_all_queue_changes", perform_all_queue_changes)

    var _conn_ := CSConnector.with(self)
    _conn_.register("sig:parse_icon_directory")
    _conn_.register("sig:clear_previews")
    _conn_.register("sig:preview_image")

    var _gloc_ := CSLocator.with(get_tree().current_scene)
    _gloc_.register("Queue", _Queue_)

    var _loc_ := CSLocator.with(self)
    _loc_.connect_service_found("TreeView", func(service): _TreeView_ = service)
    _loc_.connect_service_found("ColorOptions", func(service): _ColorOptions_ = service)
    _loc_.connect_service_found("DirPathLabel", func(service): _DirPathLabel_ = service)
    _loc_.connect_service_found("SettingsMenu", func(service): _SettingsMenu_ = service)


func add_change(item_ :TreeItem, col_ :int) -> void:
    var dir :String = _DirPathLabel_.text
    var iconName :String = item_.get_parent().get_text(0)
    var itemCount :int = _Queue_.get_item_count()
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)

    _Queue_.add_item(iconName, Colorist.get_icon_texture('%s/%s' %[dir, iconName]))
    _Queue_.set_item_metadata(itemCount, item_)
    _item_data_.queue = itemCount

    if _item_data_.has('color'):
        _Queue_.add_icon_item(color_icon__, false)
        _Queue_.set_item_icon_modulate(itemCount +1, _item_data_.color.org)

        _Queue_.add_icon_item(color_icon__, false)
        _Queue_.set_item_icon_modulate(itemCount +2, _item_data_.color.new)
    else:
        _Queue_.add_item("---", null, false)
        _Queue_.add_item("---", null, false)

    #TODO: add label items for opacity values
    if _item_data_.has('opacity'):
        _Queue_.add_item(str(_item_data_.opacity.org), null, false)
        _Queue_.add_item(str(_item_data_.opacity.new), null, false)
    else:
        _Queue_.add_item("---", null, false)
        _Queue_.add_item("---", null, false)

    var _button_idx_ :int = item_.get_button_by_id(col_, GE.TreeButtonId.COLOR)
    if _button_idx_ >= 0: item_.set_button_disabled(col_, _button_idx_, true)

    _button_idx_ = item_.get_button_by_id(col_, GE.TreeButtonId.QUEUE)
    item_.set_button(col_, _button_idx_, icon_reload__)
    item_.set_button_disabled(col_, _button_idx_, false)
    _item_data_.is_queued = true


func remove_change(item_ :TreeItem, col_ :int, all_ :bool) -> void:
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)
    var _button_idx_ :int = item_.get_button_by_id(col_, GE.TreeButtonId.COLOR)

    if _button_idx_ >= 0: item_.set_button_disabled(col_, _button_idx_, false)
    # Set the color-picker button to enabled

    _button_idx_ = item_.get_button_by_id(col_, GE.TreeButtonId.QUEUE)
    if all_:
        # set the ;reset button to disabled
        item_.set_button_disabled(col_, _button_idx_, true)
        # modulate the icon color back to the original
        item_.set_icon_modulate(GE.TreeColumn.NEW_COLOR, _item_data_.color.org)

    # swap reset button for add-to-queue button
    item_.set_button(col_, _button_idx_, update_color_icon__)

    # each queue item takes up 3 slots, which must all be removed
    var _items_ :int = _item_data_.queue
    for _I in range(_items_, _items_ +MAX_COLUMNS): _Queue_.remove_item(_items_)

    # clear tracking data
    _item_data_.is_queued = false
    _item_data_.queue = null

    if _Queue_.get_item_count() == 0: return
    for i in range(0, _Queue_.get_item_count(), MAX_COLUMNS):
        _Queue_.get_item_metadata(i).get_meta('data').queue = i


func perform_all_queue_changes(item_ :TreeItem, action_ :int) -> void:
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)
    _item_data_.is_queued = !_item_data_.is_queued
    item_.set_button(
        GE.TreeColumn.NEW_COLOR, GE.TreeButtonId.QUEUE,
        icon_reload__ if _item_data_.is_queued else update_color_icon__
    )

    var action :Callable
    match action_:
        GE.QueueChanges.ADD:
            action = __add
            item_.set_button_disabled(GE.TreeColumn.NEW_COLOR, GE.TreeButtonId.COLOR, true)
        GE.QueueChanges.REMOVE:
            action = __remove
            item_.set_button_disabled(GE.TreeColumn.NEW_COLOR, GE.TreeButtonId.COLOR, false)

    var _icons_ :TreeItem = item_.get_next()
    while _icons_:
        var _colors_ :Array[TreeItem] = _icons_.get_children()

        for _color_item_ :TreeItem in _colors_:
            var _color_data_ :Dictionary = _color_item_.get_meta(GC.META_DATA)

            if not (_color_data_.has('color') and _item_data_.has('color')): continue
            if _color_data_.color.org != _item_data_.color.org: continue

            action.call(_color_item_, item_)

        _icons_ = _icons_.get_next()


func __add (color_ :TreeItem, item_ :TreeItem) -> void:
    var _color_data_ :Dictionary = color_.get_meta(GC.META_DATA)
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)

    if _color_data_.is_queued == true: return

    _color_data_.color.new = _item_data_.color.new
    color_.set_icon_modulate(GE.TreeColumn.NEW_COLOR, _item_data_.color.new)
    TreeView.check_same(color_)
    add_change(color_, GE.TreeColumn.BUTTONS)


func __remove (color_ :TreeItem, item_ :TreeItem) -> void:
    var _color_data_ :Dictionary = color_.get_meta(GC.META_DATA)
    var _item_data_ :Dictionary = item_.get_meta(GC.META_DATA)

    if _color_data_.queue == null: return
    if _color_data_.color.new != _item_data_.color.new: return

    _color_data_.color.new = _item_data_.color.org
    TreeView.check_same(color_)
    remove_change(color_, GE.TreeColumn.BUTTONS, true)


func _on_clear_all_pressed() -> void:
    var _color_group_ :Array[TreeItem] = _TreeView_.root.get_children()

    if _color_group_.is_empty(): return
    if _color_group_[0].get_meta(GC.META_DATA).is_queued:
        perform_all_queue_changes(_color_group_[0], GE.QueueChanges.REMOVE)

    for _I in range(0, _Queue_.get_item_count(), MAX_COLUMNS):
        remove_change(_Queue_.get_item_metadata(0), GE.TreeColumn.BUTTONS, false)


func _on_clear_selected_pressed() -> void:
    var _list_ :PackedInt32Array = _Queue_.get_selected_items()
    _list_.reverse()

    for _I in _list_: remove_change(_Queue_.get_item_metadata(_I), GE.TreeColumn.BUTTONS, false)


func _on_commit_all_pressed(confirmation_ :bool) -> void:
    if _Queue_.get_item_count() == 0: return

    if _SettingsMenu_.is_item_checked(
        _SettingsMenu_.get_item_index(GE.MenuId.CONFIRM)
    ) and not confirmation_:
        _ConfirmCommitDialog__.confirmed.connect(
            _on_commit_all_pressed.bind(true), CONNECT_ONE_SHOT
        )
        _ConfirmCommitDialog__.popup_centered()
        return

    for _Icon :TreeItem in _TreeView_.root.get_children().slice(1):
        if not AppState.current_preview_changed_list.has(_Icon): continue
        if AppState.current_preview_changed_list[_Icon].is_empty(): continue

        __commit_changes(_Icon)

    parse_icon_directory.emit(_DirPathLabel_.text, false)
    clear_previews.emit()


func _on_commit_selected_pressed(confirmation_ :bool) -> void:
    var _selected_ :PackedInt32Array = _Queue_.get_selected_items()
    if _selected_.is_empty(): return

    if _SettingsMenu_.is_item_checked(
        _SettingsMenu_.get_item_index(GE.MenuId.CONFIRM)
    ) and not confirmation_:
        _ConfirmCommitDialog__.confirmed.connect(
            _on_commit_selected_pressed.bind(true), CONNECT_ONE_SHOT
        )
        _ConfirmCommitDialog__.popup_centered()
        return

    # collect icons and colors to commit
    var _commit_list_ :Dictionary[TreeItem, Array] = {}
    for _I in _selected_:
        var _item_ :TreeItem = _Queue_.get_item_metadata(_I)
        var _icon_ :TreeItem = _item_.get_parent()
        if not _commit_list_.has(_icon_): _commit_list_[_icon_] = []
        _commit_list_[_icon_].append(_item_)

    # collect all remaining queued changes into a list
    var _uncommited_list_ :Dictionary = {}
    for _I in range(0, _Queue_.get_item_count(), MAX_COLUMNS):
        if _I in _selected_: continue
        var _item_ :TreeItem = _Queue_.get_item_metadata(_I)
        var _icon_ :String = _item_.get_parent().get_text(0)
        var _item_data_ :Dictionary = _item_.get_meta(GC.META_DATA).duplicate(true)
        var _has_color_ :String = 'color' if _item_data_.has('color') else 'opacity'
        var _unique_id_ :String = '%s_%s_%s' %[
            _has_color_, _item_data_.node, _item_data_[_has_color_].attribute
        ]

        _uncommited_list_.get_or_add(_icon_, {})[_unique_id_] = _item_data_

    for _Icon in _commit_list_.keys():
        __commit_changes(_Icon, _commit_list_)

    var _color_group_data_ :Dictionary = _ColorOptions_.get_selected_metadata()
    parse_icon_directory.emit(_DirPathLabel_.text, false)
    clear_previews.emit()

    for _Idx :int in _ColorOptions_.get_item_count():
        var _metadata_ :Dictionary = _ColorOptions_.get_item_metadata(_Idx)
        if _metadata_.color != _color_group_data_.color: continue

        _ColorOptions_.select(_Idx)
        _ColorOptions_.item_selected.emit(_Idx)

        for _Icon :TreeItem in _TreeView_.root.get_children().slice(1):
            var _icon_name_ :String = _Icon.get_text(0)
            if not _uncommited_list_.has(_icon_name_): continue

            for _ColorItem :TreeItem in _Icon.get_children():
                var _color_data_ :Dictionary = _ColorItem.get_meta(GC.META_DATA)
                var _has_color_ :String = 'color' if _color_data_.has('color') else 'opacity'
                var _unique_id_ :String = '%s_%s_%s' %[
                    _has_color_, _color_data_.node, _color_data_[_has_color_].attribute,
                ]

                if _uncommited_list_[_icon_name_].has(_unique_id_):
                    _ColorItem.set_meta(
                        GC.META_DATA,
                        _uncommited_list_[_icon_name_][_unique_id_].duplicate(true)
                    )
                    add_change(_ColorItem, GE.TreeColumn.BUTTONS)
                    TreeView.check_same(_ColorItem)
                    _ColorItem.set_icon_modulate(
                        GE.TreeColumn.NEW_COLOR,
                        _uncommited_list_[_icon_name_][_unique_id_].color.new
                    )

func _on_queue_item_clicked(index_ :int, _position_ :Vector2, mouse_button_ :int) -> void:
    if mouse_button_ != MOUSE_BUTTON_RIGHT: return
    if index_ %MAX_COLUMNS != 0: return

    var _item_ :TreeItem = _Queue_.get_item_metadata(index_)
    var _parent_ :TreeItem = _item_.get_parent()

    preview_image.emit(
        '%s/%s' %[_DirPathLabel_.text, _parent_.get_text(0)],
        ParserData.get_preview_data(_parent_)
    )

    _parent_.collapsed = false
    _TreeView_.Tree_.scroll_to_item(_parent_, true)


func __commit_changes(icon_ :TreeItem, commit_list_ :Dictionary[TreeItem, Array] = {}) -> void:
    var _filename_ :String = _DirPathLabel_.text.path_join(icon_.get_text(TEXT_COL))
    var _data_ :TreeItem = ParserData.get_preview_data(icon_, true)

    var _file_ = FileAccess.open(_filename_, FileAccess.READ)
    if _file_ == null:
        MessageLogger.error(
            'file %s could not be opened for reading to commit changes' %_filename_.get_file(),
            get_script().resource_path.get_file()
        )
        return
    var _svgtext_ = _file_.get_as_text()
    _file_.close()

    _svgtext_ = AppState.use_preview_data(_svgtext_, _data_, commit_list_)

    _file_ = FileAccess.open(_filename_, FileAccess.WRITE)
    if _file_ == null:
        MessageLogger.error(
            'file %s could not be opened for writing to commit changes' %_filename_.get_file(),
            get_script().resource_path.get_file()
        )
        return
    _file_.store_string(_svgtext_)
    _file_.close()
