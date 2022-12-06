DoIncludeScript("dotf/util.nut", null);
DoIncludeScript("dotf/settings.nut", null);

const PATH_INTERVAL = 1.0;
const PATH_MARGIN = 64.0;
const STEP_HEIGHT = 24.0;

class Bot
{
    botEnt = null;
    locomotion = null;
    body = null;
    vision = null;

    lane = null;
    botType = null;
    botTypeName = null;
    team = null;
    teamName = null;
    botSettings = null;

    targetEnt = null;
    targetPos = null;
    targetPath = null;
    navArea = null;
    navPath = [];
    pathTime = 0.0;
    lastThink = 0.0;

    constructor(type, team, pos, ang, lane){
        this.lane = lane;
        this.botType = type;
        this.botTypeName = TF_BOT_TYPE_NAME[type];
        this.team = team;
        this.teamName = TF_TEAM_NAMES[team];
        this.botSettings = BOT_SETTINGS[this.botTypeName];

        this.lastThink = Time();

        // Spawn on navmesh
        local navArea = NavMesh.GetNavArea(pos, 512.0);
        if (navArea)
        {
            pos = navArea.FindRandomSpot();
        }

        this.botEnt = SpawnEntityFromTable(
            "base_boss",
            {
                targetname = "bot",
                origin = pos,
                model = this.botSettings["model"],
                playbackrate = 1.0,
                health = this.botSettings["health"],
                speed = this.botSettings["move_speed"]
            }
        );

        this.locomotion = this.botEnt.GetLocomotionInterface();
        this.body = this.botEnt.GetBodyInterface();
        this.vision = this.botEnt.GetVisionInterface();

        this.botEnt.SetGravity(800.0);

        this.botEnt.SetModelScale(this.botSettings["model_scale"], 0.0);
        this.botEnt.SetSkin(this.botSettings["model_skin_" + this.teamName]);
        NetProps.SetPropInt(this.botEnt, "m_bClientSideAnimation", 1);

        this.botEnt.SetTeam(team);

        this.locomotion.SetDesiredSpeed(this.botSettings["move_speed"]);
        this.locomotion.SetSpeedLimit(3500.0);

        if (!this.botEnt.ValidateScriptScope())
        {
            Log("Failed to validate bot script scope");
            return;
        }

        this.botEnt.GetScriptScope().my_bot <- this;
        AddThinkToEnt(this.botEnt, "BotThink");
    }

    function Update()
    {
        local time = Time();

        if (this.targetEnt == null)
        {
            this.FindTarget();
        }

        if (time - this.pathTime > PATH_INTERVAL || this.navPath.len() <= 0)
        {
            this.GetTargetPos();
            this.GetPath();
        }

        local moveTarget = null;
        local currentPos = this.botEnt.GetOrigin();

        for (local i = this.navPath.len() - 1; i >= 0; i--) {
            if ((this.navPath[i] - currentPos).Length2D() < PATH_MARGIN)
            {
                this.navPath.remove(i);
                continue;
            }

            moveTarget = this.navPath[i];
            break;
        }

        if (moveTarget)
        {
            this.locomotion.Approach(moveTarget, 0.1);
            this.locomotion.FaceTowards(moveTarget);

            this.botEnt.SetForwardVector(this.locomotion.GetGroundMotionVector());

            this.PlayAnim(this.botSettings["model_anim_move"]);
            this.SetPoseParameter("move_x", 1.0);
            if (this.botType == TF_BOT_TYPE["RANGED"])
            {
                this.SetPoseParameter("move_scale", 1.0);
            }
        }
        else
        {
            this.PlayAnim(this.botSettings["model_anim_idle"]);
            this.SetPoseParameter("move_x", 0.0);
            if (this.botType == TF_BOT_TYPE["RANGED"])
            {
                this.SetPoseParameter("move_scale", 0.0);
            }
        }

        // loop anim
        if (this.botEnt.GetCycle() > 0.99)
		{
            this.botEnt.SetCycle(0.0);
        }

        // advance anim
        this.botEnt.StudioFrameAdvance();
        this.botEnt.DispatchAnimEvents(this.botEnt);

        this.lastThink = time;
    }

    function FindTarget()
    {
        // TODO
        //local ply = GetListenServerHost();
        //this.targetEnt = ply;
    }

    function GetTargetPos()
    {
        if (this.targetEnt != null)
        {
            this.targetPos = this.targetEnt.GetOrigin();
            return;
        }

        this.targetPos = this.lane.GetNextLanePoint(this.botEnt.GetOrigin());
    }

    function GetPath()
    {
        if (this.targetPos == null)
        {
            return;
        }

        this.navPath = [];
        // Path is in reverse
        this.navPath.append(this.targetPos);

        local startArea = NavMesh.GetNavArea(this.botEnt.GetOrigin(), 512.0);
        if (startArea == null)
        {
            NavMesh.GetNearestNavArea(this.botEnt.GetOrigin(), 512.0, false, true);
        }
        if (startArea == null)
        {
            return;
        }
        local endArea = NavMesh.GetNavArea(this.targetPos, 512.0);
        if (endArea == null)
        {
            NavMesh.GetNearestNavArea(this.targetPos, 512.0, false, true);
        }

        local pathTable = {};
        local builtPath = NavMesh.GetNavAreasFromBuildPath(startArea, endArea, this.targetPos, 10000.0, this.team, false, pathTable);
        this.pathTime = Time();

        if (builtPath && pathTable.len() > 0)
        {
            local area = pathTable["area0"];
            while (area != null)
            {
                // Don't add current area so bot will actually leave it...
                // Don't add end area, use actual targetPos for final point
                if (area != startArea && area != endArea)
                {
                    this.navPath.append(area.GetCenter());
                }

                area = area.GetParent();
            }
        }
    }

    function PlayAnim(name)
    {
        local seq = this.botEnt.LookupSequence(name);
        this.botEnt.ResetSequence(seq);
    }

    function SetPoseParameter(name, val)
    {
        local index = this.botEnt.LookupPoseParameter(name);
        if (index > 0)
        {
            this.botEnt.SetPoseParameter(index, val);
        }
    }

    function IsCurrentAnim(name)
    {
        local seq = this.botEnt.LookupSequence(name);
        return this.botEnt.GetSequence() == seq;
    }
}

function BotThink()
{
	return self.GetScriptScope().my_bot.Update();
}