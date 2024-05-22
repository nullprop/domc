DoIncludeScript("domc_bot.nut", null);

const BOT_SPAWN_INTERVAL = 30.0;
const BOT_SIEGE_INTERVAL = 1;

class BotSpawner
{
    team = null;
    botType = null;
    laneIndex = 0;
    lane = null;
    pos = null;
    ang = null;
    mega = false;
    lastSpawnTime = 0.0;
    active = false;
    wave = 0;
    // Delay spawn by 1 tick.
    // Avoid server var hitch from too many spawns at same time.
    delaySpawn = false;
    wantsSpawn = false;

    constructor(team, botType, laneIndex, pos, ang)
    {
        if (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE)
        {
            error(format"Invalid spawner team %d", team);
        }

        this.team = team;
        this.botType = botType;
        this.laneIndex = laneIndex;
        this.pos = pos;
        this.ang = ang;

        if (this.botType != TF_BOT_TYPE["MELEE"])
        {
            this.delaySpawn = true;
        }
    }

    function OnRoundStart()
    {
        this.active = true;
        CallSpawn();
    }

    function OnRoundEnd()
    {
        this.active = false;
    }

    function SpawnerThink()
    {
        if (!this.active)
        {
            return;
        }

        if (this.wantsSpawn)
        {
            this.wantsSpawn = false;
            this.SpawnBot();
        }

        if (Time() - this.lastSpawnTime >= BOT_SPAWN_INTERVAL)
        {
            CallSpawn();
        }
    }

    function CallSpawn()
    {
        this.lastSpawnTime = Time();
        this.wave++;
        if (this.delaySpawn)
        {
            this.wantsSpawn = true;
        }
        else
        {
            this.SpawnBot();
        }
    }

    function SpawnBot()
    {
        if (this.botType == TF_BOT_TYPE["SIEGE"] && this.wave % BOT_SIEGE_INTERVAL != 0)
        {
            return;
        }
        local bot = Bot(this.botType, this.team, this.lane, this.pos, this.ang, this.mega);
        ::gamemode_domc.bots.append(bot);
    }
}
