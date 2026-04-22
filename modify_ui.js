const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');
content = content.replace('text = "\"', 'text = "\/s"');
content = content.replace('text = "10.0s"', 'text = "0"');
const lines = content.split('\n');
let newLines = [];
let skipNode = false;
for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim().startsWith('[node ')) {
        if (line.includes('name="Table Upgrade"') || line.includes('parent="CenterContainer/Panel/VBoxContainer/TabContainer/Table Upgrade')) {
            skipNode = true;
        } else if (line.includes('name="CharismaCoursePanel"') || line.includes('parent="CenterContainer/Panel/VBoxContainer/TabContainer/Upgrades/VBoxContainer/CharismaCoursePanel')) {
            skipNode = true;
        } else if (line.includes('name="MasterClassPanel"') || line.includes('parent="CenterContainer/Panel/VBoxContainer/TabContainer/Upgrades/VBoxContainer/MasterClassPanel')) {
            skipNode = true;
        } else {
            skipNode = false;
        }
    }
    if (!skipNode) {
        newLines.push(line);
    }
}
fs.writeFileSync('scenes/UI/BarUI.tscn', newLines.join('\n'));

