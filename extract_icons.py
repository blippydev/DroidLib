import re

with open(r'C:\Users\Anton\AppData\Local\Temp\dw_lucide_icons.lua', encoding='utf-8') as f:
    src = f.read()

m = dict(re.findall(r'\["([^"]+)"\] = "(rbxassetid://\d+)"', src))
print('total icons:', len(m))

want = ['home', 'house', 'settings', 'sword', 'swords', 'crosshair', 'eye',
        'users', 'user', 'move', 'car', 'map', 'compass', 'globe', 'box',
        'package', 'wrench', 'zap', 'shield', 'target', 'sparkles', 'keyboard',
        'save', 'trash-2', 'search', 'info', 'x', 'check', 'plus', 'menu',
        'gamepad-2', 'wifi', 'server', 'hammer', 'layers', 'radar', 'ghost',
        'skull', 'bomb', 'crown', 'gem', 'rocket', 'flag', 'bell', 'camera',
        'axe', 'flame', 'gauge', 'sliders-horizontal', 'palette', 'lock',
        'chevron-down', 'chevron-right', 'refresh-ccw', 'play', 'trophy',
        'dices', 'puzzle', 'timer', 'activity', 'siren', 'hourglass',
        'smartphone', 'monitor', 'tent', 'mountain', 'waves', 'fish', 'key',
        'door-open', 'coffee', 'gift', 'bug', 'lightbulb', 'wallet', 'music',
        'headphones', 'radio', 'tv', 'film', 'printer', 'satellite', 'drone',
        'anchor', 'ship', 'plane', 'bike', 'fuel', 'traffic-cone', 'sailboat',
        'backpack', 'tent-tree', 'pickaxe', 'shovel', 'lantern', 'compass']

missing = [w for w in want if w not in m]
print('missing:', missing)
found = {w: m[w] for w in want if w in m}
print('found:', len(found))

lines = [
    '-- DWLibV1 vendored lucide tab icons (subset).',
    '-- Source icons: Footagesus/Icons lucide pack (Lucide is MIT).',
    '-- Full upstream set has 1500+ names; add more lines here as needed.',
    '-- Thesetint white at runtime via ImageColor3, so they follow the theme.',
    '',
    'Library.IconMap = Library.IconMap or {}',
    'do',
]
for k in sorted(found):
    lines.append('\tLibrary.IconMap["%s"] = "%s"' % (k, found[k]))
lines.append('end')
lines.append('')
lines.append('function Library:GetIcon(name)')
lines.append('\tif name == nil then return nil end')
lines.append('\tlocal s = tostring(name):gsub("^%s+", ""):gsub("%s+$", ""):lower()')
lines.append('\tif s == "" then return nil end')
lines.append('\tif s:match("^rbxassetid://%d+$") then return s end')
lines.append('\tif s:match("^%d+$") then return "rbxassetid://" .. s end')
lines.append('\treturn self.IconMap[s]')
lines.append('end')

with open('DWLIBV1/src/Icons.lua', 'w', encoding='utf-8', newline='') as f:
    f.write('\n'.join(lines) + '\n')
print('wrote DWLIBV1/src/Icons.lua')
