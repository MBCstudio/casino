const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');

// Update labels and ids
content = content.replace('res://scripts/TableUi.gd', 'res://scripts/BarUi.gd');
content = content.replace('text = "Base Bet"', 'text = "Passive Income"');
content = content.replace('text = "Play Time"', 'text = "Prestige"');
content = content.replace('text = "VIP Bonus"', 'text = "VIP Attraction"');
content = content.replace('name="Dealer Upgrade"', 'name="Upgrades"');
content = content.replace(/CenterContainer\/Panel\/VBoxContainer\/TabContainer\/Dealer Upgrade/g, 'CenterContainer/Panel/VBoxContainer/TabContainer/Upgrades');

// Wait time into Passive income rate text
content = content.replace('text = "Speed Training / Fast Games"', 'text = "Cashier Update"');
content = content.replace('text = "-2s Table Wait Time"', 'text = "Increases passive income rate"');
content = content.replace('text = "\,000  >"', 'text = "\,000"');

// Fix start amounts
content = content.replace('text = "\"', 'text = "\/s"');
content = content.replace('text = "10.0s"', 'text = "0"');
content = content.replace('text = "+0%"', 'text = "+0%"');

const lines = content.split('\n');
let result = [];
let skipPrefixes = [];
let insideSkippedNode = false;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    if (line.trim().startsWith('[node ')) {
        const nameMatch = line.match(/name="([^"]+)"/);
        const parentMatch = line.match(/parent="([^"]+)"/);
        
        const name = nameMatch ? nameMatch[1] : '';
        const parent = parentMatch ? parentMatch[1] : '';
        const fullPath = parent ? parent + '/' + name : name;
        
        insideSkippedNode = false;
        
        // Exclude all these paths entirely!
        if (name === 'Table Upgrade' || name === 'CharismaCoursePanel' || name === 'MasterClassPanel' || name === 'WinProbPanel' ) {
            skipPrefixes.push(fullPath);
            insideSkippedNode = true;
        } else {
            for (let prefix of skipPrefixes) {
                if (fullPath === prefix || fullPath.startsWith(prefix + '/')) {
                    insideSkippedNode = true;
                    break;
                }
            }
        }
    } else if (line.trim().startsWith('[') && !line.trim().startsWith('[node ')) {
         insideSkippedNode = false;
    }
    
    if (!insideSkippedNode) {
        result.push(line);
    }
}

fs.writeFileSync('scenes/UI/BarUI.tscn', result.join('\n'));
console.log('Pipeline complete!');

