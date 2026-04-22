const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');

// Fix the \/min instead of /s
content = content.replace('text = "\/s"', 'text = "\/min"');

let lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('name="PrestigeLabel"') && lines[i].includes('parent=')) {
        lines.splice(i+1, 0, 'unique_name_in_owner = true');
        for (let j = i+1; j < i+10; j++) {
            if (lines[j].includes('text = "') && lines[j].includes('850"')) {
                lines[j] = lines[j].replace('850', '0');
                break;
            }
        }
        break;
    }
}

for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('unique_name_in_owner = true') && (lines[i-1].includes('name="Value"') || lines[i-1].includes('name="Value3"'))) {
        let hasAlign = false;
        for (let j = i; j < i+5; j++) {
            if (lines[j].startsWith('[')) break;
            if (lines[j].includes('horizontal_alignment = 1')) hasAlign = true;
        }
        if (!hasAlign) {
            lines.splice(i+2, 0, 'horizontal_alignment = 1');
        }
    }
}

fs.writeFileSync('scenes/UI/BarUI.tscn', lines.join('\n'));

