extends Node


@onready var _ImmediateWindow_ :Window = $ImmediateWindow
@onready var _ImmediateLabel_ :Label = %ImmediateLabel

@onready var _BatchWindow_ :Window = $BatchWindow
@onready var _BatchLabel_ :RichTextLabel = %BatchLabel


func _ready() -> void:
    _ImmediateWindow_.confirmed.connect(_ImmediateWindow_.hide)
    _ImmediateWindow_.hide()

    _BatchWindow_.confirmed.connect(_BatchWindow_.hide)
    _BatchWindow_.hide()


func show_immediate_message(message_ :String) -> void:
    _ImmediateLabel_.text = message_
    _ImmediateWindow_.reset_size()

    _ImmediateWindow_.popup_centered()


func show_batch_message(message_ :String) -> void:
    _BatchLabel_.text = message_
    _BatchWindow_.reset_size()

    _BatchWindow_.popup_centered()
