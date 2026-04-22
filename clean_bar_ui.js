const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');

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
        
        if (name === 'Table Upgrade' || name === 'CharismaCoursePanel' || name === 'MasterClassPanel' || name === 'WinProbPanel' || name === 'PlayTimeBox') {
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
         // Some other tag (like ext_resource), reset skipped node just in case
         insideSkippedNode = false;
    }
    
    if (!insideSkippedNode) {
        // Fix labels
        let newLine = line;
        
        // Remove 's' from prestige and fix 
        if (newLine.includes('text = "10.0s"')) newLine = newLine.replace('text = "10.0s"', 'text = "0"');
        if (newLine.includes('text = "\"')) newLine = newLine.replace('text = "\"', 'text = "\/s"');
        if (newLine.includes('text = "+0%"')) newLine = newLine.replace('text = "+0%"', 'text = "0%"');
        
        // Convert Dealer Upgrade texts
        if (newLine.includes('text = "Speed Training / Fast Games"')) newLine = newLine.replace('text = "Speed Training / Fast Games"', 'text = "Cashier Update"');
        if (newLine.includes('text = "-2s Table Wait Time"')) newLine = newLine.replace('text = "-2s Table Wait Time"', 'text = "Increases passive income rate"');
        
        // Fix button texts
        if (newLine.includes('text = "\,000  >"')) newLine = newLine.replace('text = "\,000  >"', 'text = "\,000"');
        
        result.push(newLine);
    }
}

fs.writeFileSync('scenes/UI/BarUI.tscn', result.join('\n'));
console.log('Cleaned up BarUI.tscn successfully.');

