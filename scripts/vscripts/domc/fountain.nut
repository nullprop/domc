DoIncludeScript("domc/util.nut", null);

const FOUNTAIN_HEALTH = 2000;

class Fountain
{
    triggerEnt = null;
    dispenserEnt = null;
    team = null;

    constructor(team, pos, ang)
    {
        if (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE)
        {
            error(format"Invalid fountain team %d", team);
        }

        this.team = team;

        local skin = 1;
        if (team == Constants.ETFTeam.TF_TEAM_RED)
        {
            skin = 0;
        }

        local dispenserName = format("fountain_%s", TF_TEAM_NAMES[team]);
        local triggerName = dispenserName + "_trigger";

        this.dispenserEnt = SpawnEntityFromTable(
            "obj_dispenser",
            {
                targetname = dispenserName,
                origin = pos,
                angles = ang,
                defaultupgrade = 2,
                SolidToPlayer = 1,
                touch_trigger = triggerName,
                health = FOUNTAIN_HEALTH,
            }
        );

        this.dispenserEnt.SetTeam(team);
        EntFireByHandle(this.dispenserEnt, "Skin", "" + skin, 0.0, null, null);
        this.dispenserEnt.SetModelScale(3.0, 0.0);

        // buildings do weird stuff with health
        NetProps.SetPropInt(this.dispenserEnt, "m_iMaxHealth", FOUNTAIN_HEALTH);
        EntFireByHandle(this.dispenserEnt, "SetHealth", "" + FOUNTAIN_HEALTH, 0.0, null, null);

        // prevent upgrades
        NetProps.SetPropInt(this.dispenserEnt, "m_iUpgradeLevel", 2);
        NetProps.SetPropInt(this.dispenserEnt, "m_iHighestUpgradeLevel", 2);

        // prevent repair
        NetProps.SetPropBool(this.dispenserEnt, "m_bDisposableBuilding", true);

        // Add think
        if (!this.dispenserEnt.ValidateScriptScope())
        {
            Log("Failed to validate fountain script scope");
            return;
        }
        this.dispenserEnt.GetScriptScope().my_fountain <- this;
        AddThinkToEnt(this.dispenserEnt, "FountainThink");
    }

    function Update()
    {

    }

    function GetEnt()
    {
        return this.dispenserEnt;
    }
}

function FountainThink()
{
	return self.GetScriptScope().my_fountain.Update();
}
