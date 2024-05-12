DoIncludeScript("domc_util.nut", null);

TOWER_SETTINGS <-
[
	{
		"health": 5000,
		"damage": 15.0,
	},
    {
		"health": 5500,
		"damage": 15.0,
	},
    {
		"health": 6000,
		"damage": 20.0,
	}
];

class Tower
{
    sentryEnt = null;
    towerSettings = null;
    tier = null;
    laneIndex = null;
    team = null;
    protected = false;
    protectedFx = null;

    constructor(team, tier, laneIndex, pos, ang)
    {
        if (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE)
        {
            error(format"Invalid tower team %d", team);
        }

        this.towerSettings = TOWER_SETTINGS[tier];
        this.tier = tier;
        this.laneIndex = laneIndex;
        this.team = team;

        local skin = 1;
        if (team == Constants.ETFTeam.TF_TEAM_RED)
        {
            skin = 0;
        }

        this.sentryEnt = SpawnEntityFromTable(
            "obj_sentrygun",
            {
                targetname = format("tower_%s_%d_%d", TF_TEAM_NAMES[team], tier, laneIndex),
                origin = pos,
                angles = ang,
                health = this.towerSettings["health"],
                defaultupgrade = tier,
                SolidToPlayer = 1
            }
        );

        this.sentryEnt.SetTeam(team);
        EntFireByHandle(this.sentryEnt, "Skin", "" + skin, 0.0, null, null);

        // buildings do weird stuff with health
        NetProps.SetPropInt(this.sentryEnt, "m_iMaxHealth", this.towerSettings["health"]);
        EntFireByHandle(this.sentryEnt, "SetHealth", "" + this.towerSettings["health"], 0.0, null, null);

        // prevent upgrades
        NetProps.SetPropInt(this.sentryEnt, "m_iUpgradeLevel", tier + 1);
        NetProps.SetPropInt(this.sentryEnt, "m_iHighestUpgradeLevel", tier + 1);

        // prevent repair
        NetProps.SetPropBool(this.sentryEnt, "m_bDisposableBuilding", true);

        // Add think
        if (!this.sentryEnt.ValidateScriptScope())
        {
            Log("Failed to validate tower script scope");
            return;
        }
        this.sentryEnt.GetScriptScope().my_tower <- this;
        AddThinkToEnt(this.sentryEnt, "TowerThink");
    }

    function Update()
    {
        // refill ammo
        local shellCount = 150;
        local rocketCount = 0;
        if (this.tier > 0)
        {
            shellCount = 200;
        }
        if (this.tier > 1)
        {
            rocketCount = 20;
        }
        NetProps.SetPropInt(this.sentryEnt, "m_iAmmoShells", shellCount);
        NetProps.SetPropInt(this.sentryEnt, "m_iAmmoRockets", rocketCount);
    }

    function GetDamage()
    {
        return this.towerSettings["damage"];
    }

    function GetEnt()
    {
        return this.sentryEnt;
    }

    function OnTakeDamage(params)
    {
        if (this.protected)
        {
            params.damage = 0;
            return false;
        }

        if (params.damage >= this.sentryEnt.GetHealth())
        {
            return true;
        }

        return false;
    }

    function Kill()
    {
        if (IsValid(this.sentryEnt))
        {
            this.sentryEnt.Kill();
        }
        if (IsValid(this.protectedFx))
        {
            this.protectedFx.Kill();
        }
    }

    function SetProtected(value)
    {
        if (this.protected == value)
        {
            return;
        }

        this.protected = value;

        if (value)
        {
            this.protectedFx = SpawnEntityFromTable("info_particle_system",
            {
                // TODO: use a different particle, this one is not all that visible
                effect_name = format("teleporter_%s_entrance", TF_TEAM_NAMES_PARTICLES[this.team]),
                targetname = format("tower_fx_%s_%d_%d", TF_TEAM_NAMES[this.team], this.tier, this.laneIndex),
                origin = this.sentryEnt.GetOrigin(),
                start_active = true
            });
        }
        else if (IsValid(this.protectedFx))
        {
            this.protectedFx.Kill();
        }
    }
}

function TowerThink()
{
	return self.GetScriptScope().my_tower.Update();
}