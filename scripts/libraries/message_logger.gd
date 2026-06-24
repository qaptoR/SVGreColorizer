class_name MessageLogger
extends Object


enum LogLevel { INFO, WARNING, ERROR }

const LOG_FILE_PATH :String = "user://logs.txt"
const BATCH :bool = true
const CLEAR :bool = true

const LEVEL_LABEL :Dictionary = {
    LogLevel.INFO:    "INFO",
    LogLevel.WARNING: "WARN",
    LogLevel.ERROR:   "ERR ",
}
const LEVEL_SYMBOL :Dictionary = {
    LogLevel.INFO:    "✓",
    LogLevel.WARNING: "⚠",
    LogLevel.ERROR:   "✗",
}
const LEVEL_COLOR :Dictionary = {
    LogLevel.INFO:    "#88cc88",
    LogLevel.WARNING: "#ddaa44",
    LogLevel.ERROR:   "#cc5555",
}

static var _batch_messages :Array[Dictionary] = []
static var _messages :Array[Dictionary] = []


# TODO: need a button and method to clear the log file
# and a way to view it in the editor



# 88      dP"Yb   dP""b8  dP""b8 88 88b 88  dP""b8
# 88     dP   Yb dP   `" dP   `" 88 88Yb88 dP   `"
# 88  .o Yb   dP Yb  "88 Yb  "88 88 88 Y88 Yb  "88
# 88ood8  YbodP   YboodP  YboodP 88 88  Y8  YboodP

static func log_message(
    message_ :String,
    level_ :LogLevel = LogLevel.INFO,
    source_path_ :String = "",
    batch_ :bool = false
) -> void:
    var _entry_ := {
        "message":     message_,
        "level":       level_,
        "source_path": source_path_,
        "timestamp":   Time.get_datetime_string_from_system(),
    }

    if batch_: _batch_messages.append(_entry_)
    else: _messages.append(_entry_)
    _print_entry(_entry_)


static func info(message_ :String, source_path_ :String = "", batch_ :bool = false) -> void:
    log_message(message_, LogLevel.INFO, source_path_, batch_)


static func warn(message_ :String, source_path_ :String = "", batch_ :bool = false) -> void:
    log_message(message_, LogLevel.WARNING, source_path_, batch_)


static func error(message_ :String, source_path_ :String = "", batch_ :bool = false) -> void:
    log_message(message_, LogLevel.ERROR, source_path_, batch_)



#  dP"Yb  88   88 888888 88""Yb Yb  dP 88 88b 88  dP""b8 
# dP   Yb 88   88 88__   88__dP  YbdP  88 88Yb88 dP   `" 
# Yb b dP Y8   8P 88""   88"Yb    8P   88 88 Y88 Yb  "88 
#  `"YoYo `YbodP' 888888 88  Yb  dP    88 88  Y8  YboodP 

static func get_messages(batch_ :bool = false, deep_ :bool = false) -> Array[Dictionary]:
    return _batch_messages.duplicate(deep_) if batch_ else _messages.duplicate(deep_)


static func _get_messages(batch_ :bool = false) -> Array[Dictionary]:
    return _batch_messages if batch_ else _messages


static func get_messages_at_level(level_ :LogLevel, batch_ :bool = false) -> Array[Dictionary]:
    return _get_messages(batch_).filter(func(e_ :Dictionary) -> bool :return e_.level == level_)


static func has_errors(batch_ :bool = false) -> bool:
    return _get_messages(batch_).any(func(e_ :Dictionary) -> bool :return e_.level == LogLevel.ERROR)


static func has_warnings(batch_ :bool = false) -> bool:
    return _get_messages(batch_).any(func(e_ :Dictionary) -> bool :return e_.level == LogLevel.WARNING)


static func error_count(batch_ :bool = false) -> int:
    return get_messages_at_level(LogLevel.ERROR, batch_).size()


static func warning_count(batch_ :bool = false) -> int:
    return get_messages_at_level(LogLevel.WARNING, batch_).size()


static func is_empty(batch_ :bool = false) -> bool:
    return _get_messages(batch_).is_empty()



#  dP""b8  dP"Yb  88b 88 888888 88""Yb  dP"Yb  88
# dP   `" dP   Yb 88Yb88   88   88__dP dP   Yb 88
# Yb      Yb   dP 88 Y88   88   88"Yb  Yb   dP 88  .o
#  YboodP  YbodP  88  Y8   88   88  Yb  YbodP  88ood8

## Clears all stored messages. Call between batches if reusing the logger.
static func clear(batch_ :bool = false) -> void:
    if batch_: _batch_messages.clear()
    else: _messages.clear()


static func commit(clear_ :bool = false) -> void:
    if clear_:
        _messages.append_array(_batch_messages)
        _batch_messages.clear()
    else: _messages.append_array(_batch_messages)



#  dP"Yb  88   88 888888 88""Yb 88   88 888888
# dP   Yb 88   88   88   88__dP 88   88   88
# Yb   dP Y8   8P   88   88"""  Y8   8P   88
#  YbodP  `YbodP'   88   88     `YbodP'   88

## Returns a one-line plain-text summary suitable for a status bar or dialog.
static func get_summary(batch_ :bool = false) -> String:
    var _total_   := _get_messages(batch_).size()
    var _errors_  := error_count(batch_)
    var _warnings_ := warning_count(batch_)
    return "%d message%s — %d error%s, %d warning%s" % [
        _total_,    "s" if _total_    != 1 else "",
        _errors_,   "s" if _errors_   != 1 else "",
        _warnings_, "s" if _warnings_ != 1 else "",
    ]


## Returns BBCode-formatted text ready for a RichTextLabel.
## Format:  [symbol]  filename.svg   message text
static func get_display_text(batch_ :bool = false) -> String:
    if is_empty(batch_):
        return "[color=#888888]No messages.[/color]"

    var _lines_ :PackedStringArray = []
    for _Entry :Dictionary in _messages:
        var _level_ :LogLevel   = _Entry.level
        var _color_ :String  = LEVEL_COLOR[_level_]
        var _symbol_ :String = LEVEL_SYMBOL[_level_]

        var _source_ := ""
        if not (_Entry.source_path as String).is_empty():
            var _filename_ :String = (_Entry.source_path as String).get_file()
            _source_ = "  [color=#aaaaaa]%s[/color]" % _filename_

        _lines_.append("[color=%s]%s[/color]%s  %s" % [
            _color_, _symbol_, _source_, _Entry.message
        ])

    return "\n".join(_lines_)


## Returns a plain-text copy of the log suitable for clipboard export.
static func get_plain_text(batch_) -> String:
    var _lines_ :PackedStringArray = []
    _lines_.append("── MessageLogger Export ── %s" % Time.get_datetime_string_from_system())
    _lines_.append("─".repeat(60))

    for _Entry :Dictionary in _get_messages(batch_):
        _lines_.append(_format_entry(_Entry))

    _lines_.append("")
    _lines_.append(get_summary())
    return "\n".join(_lines_)


## Writes the current log to a file, overwriting any existing content.
static func flush_messages_to_file(
    file_path_ :String = LOG_FILE_PATH, batch_ :bool = false
) -> Error:
    var _file_ := FileAccess.open(file_path_, FileAccess.WRITE)
    if _file_ == null:
        var _err_ := FileAccess.get_open_error()
        push_error("MessageLogger: could not open '%s' for writing: %s" % [
            file_path_, error_string(_err_)
        ])
        return _err_

    _file_.store_string(get_plain_text(batch_))
    _file_.close()
    return OK


## Appends new entries to an existing log file rather than overwriting it.
## Useful for multi-session or multi-pass workflows.
static func append_messages_to_file(
    file_path_ :String = LOG_FILE_PATH, batch_ :bool = false
) -> Error:
    var _file_ := FileAccess.open(file_path_, FileAccess.READ_WRITE)
    if _file_ == null: return flush_messages_to_file(file_path_)

    _file_.seek_end()
    _file_.store_line("\n── Appended ── %s" % Time.get_datetime_string_from_system())
    for entry :Dictionary in _get_messages(batch_):
        _file_.store_line(_format_entry(entry))
    _file_.store_line(get_summary())
    _file_.close()
    return OK



# 88  88 888888 88     88""Yb 888888 88""Yb .dP"Y8
# 88  88 88__   88     88__dP 88__   88__dP `Ybo."
# 888888 88""   88  .o 88"""  88""   88"Yb  o.`Y8b
# 88  88 888888 88ood8 88     888888 88  Yb 8bodP'

static func _format_entry(entry_ :Dictionary) -> String:
    var _line_ := "[%s][%s]" % [entry_.timestamp, LEVEL_LABEL[entry_["level"]]]

    if not (entry_.source_path as String).is_empty():
        _line_ += " %s:" % (entry_.source_path as String).get_file()
    _line_ += " %s" % entry_.message

    return _line_


static func _print_entry(entry_ :Dictionary) -> void:
    var _line_ := _format_entry(entry_)

    match entry_.level as LogLevel:
        LogLevel.WARNING: push_warning(_line_)
        LogLevel.ERROR:   push_error(_line_)
        _:                print(_line_)
