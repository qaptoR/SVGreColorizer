class_name GC
extends Object


const META_DATA :StringName = &'data'

# SVG PARSING
const COLOR :String = 'color'
const FILL :String = 'fill'
const STROKE :String = 'stroke'
const STOPCOLOR :String = 'stop-color'
const FLOODCOLOR :String = 'flood-color'
const LIGHTINGCOLOR :String = 'lighting-color'
const BGCOLOR :String = 'background-color'

const OPACITY :String = 'opacity'
const FILLOPACITY :String = 'fill-opacity'
const STROKEOPACITY :String = 'stroke-opacity'
const STOPOPACITY :String = 'stop-opacity'
const FLOODOPACITY :String = 'flood-opacity'

const ATTRIBUTE_SETS :Dictionary = {
    'fill': [FILL, FILLOPACITY],
    'stroke': [STROKE, STROKEOPACITY],
    'stop': [STOPCOLOR, STOPOPACITY],
    'flood': [FLOODCOLOR, FLOODOPACITY],
}

const COLOR_ATTR :Array = [COLOR, FILL, STROKE, STOPCOLOR, FLOODCOLOR, LIGHTINGCOLOR, BGCOLOR]
const OPACITY_ATTR :Array = [OPACITY, FILLOPACITY, STROKEOPACITY, STOPOPACITY, FLOODOPACITY]
const COLOR_VALUES :Array = COLOR_ATTR + OPACITY_ATTR

const COLOR_NONVALUES :Array = [
    r'(?i)none',
    r'(?i)url\(.*\)',
    r'(?i)currentcolor',
    r'(?i)inherit',
    r'(?i)transparent',
]


const SETTINGS_PATH = 'user://user_settings.cfg'
