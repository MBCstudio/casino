const fs = require('fs');
let content = fs.readFileSync('scenes/UI/BarUI.tscn', 'utf8');

let lines = content.split('\n');
let startIdx = lines.findIndex(l => l.includes('name="SpeedTrainingPanel"'));
let endIdx = lines.length;

// Find the start of the next tab or something indicating end of upgrades
let block = lines.slice(startIdx).join('\n');

function createPanel(newId, title, desc, btnName, cost, baseStr) {
    let result = baseStr.replace(/SpeedTrainingPanel/g, newId + 'Panel');
    result = result.replace(/Cashier Update/g, title);
    result = result.replace(/Increases passive income rate/g, desc);
    result = result.replace(/BuySpeedBtn/g, btnName);
    result = result.replace(/\\\,000/g, '\\\$' + cost);
    // Replace unique_ids so godot doesn't complain
    result = result.replace(/unique_id=\d+/g, () => 'unique_id=' + Math.floor(Math.random() * 2000000000));
    return result;
}

let panelLines = [];
let braceCount = 0;
for (let i = startIdx; i < lines.length; i++) {
    panelLines.push(lines[i]);
}
// since SpeedTrainingPanel is the LAST element currently, we can just grab everything from startIdx to the end!
let originalPanel = panelLines.join('\n');

let panelDrinks = createPanel('Drinks', 'Premium Drinks', 'Adds +150 Prestige', 'BuyDrinksBtn', '8,000', originalPanel);
let panelBand = createPanel('Band', 'Live Band', 'Adds +5% VIP Attraction', 'BuyBandBtn', '12,000', originalPanel);

lines.push('');
lines.push(panelDrinks);
lines.push('');
lines.push(panelBand);

fs.writeFileSync('scenes/UI/BarUI.tscn', lines.join('\n'));

