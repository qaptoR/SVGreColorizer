class_name Filer
extends Object


func file_by_list (filename_ :String, list_ :Array):
    var _file_ = FileAccess.open(filename_, FileAccess.WRITE)
    for _Line in list_: _file_.store_line(_Line)
    _file_.close()


func file_by_dict (filename_ :String, coll_ :Dictionary):
    var _file_ = FileAccess.open(filename_, FileAccess.WRITE)
    for _Node in coll_.keys():
        _file_.store_line(_Node)
        for _Attr in coll_[_Node]:
            _file_.store_line('\t%s' %_Attr)
    _file_.close()


func file_string (filename_ :String, text_ :String):
    var _file_ = FileAccess.open(filename_, FileAccess.WRITE)
    _file_.store_string(text_)
    _file_.close()
