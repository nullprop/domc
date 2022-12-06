DoIncludeScript("dotf/util.nut", null);

const LANE_EPSILON = 256.0;

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

    }

    function AddNode(pos)
    {
        local node = pos;
        if (this.nodes.len() > 0)
        {
            this.lines.append(Line(this.nodes[this.nodes.len() - 1], node));
        }
        this.nodes.append(node);
    }

    function GetNearestPoint(pos)
    {
        local nearest = NearestPoint(null, 100000.0, null);

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

    function GetNextLanePoint(pos)
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
        // Overshoot the line endPos a bit so we
        // don't get stuck and move to the next line.

        local endPos = nearest.line.endPos;
        endPos += nearest.line.vecNorm * 128.0;

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