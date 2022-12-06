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
