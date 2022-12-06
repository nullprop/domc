::Log <- function(msg)
{
    local time = Time();
    printl(format("[dotf][%.2f] | %s", time, msg));
}

::ClipVelocity <- function(vel, normal, bounce)
{
    local backoff = vel.Dot(normal);

    if (backoff < 0)
    {
        backoff *= bounce;
    }
    else
    {
        backoff /= bounce;
    }

    local change = normal.Scale(backoff);
    return vel - change;
}

TF_TEAM_NAMES <-
[
    "unknown",
    "spectator",
    "red",
    "blu"
]

TF_BOT_TYPE <-
{
    "MELEE": 0,
    "RANGED": 1
}

TF_BOT_TYPE_NAME <-
[
    "melee",
    "ranged"
]

MASK_PLAYER_SOLID <-
    Constants.FContents.CONTENTS_SOLID |
    Constants.FContents.CONTENTS_PLAYERCLIP |
    Constants.FContents.CONTENTS_WINDOW |
    Constants.FContents.CONTENTS_MONSTER |
    Constants.FContents.CONTENTS_GRATE;

::Min <- function(a, b)
{
    if (a < b) return a;
    return b;
}

::Max <- function(a, b)
{
    if (a > b) return a;
    return b;
}

::Clamp <- function(val, min, max)
{
    return Min(Max(val, min), max);
}

class Line
{
    startPos = null;
    endPos = null;
    vec = null;
    vecNorm = null;
    vecDot = null;
    distance = null;

    constructor(startPos, endPos)
    {
        this.startPos = startPos;
        this.endPos = endPos;
        this.vec = endPos - startPos;
        this.distance = this.vec.Length();
        this.vecNorm = this.vec * (1.0 / this.distance);
        this.vecDot = this.startPos.Dot(this.endPos);
    }

    function GetNearestPoint(pos)
    {
        local toPos = pos - this.startPos;
        local frac = toPos.Dot(this.vecNorm);
        frac = Clamp(frac, 0.0, this.distance);
        local nearest = this.startPos + this.vecNorm * frac;
        //DebugDrawLine(pos, nearest, 255, 255, 255, true, 1.0);
        return nearest;
    }

    function Contains(pos)
    {
        local toEnd = this.endPos - pos;
        return this.vec.Dot(toEnd) > 0;
    }

    function DebugDraw(duration)
    {
        DebugDrawLine(this.startPos, this.endPos, 0, 255, 0, true, duration);
    }
}