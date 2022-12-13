::Log <- function(msg)
{
    local time = Time();
    printl(format("[domc][%.2f] | %s", time, msg));
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
    "RANGED": 1,
    "SIEGE": 2
}

TF_BOT_TYPE_NAME <-
[
    "melee",
    "ranged",
    "siege"
]

MASK_PLAYER_SOLID <-
    Constants.FContents.CONTENTS_SOLID |
    Constants.FContents.CONTENTS_PLAYERCLIP |
    Constants.FContents.CONTENTS_WINDOW |
    Constants.FContents.CONTENTS_MONSTER |
    Constants.FContents.CONTENTS_GRATE;

MASK_ATTACK_TRACE <-
    Constants.FContents.CONTENTS_SOLID |
    Constants.FContents.CONTENTS_PLAYERCLIP |
    Constants.FContents.CONTENTS_WINDOW |
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

const FLT_BIG = 100000.0;

IsValidAndAlive <- function(ent)
{
    if (!IsValid(ent))
    {
        return false;
    }

    if (ent.GetHealth() < 0)
    {
        return false;
    }

    return true;
}

IsValid <- function(ent)
{
    if (ent == null)
    {
        return false;
    }

    if (!ent.IsValid())
    {
        return false;
    }

    return true;
}

GetTopOwner <- function(ent)
{
    local owner = ent.GetOwner();
    local top = null;
    local ownerCount = 0; // sanity
    while (IsValid(owner) && ownerCount < 10)
    {
        top = owner;
        owner = owner.GetOwner();
        ownerCount++;
    }
    return top;
}

RandomElement <- function(arr)
{
    local len = arr.len();
    if (len == 0)
    {
        return null;
    }
    if (len == 1)
    {
        return arr[0];
    }
    return arr[RandomInt(0, len - 1)];
}

TrajectoryDistance <- function(velX, velY, gravity)
{
    // parabolic trajectory
    // y = h0 + (sinθ)v0t - (g/2)t2
    // x = (cosθ)v0t
    // -->
    // assume start height is 0,
    // don't care about the angle since
    // we pass velX and velY directly
    // -->
    // y = velY * t - (g/2) * t^2
    // x = velX * t
    // -->
    // assume start and end are at the same height (y = 0)
    // -->
    // (g/2) * t^2 = velY * t
    // (g/2) * t = velY
    // t = 2 * velY / g
    // x = velX * 2 * velY / g

    return velX * 2.0 * velY / gravity;
}

TrajectoryVertVel <- function(distX, velX, gravity)
{
    // x = velX * 2 * velY / g
    // x * g = velX * 2 * velY
    // velY = x * g / (2 * velX)
    return distX * gravity * 0.5 / velX;
}