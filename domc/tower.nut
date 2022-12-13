DoIncludeScript("domc/util.nut", null);

TOWER_SETTINGS <-
[
	{
		"health": 12000,
		"damage": 10.0,
	},
    {
		"health": 20000,
		"damage": 20.0,
	},
    {
		"health": 25000,
		"damage": 30.0,
	}
];

class Tower
{
    sentryEnt = null;
    towerSettings = null;
    tier = null;
    laneIndex = null;
    team = null;

    constructor(tier, team, laneIndex, pos, ang)
    {
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
        NetProps.SetPropInt(this.sentryEnt, "m_iUpgradeLevel", tier);
        NetProps.SetPropInt(this.sentryEnt, "m_iHighestUpgradeLevel", tier);

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
}

function TowerThink()
{
	return self.GetScriptScope().my_tower.Update();
}