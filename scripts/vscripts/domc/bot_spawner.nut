DoIncludeScript("domc/bot.nut", null);

const BOT_SPAWN_INTERVAL = 45.0;

class BotSpawner
{
    team = null;
    botType = null;
    laneIndex = 0;
    lane = null;
    pos = null;
    ang = null;
    lastSpawnTime = 0.0;
    active = false;

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

    function Think()
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
        local bot = Bot(this.botType, this.team, this.lane, this.pos, this.ang);
        ::gamemode_domc.bots.append(bot);
    }
}