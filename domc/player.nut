DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/settings.nut", null);

const SENTRY_PROTECT_INTERVAL = 1.0;
const SENTRY_PROTECT_RADIUS = 512.0;

class Player
{
    playerEnt = null;

    classId = null;
    classSettings = null;

    lastRegenTime = null;
    lastSentryProtectTime = 0.0;

    constructor(ent)
    {
        this.playerEnt = ent;
        this.classId = NetProps.GetPropInt(this.playerEnt, "m_PlayerClass.m_iClass");
        this.classSettings = CLASS_SETTINGS[classId];
        this.lastRegenTime = Time();

        this.ApplyClassSettings();
    }

    function ApplyClassSettings()
    {
        this.playerEnt.SetMaxHealth(this.classSettings["health"]);
        this.playerEnt.SetHealth(this.classSettings["health"]);
    }

    function OnRoundStart()
    {
        Log("Player.OnRoundStart");
        this.ApplyClassSettings();
    }

    function Think()
    {
        local time = Time();

        // regen
        local regenInterval = this.classSettings["regen_interval"];
        if (regenInterval > 0)
        {
            local time = Time();
            if (time - this.lastRegenTime > regenInterval)
            {
                this.lastRegenTime += regenInterval;
                local regenAmount = this.classSettings["regen"];
                this.playerEnt.SetHealth(this.playerEnt.GetHealth() + regenAmount);
            }
        }

        // don't allow overheal
        if (this.playerEnt.GetHealth() > this.playerEnt.GetMaxHealth())
        {
            this.playerEnt.SetHealth(this.playerEnt.GetMaxHealth());
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
