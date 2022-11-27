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
    Constants.ContentsFlags.CONTENTS_SOLID |
    Constants.ContentsFlags.CONTENTS_PLAYERCLIP |
    Constants.ContentsFlags.CONTENTS_WINDOW |
    Constants.ContentsFlags.CONTENTS_MONSTER |
    Constants.ContentsFlags.CONTENTS_GRATE;
