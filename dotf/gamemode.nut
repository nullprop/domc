DoIncludeScript("dotf/util.nut", null);
DoIncludeScript("dotf/player.nut", null);
DoIncludeScript("dotf/bot.nut", null);

PrecacheModel("models/bots/heavy/bot_heavy.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_pelvis.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_arm.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_arm2.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_leg.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_leg2.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_head.mdl");
PrecacheModel("models/bots/gibs/heavybot_gib_chest.mdl");

PrecacheModel("models/bots/sniper/bot_sniper.mdl");
PrecacheModel("models/bots/gibs/sniperbot_gib_head.mdl");

function Think()
{
    if (("gamemode_dotf" in getroottable()))
    {
        ::gamemode_dotf.Think();
    }
}

class GamemodeDotf
{
    players = null;
    bots = null;

    constructor()
    {
        this.bots = [];
        this.players = {};
        local ply = null;
        while(ply = Entities.FindByClassname(ply, "player"))
        {
            this.players[ply.entindex()] <- Player(ply);
        }
    }

    function Think()
    {
        foreach(ply in this.players)
        {
            ply.Think();
        }
        foreach(bot in this.bots)
        {
            bot.Think();
        }
    }

    function OnRoundStart()
    {
        Log("round start");

        foreach(ply in this.players)
        {
            ply.OnRoundStart();
        }
    }

    function AddPlayer(userid)
    {
        if (userid in this.players)
        {
            return;
        }

        local ent = GetPlayerFromUserID(userid);
        if (ent && ent.IsValid() && ent.IsPlayer())
        {
            this.players[userid] <- Player(ent);
        }
    }

    function RemovePlayer(userid)
    {
        if (!(userid in this.players))
        {
            return;
        }

        delete this.players[userid];
    }

    function AddBot(type, team, pos, ang)
    {
        Log(format("AddBot %d, %d", type, team));
        local bot = Bot(type, team, pos, ang);
        this.bots.append(bot);
    }
}

function OnGameEvent_player_spawn(data)
{
    Log("player " + data.userid + " spawned");
    ::gamemode_dotf.AddPlayer(data.userid);
}

function OnGameEvent_player_death(data)
{
    Log("player " + data.userid + " died");
    ::gamemode_dotf.RemovePlayer(data.userid);
}

function OnGameEvent_teamplay_round_start(data)
{
    local collected = collectgarbage();
    Log("gc: deleted " + collected + " ref cycles");

    ::gamemode_dotf.OnRoundStart();
}

function OnGameEvent_teamplay_round_waiting_ends(data)
{
    // TODO: start spawning bots
    Log("teamplay_round_waiting_ends");
}

if (!("gamemode_dotf" in getroottable()))
{
    ::gamemode_dotf <- GamemodeDotf();

    if (!("HOOKED_EVENTS" in getroottable()))
    {
        __CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
        ::HOOKED_EVENTS <- true;
    }
}
else
{
    ::gamemode_dotf.OnRoundStart();
}

::TestBot <- function(type, team)
{
    if ("gamemode_dotf" in getroottable())
    {
        local ply = GetListenServerHost();
        ::gamemode_dotf.AddBot(
            type,
            team,
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles()
        );
    }
}

::TestThink <- function()
{
    if ("gamemode_dotf" in getroottable())
    {
        ::gamemode_dotf.Think();
    }
}

// https://github.com/ValveSoftware/Source-1-Games/issues/4481#issuecomment-1328052130
::TestNav <- function()
{
    local ply = GetListenServerHost();
    local navArea = NavMesh.GetNavArea(ply.GetOrigin(), 512.0);
    printl("navArea " + navArea);
    if (navArea)
    {
        navArea.DebugDrawFilled(0, 255, 0, 100, 5.0, false, 1.0);
    }
}
