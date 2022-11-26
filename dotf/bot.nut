DoIncludeScript("dotf/util.nut", null);
DoIncludeScript("dotf/settings.nut", null);

const PATH_INTERVAL = 1.0;
const PATH_MARGIN = 64.0;

class Bot
{
    botEnt = null;
    botType = null;
    botTypeName = null;
    team = null;
    teamName = null;
    botSettings = null;

    targetEnt = null;
    targetPos = null;
    targetPath = null;
    navArea = null;
    navPath = null;
    hasPath = false;
    pathTime = 0.0;
    lastThink = 0.0;

    constructor(type, team, pos, ang){
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

        this.botEnt = Entities.CreateByClassname("prop_dynamic");

        this.botEnt.SetModelSimple(this.botSettings["model"]);
        this.botEnt.SetModelScale(this.botSettings["model_scale"], 0.0);
        this.botEnt.SetSkin(this.botSettings["model_skin_" + this.teamName]);
        NetProps.SetPropInt(this.botEnt, "m_bClientSideAnimation", 1);

        this.botEnt.SetSolid(Constants.ESolidType.SOLID_BBOX);
        this.botEnt.SetCollisionGroup(Constants.ECollisionGroup.COLLISION_GROUP_NPC);
        this.botEnt.SetGravity(800.0);
        // this.botEnt.SetVelocity(Vector(200.0, 0.0, 0.0));

        this.botEnt.SetTeam(team);

        this.botEnt.SetAbsOrigin(pos);
        this.botEnt.SetAbsAngles(QAngle(ang));

        this.botEnt.DispatchSpawn();

        // can get reset on spawn depending on classname
        this.botEnt.SetMaxHealth(this.botSettings["health"]);
        this.botEnt.SetHealth(this.botSettings["health"]);

        this.PlayAnim(this.botSettings["model_anim_move"]);
        //this.botEnt.SetPoseParameter(0, 1.0); # TODO: ask if string version could be exposed or LookupPoseParameter
    }

    function Think()
    {
        local time = Time();
        local dt = time - this.lastThink;

        if (this.targetEnt == null)
        {
            this.FindTarget();
        }

        if (time - this.pathTime > PATH_INTERVAL)
        {
            this.GetTargetPos();
            this.GetPath();
        }

        if (this.hasPath)
        {
            local moveSpeed = this.botSettings["move_speed"];
            local currentPos = this.botEnt.GetOrigin();
            local moveDir = null;

            printl("path type " + typeof(this.navPath));

            local passedIndex = -1;
            for (local i = 0; i < this.navPath.len(); i++) {
                local center = this.navPath[i].GetCenter();
                local delta = center - currentPos;
                local dist = delta.Length();

                if (dist < PATH_MARGIN)
                {
                    passedIndex = i;
                    continue;
                }

                moveDir = delta / dist;
                break;
            }

            for (local i = passedIndex; i >= 0; i--) {
                delete this.navPath[i];
            }

            if (moveDir)
            {
                local move = moveDir * moveSpeed;
                local velocity = this.botEnt.GetAbsVelocity();
                velocity.x = move.x;
                velocity.y = move.y;
                this.botEnt.SetVelocity(velocity);
            }
        }

        this.lastThink = Time();
    }

    function FindTarget()
    {
        local ply = GetListenServerHost();
        this.targetEnt = ply;
    }

    function GetTargetPos()
    {
        if (this.targetEnt == null)
        {
            return;
        }
        this.targetPos = this.targetEnt.GetOrigin();
    }

    function GetPath()
    {
        if (this.targetPos == null)
        {
            return;
        }

        this.navArea = NavMesh.GetNavArea(this.botEnt.GetOrigin(), 512.0);
        if (this.navArea == null)
        {
            return;
        }

        this.navPath = {};
        this.hasPath = NavMesh.GetNavAreasFromBuildPath(this.navArea, null, this.targetPos, 10000.0, this.team, false, this.navPath);
        this.pathTime = Time();
    }

    function PlayAnim(name)
    {
        local seq = this.botEnt.LookupSequence(name);
        this.botEnt.ResetSequence(seq);
    }
}