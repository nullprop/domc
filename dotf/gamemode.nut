DoIncludeScript("dotf/util.nut", null);
DoIncludeScript("dotf/player.nut", null);

function Precache()
{
    PrecacheModel("models/bots/heavy/bot_heavy.mdl");
    PrecacheModel("models/bots/sniper/bot_sniper.mdl");
}

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

    constructor()
    {
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
