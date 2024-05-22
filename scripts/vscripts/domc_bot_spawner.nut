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
    }

    function OnRoundStart()
    {
        this.active = true;
        this.SpawnBot();
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

        if (Time() - this.lastSpawnTime >= BOT_SPAWN_INTERVAL)
        {
            this.SpawnBot();
        }
    }

    function SpawnBot()
    {
        this.lastSpawnTime = Time();
        this.wave++;
        if (this.botType == TF_BOT_TYPE["SIEGE"] && this.wave % BOT_SIEGE_INTERVAL != 0)
        {
            return;
        }
        local bot = Bot(this.botType, this.team, this.lane, this.pos, this.ang, this.mega);
        ::gamemode_domc.bots.append(bot);
    }
}
