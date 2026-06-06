# UpgradeCosts.gd
# Centralny plik ze wszystkimi kosztami ulepszeń w kasynie.
# Zamiast wpisywać liczby bezpośrednio w kodzie, używaj stałych z tej klasy.
# Przykład użycia:  var cost = UpgradeCosts.BAR_CASHIER

class_name UpgradeCosts

# ============================================================
#  BAR – ulepszenia
# ============================================================
const BAR_CASHIER   := 3000     # Szybka kasa barowa
const BAR_DRINKS    := 20000    # Ulepszenie drinków
const BAR_LIVE_BAND := 50000    # Żywy zespół

# ============================================================
#  KASA – ulepszenia
# ============================================================
const CASHIER_SPEED    := 10000   # Szybsza obsługa (skrócenie wait_time)
const CASHIER_PRESTIGE := 25000   # Ulepszenie prestiżu kasjera
const CASHIER_VIP      := 60000   # Zwiększenie szansy na VIP

# ============================================================
#  STOLIK – BLACKJACK
# ============================================================
const TABLE_BJ_SPEED     := 3000     # Fast Dealing
const TABLE_BJ_CHARISMA  := 5000     # Professional
const TABLE_BJ_MASTER    := 9000     # Senior Dealer
const TABLE_BJ_FELT      := 15000    # Premium Felt
const TABLE_BJ_LED       := 25000    # Brass Finish
const TABLE_BJ_CHIP_RACK := 40000    # Wooden Rack
const TABLE_BJ_VIP       := 70000    # Leather Seats
const TABLE_BJ_VINTAGE   := 120000   # Vintage Cards
const TABLE_BJ_SNACKS    := 250000   # Free Snacks

# ============================================================
#  STOLIK – ROULETTE
# ============================================================
const TABLE_RL_SPEED     := 5000     # Fast Spinning
const TABLE_RL_CHARISMA  := 8000     # Elegant Croupier
const TABLE_RL_MASTER    := 12000    # Master Croupier
const TABLE_RL_FELT      := 20000    # Luxury Felt
const TABLE_RL_LED       := 35000    # Gold Finish
const TABLE_RL_CHIP_RACK := 55000    # Classic Rack
const TABLE_RL_VIP       := 90000    # Velvet Seats
const TABLE_RL_MAHOGANY  := 150000   # Mahogany Wheel
const TABLE_RL_SNACKS    := 300000   # Gourmet Snacks

# ============================================================
#  PRESTIŻ – za zakup obiektu
# ============================================================
const PRESTIGE_BUY_TABLE := 10   # Za postawienie nowego stolika
const PRESTIGE_BUY_BAR   := 10   # Za zakup baru

# ============================================================
#  PRESTIŻ – ulepszenia BARU
# ============================================================
const PRESTIGE_BAR_DRINKS := 40   # Ulepszenie drinków
# BAR_CASHIER i BAR_LIVE_BAND nie dają prestiżu bezpośrednio
# (cashier → passive_income, band → vip_percentage)

# ============================================================
#  PRESTIŻ – ulepszenia KASY
# ============================================================
const PRESTIGE_CASHIER_PER_LEVEL := 10  # Za każdy poziom ulepszenia prestiżu kasjera

# ============================================================
#  PRESTIŻ – ulepszenia STOLIKA
# ============================================================
const PRESTIGE_TABLE_FELT      := 20    # Premium/Luxury Felt
const PRESTIGE_TABLE_LED       := 30    # Brass/Gold Finish
const PRESTIGE_TABLE_CHIP_RACK := 40    # Wooden/Classic Rack
const PRESTIGE_TABLE_VIP       := 50    # Leather/Velvet Seats
const PRESTIGE_TABLE_VINTAGE   := 70    # Vintage Cards / Mahogany Wheel
const PRESTIGE_TABLE_SNACKS    := 100   # Free/Gourmet Snacks
# Speed, Charisma, Master nie dają prestiżu (wpływają na play_time, vip_bonus, bet)
