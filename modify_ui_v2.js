const fs = require('fs');

const tscnPath = 'scenes/UI/CashierUI.tscn';
let text = fs.readFileSync(tscnPath, 'utf8');

const blocks = [];
let currentBlock = [];
let inTargetBlock = false;

const lines = text.split('\n');

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith('[')) {
        if (line.includes('CashierUpdatePanel')) {
            if (currentBlock.length > 0 && inTargetBlock) blocks.push(currentBlock.join('\n'));
            currentBlock = [];
            inTargetBlock = true;
            currentBlock.push(line);
        } else {
            if (inTargetBlock) {
                blocks.push(currentBlock.join('\n'));
                currentBlock = [];
            }
            inTargetBlock = false;
        }
    } else {
        if (inTargetBlock) {
            currentBlock.push(line);
        }
    }
}
if (inTargetBlock && currentBlock.length > 0) {
    blocks.push(currentBlock.join('\n'));
}

const allTargetBlocks = blocks.join('\n\n');

function createPanel(name, niceName, desc, btnName, uidOffset) {
    let newPanel = allTargetBlocks.replace(/CashierUpdatePanel/g, name);
    newPanel = newPanel.replace(/Cashier Update/g, niceName);
    newPanel = newPanel.replace(/-1s Wait Time/g, desc);
    newPanel = newPanel.replace(/BuyCashierUpdateBtn/g, btnName);
    
    newPanel = newPanel.replace(/unique_id=(\d+)/g, (match, p1) => {
        return "unique_id=" + (parseInt(p1) + uidOffset);
    });
    return newPanel;
}

const prestigePanel = createPanel('PrestigeUpdatePanel', 'Golden Register', '+1 Prestige', 'BuyPrestigeBtn', 10000);
const vipPanel = createPanel('VipUpdatePanel', 'Red Carpet', '+1% VIP Chance', 'BuyVipBtn', 20000);

text += '\n\n' + prestigePanel + '\n\n' + vipPanel;
fs.writeFileSync(tscnPath, text, 'utf8');
console.log("Done");
