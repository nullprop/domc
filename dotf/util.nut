::Log <- function(msg)
{
    local time = Time();
    printl(format("[dotf][%.2f] | %s", time, msg));
}

TF_TEAM <-
{
    "UNKNOWN": 0,
    "SPECTATOR": 1,
    "RED": 2,
    "BLU": 3
}

TF_TEAM_NAMES <-
[
    "unknown",
    "spectator",
    "red",
    "blu"
]

enum TF_CLASS
{
    UNKNOWN = 0,
    SCOUT = 1,
    SNIPER = 2,
    SOLDIER = 3,
    DEMOMAN = 4,
    MEDIC = 5,
    HEAVY = 6,
    PYRO = 7,
    SPY = 8,
    ENGINEER = 9
}

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