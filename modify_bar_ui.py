import re
with open('scenes/UI/BarUI.tscn', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('res://scripts/TableUi.gd', 'res://scripts/BarUi.gd')
content = re.sub(r'text = "Base Bet"', 'text = "Passive Income"', content)
content = re.sub(r'text = "Play Time"', 'text = "Prestige"', content)
content = re.sub(r'text = "VIP Bonus"', 'text = "VIP Percentage"', content)
content = content.replace('name="Dealer Upgrade"', 'name="Upgrades"')
content = re.sub(r'(\[node name="Table Upgrade" type="ScrollContainer"[^]]*\])', r'\1\nvisible = false', content)
content = content.replace('text = "Speed Training"', 'text = "Cashier Update"')
content = re.sub(r'(\[node name="WinProbPanel" type="PanelContainer"[^]]*\])', r'\1\nvisible = false', content)
with open('scenes/UI/BarUI.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
print('Modified BarUI.tscn')
