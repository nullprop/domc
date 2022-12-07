DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/settings.nut", null);

class Player
{
    playerEnt = null;

    classId = null;
    classSettings = null;

    lastRegenTime = null;

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
    }
}
