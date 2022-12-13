DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/player.nut", null);
DoIncludeScript("domc/bot.nut", null);
DoIncludeScript("domc/bot_spawner.nut", null);
DoIncludeScript("domc/tower.nut", null);
DoIncludeScript("domc/fountain.nut", null);
DoIncludeScript("domc/lane.nut", null);

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

PrecacheModel("models/bots/demo_boss/bot_demo_boss.mdl");

PrecacheModel("models/items/currencypack_small.mdl");
PrecacheModel("models/items/currencypack_medium.mdl");
PrecacheModel("models/items/currencypack_large.mdl");


class GamemodeDomc
{
    players = {};
    bots = [];
    towers = [];
    lanes = [];
    fountains = [];
    spawners = [];

    constructor()
    {
        local ply = null;
        while(ply = Entities.FindByClassname(ply, "player"))
        {
            this.players[ply.entindex()] <- Player(ply);
        }
        for (local i = 0; i < 3; i++)
        {
            this.lanes.append(Lane());
        }
    }

    function Think()
    {
        foreach(ply in this.players)
        {
            ply.Think();
        }

        foreach(spawner in this.spawners)
        {
            spawner.Think();
        }
    }

    function OnRoundStart()
    {
        Log("round start");

        foreach(ply in this.players)
        {
            ply.OnRoundStart();
        }

        foreach(spawner in this.spawners)
        {
            spawner.OnRoundStart();
        }
    }

    function AddPlayer(userid)
    {
        local ent = GetPlayerFromUserID(userid);
        local entindex = ent.entindex();
        if (entindex in this.players)
        {
            return;
        }

        if (ent && ent.IsValid() && ent.IsPlayer())
        {
            this.players[entindex] <- Player(ent);
        }
    }

    function OnPlayerSpawn(userid)
    {
        local ent = GetPlayerFromUserID(userid);
        local entindex = ent.entindex();
        if (!(entindex in this.players))
        {
            Log(format("OnPlayerSpawn called for %d but not in players", userid));
            return;
        }

        if (ent && ent.IsValid() && ent.IsPlayer())
        {
            this.players[entindex].OnSpawn();
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

    function AddTower(tier, team, laneIndex, pos, ang)
    {
        Log(format("AddTower %d, %d, %d", tier, team, laneIndex));
        local tower = Tower(tier, team, laneIndex, pos, ang);
        this.towers.append(tower);
    }

    function AddFountain(team, pos, ang)
    {
        Log(format("AddFountain %d", team));
        local fountain = Fountain(team, pos, ang);
        this.fountains.append(fountain);
    }

    function AddNodeToLane(laneIndex, pos)
    {
        Log(format("AddNodeToLane %d %s", laneIndex, pos.tostring()));
        this.lanes[laneIndex].AddNode(pos);
    }

    function DebugDrawLanes(duration)
    {
        foreach (lane in this.lanes)
        {
            lane.DebugDraw(duration);
        }
    }

    function GetPlayer(ent)
    {
        local entindex = ent.entindex();
        if (entindex in this.players)
        {
            return this.players[entindex];
        }
        return null;
    }

    function GetBot(ent)
    {
        foreach(bot in this.bots)
        {
            if (bot.GetEnt() == ent)
            {
                return bot;
            }
        }

        return null;
    }

    function GetTower(ent)
    {
        foreach (tower in this.towers)
        {
            if (tower.GetEnt() == ent)
            {
                return tower;
            }
        }

        return null;
    }

    function GetFountain(ent)
    {
        foreach (fountain in this.fountains)
        {
            if (fountain.GetEnt() == ent)
            {
                return fountain;
            }
        }

        return null;
    }

    function CollectGarbage()
    {
        local garbageBots = 0;
        for (local i = this.bots.len() - 1; i >= 0; i--)
        {
            if (!IsValidAndAlive(this.bots[i].GetEnt()))
            {
                this.bots.remove(i);
                garbageBots++;
            }
        }

        local garbageTowers = 0;
        for (local i = this.towers.len() - 1; i >= 0; i--)
        {
            if (!IsValidAndAlive(this.towers[i].GetEnt()))
            {
                this.towers.remove(i);
                garbageTowers++;
            }
        }

        local collected = collectgarbage();
        Log(format(
            "CollectGarbage: removed %d bots, %d towers, collected %d ref cycles",
            garbageBots,
            garbageTowers,
            collected
        ));
    }
}

// --------------------------------
// Events
// --------------------------------

function OnGameEvent_player_spawn(data)
{
    Log("player " + data.userid + " spawned");
    ::gamemode_domc.AddPlayer(data.userid);
    ::gamemode_domc.OnPlayerSpawn(data.userid);
}

function OnGameEvent_player_death(data)
{
    Log("player " + data.userid + " died");
}

function OnGameEvent_teamplay_round_start(data)
{
    ::gamemode_domc.OnRoundStart();
}

function OnGameEvent_teamplay_round_waiting_ends(data)
{
    // TODO: start spawning bots
    Log("teamplay_round_waiting_ends");
}

// --------------------------------
// Hooks
// --------------------------------

function OnScriptHook_OnTakeDamage(params)
{
    local ent = params.const_entity;
	local inf = params.inflictor;
    local entClassname = ent.GetClassname();
    local infClassname = inf.GetClassname();
    local entName = ent.GetName();
    local infName = inf.GetName();
    //Log(format("take dmg | %s (%s) -> %s (%s) : %d", infClassname, infName, entClassname, entName, params.damage));

    // Don't crush things
    if (infClassname == "base_boss" && params.damage_type == Constants.FDmgType.DMG_CRUSH)
    {
        params.damage = 0;
        return;
    }

    // Can't damage fountains
    if (::gamemode_domc.GetFountain(ent))
    {
        params.damage = 0;
        return;
    }

    // Apply proper tower dmg
    if (infClassname == "obj_sentrygun")
    {
        local tower = ::gamemode_domc.GetTower(inf);
        if (tower)
        {
            params.damage = tower.GetDamage();
        }
    }

    // Player inflictor dmg bonus
    local trueInf = GetTrueInflictor(inf);
    local player = ::gamemode_domc.GetPlayer(trueInf);
    if (player)
    {
        params.damage *= player.GetDamageMult();
    }

    // Bot callback for aggro
    if (entClassname == "base_boss")
    {
        local bot = ::gamemode_domc.GetBot(ent);
        if (bot)
        {
            bot.OnTakeDamage(params);
        }
    }
}

// --------------------------------
// Init
// --------------------------------

function Think()
{
    if (("gamemode_domc" in getroottable()))
    {
        ::gamemode_domc.Think();
    }
}

if (!("gamemode_domc" in getroottable()))
{
    ::gamemode_domc <- GamemodeDomc();

    if (!("HOOKED_EVENTS" in getroottable()))
    {
        __CollectGameEventCallbacks(this);
        ::HOOKED_EVENTS <- true;
    }

    local thinker = SpawnEntityFromTable("info_target", { targetname = "domc_gamemode" } );
    if(thinker.ValidateScriptScope())
    {
        thinker.GetScriptScope()["Think"] <- Think;
        AddThinkToEnt(thinker, "Think");
    }
}
else
{
    ::gamemode_domc.OnRoundStart();
}

// --------------------------------
// Test functions
// --------------------------------

::TestBot <- function(type, team, laneIndex)
{
    if ("gamemode_domc" in getroottable())
    {
        local ply = GetListenServerHost();
        Bot(
            type,
            team,
            ::gamemode_domc.lanes[laneIndex],
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles()
        );
    }
}

::TestSpawner <- function(type, team, laneIndex)
{
    if ("gamemode_domc" in getroottable())
    {
        local ply = GetListenServerHost();
        local spawner = BotSpawner(
            team,
            type,
            ::gamemode_domc.lanes[laneIndex],
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles()
        );
        ::gamemode_domc.spawners.append(spawner);
        spawner.OnRoundStart();
    }
}

::TestTower <- function(tier, team, laneIndex)
{
    if ("gamemode_domc" in getroottable())
    {
        local ply = GetListenServerHost();
        ::gamemode_domc.AddTower(
            tier,
            team,
            laneIndex,
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles()
        );
    }
}

::TestFountain <- function(team)
{
    if ("gamemode_domc" in getroottable())
    {
        local ply = GetListenServerHost();
        ::gamemode_domc.AddFountain(
            team,
            ply.EyePosition() + ply.GetForwardVector()*256,
            ply.GetAbsAngles()
        );
    }
}

::GiveXP <- function(amount)
{
    if ("gamemode_domc" in getroottable())
    {
        foreach(player in ::gamemode_domc.players)
        {
            player.OnGainXP(amount);
        }
    }
}

::AddLaneNode <- function(laneIndex)
{
    local ply = GetListenServerHost();
    ::gamemode_domc.AddNodeToLane(laneIndex, ply.GetOrigin());
}

::DebugDrawLanes <- function()
{
    ::gamemode_domc.DebugDrawLanes(10.0);
}

::TestGC <- function()
{
    ::gamemode_domc.CollectGarbage();
}