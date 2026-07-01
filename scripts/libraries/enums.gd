class_name GE
extends Object


enum IconColor { PENDING, QUEUED, }
enum Color_Picker { TREE, OPTIONS, SWATCH, }

enum QueueChanges { ADD, REMOVE, }
enum File_Dialog { PARSE, IMPORT, EXPORT, SAVE, }
enum SaveImageDialogue { PREVIEW, QUEUE, }

enum SettintsReset { THEME, ALL, }

enum MenuId {
    COLORS, IMAGE,
    DIRECTORY, CLEAR_PALETTE,
    CONFIRM,
    LOGS, BATCH_LOGS, COMMIT_BATCH_LOGS, CLEAR_LOGS, OVERWRITE_LOGS, APPEND_LOGS,
    ABOUT, QUIT_PROGRAM,
}
enum ColorChangedContext { NONE, SWATCH_UI_ACCEPT, KEYWORD_SELECTED }

enum TreeButtonId { COLOR, QUEUE, }
enum TreeColumn { ORG_COLOR, NEW_COLOR, ORG_OPACITY, NEW_OPACITY, BUTTONS, }

enum ColorFormat {
    HEX,
    RGB_INT,
    RGB_PERC,
    HSL,
    KEYWORD,
}
