CLASS_SETTINGS <-
[
    // UNKNOWN
    {
        "health": 125,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.2
    },
	// SCOUT
    {
        "health": 125,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.2
    },
	// SNIPER
    {
        "health": 125,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.2
    },
	// SOLDIER
    {
        "health": 200,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.8
    },
	// DEMOMAN
    {
        "health": 175,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.5
    },
	// MEDIC
    {
        "health": 150,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.5
    },
	// HEAVY
    {
        "health": 500,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.8
    },
	// PYRO
    {
        "health": 175,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.5
    },
	// SPY
    {
        "health": 125,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.2
    },
	// ENGINEER
    {
        "health": 125,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen": 1,
        "regen_interval": 1.2
    },
]

GAME_SETTINGS <-
{
	"bot_wave_interval": 30
}

BUILDING_SETTINGS <-
{
	"sentry":
	[
		{
			"health": 1500,
			"range": 450,
			"damage": 5
		},
		{
			"health": 3000,
			"range": 600,
			"damage": 10
		},
		{
			"health": 6000,
			"range": 800,
			"damage": 25
		}
	]
}

BOT_SETTINGS <-
{
	"melee":
	{
		"health": 300,
		"damage": 8.0,
		"attack_range": 64.0,
		"attack_range_min": 36.0,
		"aggro_range": 256.0,
		"class": 6,
		"model": "models/bots/heavy/bot_heavy.mdl",
		"model_scale": 0.6,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_MELEE",
		"model_anim_move": "Run_MELEE",
		"model_anim_attack": "TODO",
		"weapon": "tf_weapon_fists",
		"ammo": 0,
		"move_speed": 110
	},
	"ranged":
	{
		"health": 150,
		"damage": 12.0,
		"attack_range": 232.0,
		"attack_range_min": 36.0,
		"aggro_range": 256.0,
		"class": 2,
		"model": "models/bots/sniper/bot_sniper.mdl",
		"model_scale": 0.6,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_PRIMARY",
		"model_anim_move": "Run_PRIMARY",
		"model_anim_attack": "TODO",
		"weapon": "tf_weapon_sniperrifle",
		"ammo": 25,
		"move_speed": 100
	}
}