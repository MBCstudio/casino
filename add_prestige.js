const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');

if (!content.includes('Value2')) {
    const lines = content.split('\n');
    let newLines = [];
    for (let i = 0; i < lines.length; i++) {
        newLines.push(lines[i]);
        if (lines[i].includes('name="BaseBetBox"')) {
            // Find end of BaseBetBox
            let end = i;
            while(!lines[end+1].includes('[node ')) {
                end++;
            }
            // we will insert the new node after BaseBetBox is defined... wait, BaseBetBox has children. 
            // It's better to just manually inject the nodes for PrestigeBox.
        }
    }
}

