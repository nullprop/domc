DoIncludeScript("domc_util.nut", null);

const FOUNTAIN_HEALTH = 2000;
const FOUNTAIN_SAP_DURATION = 10.0;

class Fountain
{
    triggerEnt = null;
    dispenserEnt = null;
    team = null;
    protected = false;
    protectedFx = null;
    sapTime = 0.0;
    sapper = null;

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
    }

    function OnTakeDamage(params)
    {
        if (this.protected)
        {
            params.damage = 0;
            return false;
        }

        if (params.damage >= this.dispenserEnt.GetHealth())
        {
            return true;
        }

        return false;
    }

    function Think()
    {
        if (IsValidAndAlive(this.sapper))
        {
            if (Time() - this.sapTime >= FOUNTAIN_SAP_DURATION)
            {
                this.sapper.Kill();
                this.sapper = null;
            }
        }
        else
        {
            this.sapper = null;
            if (NetProps.GetPropBool(this.dispenserEnt, "m_bDisabled"))
            {
                local sapperEnt = null;
                while (sapperEnt = Entities.FindByClassname(sapperEnt, "obj_attachment_sapper"))
                {
                    if (sapperEnt.GetMoveParent() == this.dispenserEnt)
                    {
                        if (this.protected)
                        {
                            sapperEnt.Kill();
                        }
                        else
                        {
                            this.sapper = sapperEnt;
                            this.sapTime = Time();
                        }
                        break;
                    }
                }
            }
        }
    }

    function GetEnt()
    {
        return this.dispenserEnt;
    }

    function GetTeam()
    {
        return this.team;
    }

    function Kill()
    {
        if (IsValid(this.dispenserEnt))
        {
            this.dispenserEnt.Kill();
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
                targetname = format("fountain_fx_%s", TF_TEAM_NAMES[team]),
                origin = this.dispenserEnt.GetOrigin(),
                start_active = true
            });
        }
        else if (IsValid(this.protectedFx))
        {
            this.protectedFx.Kill();
        }
    }
}

