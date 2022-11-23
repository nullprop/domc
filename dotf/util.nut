::Log <- function(msg)
{
    local time = Time();
    printl(format("[dotf][%.2f] | %s", time, msg));
}