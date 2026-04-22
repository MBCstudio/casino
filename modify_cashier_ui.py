import re

with open('scenes/UI/CashierUI.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# We need to find the entire CashierUpdatePanel section
# It starts at [node name="CashierUpdatePanel"
# It ends right before the next root level node or end of file

panel_match = re.search(r'\[node name="CashierUpdatePanel".*?(?=\n\[node|$)', text, re.DOTALL)
if not panel_match:
    print("Panel not found")
    exit(1)

panel_text = panel_match.group(0)

def create_panel(name, nice_name, desc, btn_name, uid_offset):
    # just basic replacements
    new_panel = panel_text.replace('CashierUpdatePanel', f'{name}')
    new_panel = new_panel.replace('Cashier Update', nice_name)
    new_panel = new_panel.replace('-1s Wait Time', desc)
    new_panel = new_panel.replace('BuyCashierUpdateBtn', btn_name)
    # offset uids
    def offset_uid(match):
        uid_str = match.group(1)
        uid_val = int(uid_str) + uid_offset
        return f'unique_id={uid_val}'
    new_panel = re.sub(r'unique_id=(\d+)', offset_uid, new_panel)
    return new_panel

prestige_panel = create_panel('PrestigeUpdatePanel', 'Golden Register', '+1 Prestige', 'BuyPrestigeBtn', 10000)
vip_panel = create_panel('VipUpdatePanel', 'Red Carpet', '+1% VIP Chance', 'BuyVipBtn', 20000)

new_text = text.replace(panel_text, panel_text + "\n" + prestige_panel + "\n" + vip_panel)

with open('scenes/UI/CashierUI.tscn', 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Done modification")
