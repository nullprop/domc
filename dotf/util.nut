::Log <- function(msg)
{
    local time = Time();
    printl(format("[dotf][%.2f] | %s", time, msg));
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