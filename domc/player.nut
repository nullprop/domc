DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/settings.nut", null);

const SENTRY_PROTECT_INTERVAL = 1.0;
const SENTRY_PROTECT_RADIUS = 512.0;
const XP_PER_LEVEL = 1000;
const MAX_LEVEL = 20;

CLASS_SETTINGS <-
[
    // UNKNOWN
    {
        "hp_base": 125,
        "hp_per_level": 10,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.4
    },
	// SCOUT
    {
        "hp_base": 125,
        "hp_per_level": 10,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.4
    },
	// SNIPER
    {
        "hp_base": 125,
        "hp_per_level": 10,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.4
    },
	// SOLDIER
    {
        "hp_base": 200,
        "hp_per_level": 20,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.6,
        "regen_per_level": 1.0
    },
	// DEMOMAN
    {
        "hp_base": 175,
        "hp_per_level": 15,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.7,
        "regen_per_level": 0.8
    },
	// MEDIC
    {
        "hp_base": 150,
        "hp_per_level": 15,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.7,
        "regen_per_level": 1.0
    },
	// HEAVY
    {
        "hp_base": 300,
        "hp_per_level": 30,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.6,
        "regen_per_level": 2.0
    },
	// PYRO
    {
        "hp_base": 175,
        "hp_per_level": 15,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.8
    },
	// SPY
    {
        "hp_base": 125,
        "hp_per_level": 10,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.8
    },
	// ENGINEER
    {
        "hp_base": 125,
        "hp_per_level": 10,
        "damage_deal_mult": 0.2,
        "damage_take_mult": 1.0,
        "heal_deal_mult": 0.2,
        "heal_take_mult": 1.0,
        "regen_base": 0.8,
        "regen_per_level": 0.4
    },
]

class Player
{
    playerEnt = null;

    classId = null;
    classSettings = null;

    lastThinkTime = null;
    storedRegen = 0.0;

    lastSentryProtectTime = 0.0;

    level = 1;
    xp = 0;

    applySpawn = false;

    constructor(ent)
    {
        this.playerEnt = ent;
        this.lastThinkTime = Time();

        this.ApplyClassSettings();
    }

    function ApplyClassSettings()
    {
        this.classId = NetProps.GetPropInt(this.playerEnt, "m_PlayerClass.m_iClass");
        this.classSettings = CLASS_SETTINGS[classId];

        local hpFraction = this.playerEnt.GetHealth().tofloat() / this.playerEnt.GetMaxHealth().tofloat();

        local hpBonus = this.level * this.classSettings["hp_per_level"];
        this.playerEnt.RemoveCustomAttribute("max health additive bonus");
        this.playerEnt.AddCustomAttribute("max health additive bonus", hpBonus, -1.0);

        this.playerEnt.SetHealth((hpFraction * this.playerEnt.GetMaxHealth()).tointeger());
    }

    function OnRoundStart()
    {

    }

    function OnSpawn()
    {
        Log("Player.OnSpawn");
        // Apply class settings next think, doesn't work here
        this.applySpawn = true;
    }

    function OnGainXP(amount)
    {
        if (this.level >= MAX_LEVEL)
        {
            return;
        }

        this.xp += amount;

        while (this.xp >= XP_PER_LEVEL && this.level < MAX_LEVEL)
        {
            this.xp -= XP_PER_LEVEL;
            this.level++;
            this.ApplyClassSettings();

            if (this.level >= MAX_LEVEL)
            {
                this.xp = 0;
            }

            Log(format("Player %d leveled up to %d", this.playerEnt.entindex(), this.level));
        }
    }

    function Think()
    {
        local time = Time();
        local deltaTime = time - lastThinkTime;
        this.lastThinkTime = time;

        if (!IsValidAndAlive(this.playerEnt))
        {
            return;
        }

        if (this.applySpawn)
        {
            this.applySpawn = false;
            this.ApplyClassSettings();
        }

        // regen, store as float, heal with ints
        local regenAmount = this.classSettings["regen_base"];
        regenAmount += this.level * this.classSettings["regen_per_level"];

        this.storedRegen += deltaTime * regenAmount;
        local amountToRegen = 0;

        while(this.storedRegen >= 1.0)
        {
            this.storedRegen -= 1.0;
            amountToRegen += 1;
        }

        if (amountToRegen > 0)
        {
            this.playerEnt.SetHealth(this.playerEnt.GetHealth() + amountToRegen);
        }

        // no overheal
        local maxHealth = this.playerEnt.GetMaxHealth();
        if (this.playerEnt.GetHealth() > maxHealth)
        {
            this.playerEnt.SetHealth(maxHealth);
        }

        // refill reserve ammo
        local weapon = this.playerEnt.GetActiveWeapon();
        if (weapon && !weapon.IsMeleeWeapon())
        {
            if (weapon.UsesPrimaryAmmo())
            {
                NetProps.SetPropIntArray(this.playerEnt, "m_iAmmo", 99, weapon.GetPrimaryAmmoType());
            }
            if (weapon.UsesSecondaryAmmo())
            {
                NetProps.SetPropIntArray(this.playerEnt, "m_iAmmo", 99, weapon.GetSecondaryAmmoType());
            }
        }

        if (time - this.lastSentryProtectTime > SENTRY_PROTECT_INTERVAL)
        {
            this.UpdateSentryProtection();
            this.lastSentryProtectTime = time;
        }
    }

    function UpdateSentryProtection()
    {
        // Add FL_NOTARGET if near friendly bots or towers
        // so sentries attack bots first
        local ent = null;
        local protected = false;
        local myTeam = this.playerEnt.GetTeam();
        while (ent = Entities.FindInSphere(ent, this.playerEnt.GetOrigin(), SENTRY_PROTECT_RADIUS))
        {
            local team = ent.GetTeam();
            if (team != myTeam)
            {
                continue;
            }

            local classname = ent.GetClassname();
            if (classname != "base_boss" && classname != "obj_sentrygun")
            {
                continue;
            }

            protected = true;
            break;
        }

        if (protected)
        {
            this.playerEnt.AddFlag(Constants.FPlayer.FL_NOTARGET);
        }
        else
        {
            this.playerEnt.RemoveFlag(Constants.FPlayer.FL_NOTARGET);
        }
    }
}
