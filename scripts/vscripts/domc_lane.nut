DoIncludeScript("domc_util.nut", null);

const LANE_EPSILON = 128.0;

class NearestPoint
{
    point = null;
    dist = null;
    line = null;

    constructor(point, dist, line)
    {
        this.point = point;
        this.dist = dist;
        this.line = line;
    }
}

class Lane
{
    nodes = []
    lines = []

    constructor()
    {
        this.nodes = [];
        this.lines = [];
    }

    function AddNode(index, pos)
    {
        if (index >= this.nodes.len())
        {
            this.nodes.resize(index + 1, Vector(0, 0, 0));
        }
        this.nodes[index] = pos;
    }

    function Finalize()
    {
        for (local i = 1; i < this.nodes.len(); i++)
        {
            this.lines.append(Line(this.nodes[i - 1], this.nodes[i]));
        }
    }

    function GetNearestPoint(pos)
    {
        local nearest = NearestPoint(null, FLT_BIG, null);

        foreach (line in this.lines)
        {
            local point = line.GetNearestPoint(pos);
            local dist = (point - pos).Length();
            if (dist < nearest.dist)
            {
                nearest.dist = dist;
                nearest.point = point;
                nearest.line = line;
            }
        }

        return nearest;
    }

    function GetNextLanePoint(pos, team)
    {
        local nearest = this.GetNearestPoint(pos);
        if (!nearest.point)
        {
            return pos;
        }

        if (nearest.dist > LANE_EPSILON)
        {
            // Get back to the lane
            return nearest.point;
        }

        // On or close enough to the lane.
        // Overshoot the line end a bit so we
        // don't get stuck and move to the next line.

        local endPos = null;
        local overShoot = 128.0;

        if (team == Constants.ETFTeam.TF_TEAM_RED)
        {
            endPos = nearest.line.endPos + nearest.line.vecNorm * overShoot;
        }
        else
        {
            endPos = nearest.line.startPos - nearest.line.vecNorm * overShoot;
        }

        //DebugDrawBox(nearest.point, Vector(-16.0, -16.0, -16.0), Vector(16.0, 16.0, 16.0), 0, 0, 255, 128, 1.0);

        return endPos;
    }

    function DebugDraw(duration)
    {
        foreach(line in this.lines)
        {
            line.DebugDraw(duration);
        }
        foreach(node in this.nodes)
        {
            DebugDrawBox(node, Vector(-8.0, -8.0, -8.0), Vector(8.0, 8.0, 8.0), 255, 0, 0, 100, duration);
        }
    }
}
