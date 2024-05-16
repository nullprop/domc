DoIncludeScript("domc_util.nut", null);
DoIncludeScript("domc_player.nut", null);
DoIncludeScript("domc_bot.nut", null);
DoIncludeScript("domc_bot_spawner.nut", null);
DoIncludeScript("domc_tower.nut", null);
DoIncludeScript("domc_fountain.nut", null);
DoIncludeScript("domc_lane.nut", null);

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

const XP_AWARD_RADIUS = 1024.0;

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
    }

    function Think()
    {
        // yikes, workaround for no player disconnect hook
        local validPlayers = [];
        local plyEnt = null;
        while (plyEnt = Entities.FindByClassname(plyEnt, "player"))
        {
            validPlayers.append(plyEnt.entindex());
        }
        foreach (entindex in this.players.keys())
        {
            if (validPlayers.find(entindex) == null)
            {
                Log("remove player");
                delete this.players[entindex];
            }
        }

        foreach (ply in this.players)
        {
            ply.Think();
        }

        foreach (spawner in this.spawners)
        {
            spawner.Think();
        }
    }

    function Reset()
    {
        foreach(ply in this.players)
        {
            ply.Reset();
        }
        foreach(bot in this.bots)
        {
            bot.Kill();
        }
        foreach(tower in this.towers)
        {
            tower.Kill();
        }
        foreach(fountain in this.fountains)
        {
            fountain.Kill();
        }
        this.bots = [];
        this.towers = [];
        this.fountains = [];
        this.spawners = [];
        this.lanes = [];
        CollectGarbage();

        local target = null;
        while(target = Entities.FindByClassname(target, "info_target"))
        {
            local parts = split(target.GetName(), "_");
            if (parts.len() <= 0)
            {
                continue;
            }

            if (parts[0] == "tower")
            {
                local team = TeamNameToEnum(parts[1]);
                local tier = parts[2].tointeger();
                local laneIndex = parts[3].tointeger();
                this.towers.append(Tower(team, tier, laneIndex, target.GetOrigin(), target.GetAbsAngles()));
            }

            if (parts[0] == "lane")
            {
                local laneIndex = parts[1].tointeger();
                local nodeIndex = parts[2].tointeger();
                while (laneIndex >= this.lanes.len())
                {
                    this.lanes.append(Lane());
                }
                this.lanes[laneIndex].AddNode(nodeIndex, target.GetOrigin());
            }

            if (parts[0] == "spawner")
            {
                local team = TeamNameToEnum(parts[1]);
                local type = parts[2].tointeger();
                local laneIndex = parts[3].tointeger();
                this.spawners.append(
                    BotSpawner(
                        team,
                        type,
                        laneIndex,
                        target.GetOrigin(),
                        target.GetAbsAngles()
                    )
                );
            }

            if (parts[0] == "fountain")
            {
                local team = TeamNameToEnum(parts[1]);
                this.fountains.append(Fountain(team, target.GetOrigin(), target.GetAbsAngles()));
            }
        }

        foreach(lane in this.lanes)
        {
            lane.Finalize();
        }

        foreach(spawner in this.spawners)
        {
            spawner.lane = this.lanes[spawner.laneIndex];
        }

        foreach(tower in this.towers)
        {
            if (tower.tier != 0)
            {
                tower.SetProtected(true);
            }
        }

        foreach(fountain in this.fountains)
        {
            fountain.SetProtected(true);
        }
    }

    function OnRoundStart()
    {
        Log("round start");

        Convars.SetValue("sv_turbophysics", 0);

        Reset();

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
            Log(format("OnPlayerSpawn called for (%d, %d) but not in players", userid, entindex));
            return;
        }

        if (ent && ent.IsValid() && ent.IsPlayer())
        {
            this.players[entindex].OnSpawn();
        }
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
            if (!IsValid(this.bots[i].GetEnt()))
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

    function RemoveBot(bot)
    {
        for (local i = this.bots.len() - 1; i >= 0; i--)
        {
            if (this.bots[i] == bot)
            {
                this.bots.remove(i);
            }
        }
    }

    function AwardXP(team, amount, pos)
    {
        local inRange = [];
        foreach(player in this.players)
        {
            if (player.GetTeam() != team)
            {
                continue;
            }

            if ((pos - player.GetPos()).Length() > XP_AWARD_RADIUS)
            {
                continue;
            }

            inRange.append(player);
        }

        local playerCount = inRange.len();
        if (playerCount == 0)
        {
            return;
        }

        local splitAmount = amount.tofloat() / playerCount;
        foreach(player in inRange)
        {
            player.OnGainXP(splitAmount);
        }
    }

    function TeamLose(team)
    {
        local winningTeam = GetOppositeTeam(team);

        // Should these just be in the .bsp? ¯\_(-_-)_/¯
        local winEnt = SpawnEntityFromTable(
            "game_round_win",
            {
                targetname = format("game_round_win_%d", winningTeam),
                origin = Vector(0, 0, 0),
                angles = Vector(0, 0, 0),
                switch_teams = true,
                force_map_reset = true,
                TeamNum = winningTeam
            }
        );
        EntFireByHandle(winEnt, "RoundWin", "", 0, null, null);
        winEnt.Kill();

        foreach (spawner in this.spawners)
        {
            spawner.OnRoundEnd();
        }

        foreach (bot in this.bots)
        {
            bot.OnRoundEnd(winningTeam == bot.team);
        }
    }

    function TowerDestroyed(destroyed)
    {
        // Check fountain protection is last tower destroyed
        if (destroyed.tier == 2)
        {
            foreach(fountain in this.fountains)
            {
                if (fountain.team == destroyed.team)
                {
                    fountain.SetProtected(false);
                    break;
                }
            }
        }
        // Otherwise, check next tower
        else
        {
            foreach(tower in this.towers)
            {
                local removeProtection = false;
                if (destroyed.team == tower.team)
                {
                    if (destroyed.tier == 1 && tower.tier == 2)
                    {
                        removeProtection = true;
                    }
                    else if (
                        destroyed.tier == 0
                        && tower.tier == 1
                        && destroyed.laneIndex == tower.laneIndex
                    )
                    {
                        removeProtection = true;
                    }
                }
                if (removeProtection) 
                {
                    tower.SetProtected(false);
                    break;
                }
            }
        }

        // Start spawning mega creeps for opposite team if 2nd tower
        if (destroyed.tier == 1)
        {
            foreach (spawner in this.spawners)
            {
                if (
                    spawner.laneIndex == destroyed.laneIndex
                    && spawner.team != destroyed.team
                )
                {
                    spawner.mega = true;
                }
            }
        }
    }
}

// --------------------------------
// Events
// --------------------------------

function OnGameEvent_player_spawn(data)
{
    Log("player uid " + data.userid + " spawned");
    ::gamemode_domc.AddPlayer(data.userid);
    ::gamemode_domc.OnPlayerSpawn(data.userid);
}

function OnGameEvent_player_death(data)
{
    Log("player uid " + data.userid + " died");

    local ent = GetPlayerFromUserID(data.userid);
    local player = ::gamemode_domc.GetPlayer(ent);

    if (player)
    {
        ::gamemode_domc.AwardXP(GetOppositeTeam(player.GetTeam()), player.xpAward, player.GetPos());
    }
}

function OnGameEvent_teamplay_round_active(data)
{
    ::gamemode_domc.OnRoundStart();
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
    local trueInf = GetTrueInflictor(inf);
    local trueInfClassname = trueInf.GetClassname();
    local trueInfName = trueInf.GetName();
    /*
    Log(format("take dmg | %s (%s) [%s (%s)] -> %s (%s) : %d",
        infClassname,
        infName,
        trueInfClassname,
        trueInfName,
        entClassname,
        entName,
        params.damage
    ));
    */

    // Don't crush things
    if (infClassname == "base_boss" && params.damage_type == Constants.FDmgType.DMG_CRUSH)
    {
        params.damage = 0;
        return;
    }

    local damageDistance = (ent.GetOrigin() - trueInf.GetOrigin()).Length();

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
    local player = ::gamemode_domc.GetPlayer(trueInf);
    if (player)
    {
        local applyFalloff = true;
        if (entClassname == "player")
        {
            // Game already applies falloff to player-to-player dmg.
            applyFalloff = false;
        }
        params.damage *= player.GetDamageMult(applyFalloff, damageDistance);
    }

    // Bot callback for aggro + award xp
    if (entClassname == "base_boss")
    {
        local bot = ::gamemode_domc.GetBot(ent);
        if (bot)
        {
            local dead = bot.OnTakeDamage(params);
            if (dead)
            {
                ::gamemode_domc.AwardXP(GetOppositeTeam(bot.team), bot.xpAward, bot.GetPos());
                ::gamemode_domc.RemoveBot(bot);
            }
        }
    }

    local fountain = ::gamemode_domc.GetFountain(ent);
    if (fountain)
    {
        if (fountain.OnTakeDamage(params))
        {
            ::gamemode_domc.TeamLose(fountain.GetTeam());
        }
    }

    local targetTower = ::gamemode_domc.GetTower(ent);
    if (targetTower)
    {
        if (targetTower.OnTakeDamage(params))
        {
            ::gamemode_domc.TowerDestroyed(targetTower);
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

    // >:(
    local cash = null;
    while (cash = Entities.FindByClassname(cash, "item_currencypack_custom"))
    {
        cash.Kill();
    }

    return 0.0;
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

::DebugDrawLanes <- function()
{
    ::gamemode_domc.DebugDrawLanes(10.0);
}

::TestGC <- function()
{
    ::gamemode_domc.CollectGarbage();
}
