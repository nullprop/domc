DoIncludeScript("dotf/util.nut", null);
DoIncludeScript("dotf/settings.nut", null);

class Bot
{
    botEnt = null;
    botType = null;
    botTypeName = null;
    team = null;
    teamName = null;
    botSettings = null;

    constructor(type, team, pos, ang){
        this.botType = type;
        this.botTypeName = TF_BOT_TYPE_NAME[type];
        this.team = team;
        this.teamName = TF_TEAM_NAMES[team];
        this.botSettings = BOT_SETTINGS[this.botTypeName];

        this.botEnt = Entities.CreateByClassname("prop_dynamic");
        this.botEnt.SetModelSimple(this.botSettings["model"]);
        this.botEnt.SetModelScale(this.botSettings["model_scale"], 0.0);
        this.botEnt.SetSkin(this.botSettings["model_skin_" + this.teamName]);
        NetProps.SetPropInt(this.botEnt, "m_bClientSideAnimation", 1);

        this.botEnt.SetTeam(team);

        this.botEnt.SetAbsOrigin(pos);
        this.botEnt.SetAbsAngles(QAngle(ang));

        this.botEnt.DispatchSpawn();

        // can get reset on spawn depending on classname
        this.botEnt.SetMaxHealth(this.botSettings["health"]);
        this.botEnt.SetHealth(this.botSettings["health"]);

        this.PlayAnim(this.botSettings["model_anim_move"]);
        this.botEnt.SetPoseParameter(0, 1.0); # TODO: ask if string version could be exposed
    }

    function Think()
    {

    }

    function PlayAnim(name)
    {
        local seq = this.botEnt.LookupSequence(name);
        this.botEnt.ResetSequence(seq);
    }
}