DoIncludeScript("domc/util.nut", null);
DoIncludeScript("domc/settings.nut", null);

const PATH_INTERVAL = 1.0;
const TARGET_INTERVAL = 3.0;
const PATH_MARGIN = 64.0;
const STEP_HEIGHT = 24.0;
const BOT_XP_AWARD_BASE = 100.0;

BOT_SETTINGS <-
{
	"melee":
	{
		"health": 300,
		"damage": 8.0,
        "damage_type": Constants.FDmgType.DMG_CLUB,
        "attack_interval": 1.0,
		"attack_range": 96.0,
		"aggro_range": 512.0,
		"class": Constants.ETFClass.TF_CLASS_HEAVYWEAPONS,
		"model": "models/bots/heavy/bot_heavy.mdl",
		"model_scale": 0.6,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_MELEE",
		"model_anim_move": "Run_MELEE",
		"model_anim_attack":
        [
            "AttackStand_MELEE_R",
            "AttackStand_MELEE_L"
        ],
		"weapon": null,
		"move_speed": 120
	},
	"ranged":
	{
		"health": 150,
		"damage": 12.0,
        "damage_type": Constants.FDmgType.DMG_BULLET,
        "attack_interval": 1.5,
		"attack_range": 450.0,
		"aggro_range": 512.0,
		"class": Constants.ETFClass.TF_CLASS_SNIPER,
		"model": "models/bots/sniper/bot_sniper.mdl",
		"model_scale": 0.6,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_PRIMARY",
		"model_anim_move": "Run_PRIMARY",
		"model_anim_attack": ["AttackStand_PRIMARY"],
		"weapon": "tf_weapon_sniperrifle",
        "weapon_model": "models/weapons/w_models/w_sniperrifle.mdl",
		"move_speed": 110
	},
	"siege":
	{
		"health": 500,
		"damage": 50.0,
        "damage_radius": 128.0,
        "projectile_vel": 600.0, // horizontal
        "attack_interval": 4.0,
		"attack_range": 480.0,
		"aggro_range": 512.0,
		"class": Constants.ETFClass.TF_CLASS_DEMOMAN,
		"model": "models/bots/demo_boss/bot_demo_boss.mdl",
		"model_scale": 0.8,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_PRIMARY",
		"model_anim_move": "Run_PRIMARY",
		"model_anim_attack": ["AttackStand_PRIMARY"],
		"weapon": "tf_weapon_grenadelauncher",
        "weapon_model": "models/weapons/w_models/w_grenadelauncher.mdl",
		"move_speed": 110
	}
}

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
    weaponEnt = null;

    uname = null;

    targetEnt = null;
    targetCheckTime = 0.0;
    hasNewTarget = false;
    targetPos = null;
    targetPath = null;
    navArea = null;
    navPath = [];
    pathTime = 0.0;
    lastAttackTime = 0.0;
    xpAward = BOT_XP_AWARD_BASE;

    constructor(type, team, lane, pos, ang){
        if (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE)
        {
            error(format"Invalid bot team %d", team);
        }

        this.lane = lane;
        this.botType = type;
        this.botTypeName = TF_BOT_TYPE_NAME[type];
        this.team = team;
        this.teamName = TF_TEAM_NAMES[team];
        this.botSettings = BOT_SETTINGS[this.botTypeName];
        this.uname = UniqueString();

        // Spawn on navmesh
        local navArea = NavMesh.GetNavArea(pos, 512.0);
        if (navArea)
        {
            pos = navArea.FindRandomSpot();
        }

        this.botEnt = SpawnEntityFromTable(
            "base_boss",
            {
                targetname = "bot_" + this.uname,
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

        if (this.botSettings["weapon"])
        {
            this.weaponEnt = Entities.CreateByClassname("prop_dynamic");
            this.weaponEnt.SetTeam(team);
            this.weaponEnt.SetAbsOrigin(pos + Vector(0, 0, 40.0 * this.botSettings["model_scale"]));
            this.weaponEnt.SetSolidFlags(Constants.FSolid.FSOLID_NOT_SOLID);
            this.weaponEnt.SetCollisionGroup(Constants.ECollisionGroup.COLLISION_GROUP_NONE);
            this.weaponEnt.SetModelSimple(this.botSettings["weapon_model"]);
            this.weaponEnt.SetModelScale(this.botSettings["model_scale"], 0.0);
            this.weaponEnt.DispatchSpawn();

            EntFireByHandle(this.weaponEnt, "SetParent", "bot_" + this.uname, 0.1, null, null);
            // TODO: lookup attachment name in HLMV
            // EntFireByHandle(this.weaponEnt, "SetParentAttachment", "weapon_bone", 0.2, null, null);
        }
    }

    function Update()
    {
        if (!IsValidAndAlive(this.botEnt))
        {
            return;
        }

        local time = Time();

        if (this.locomotion.IsStuck())
        {
            local stuckTime = this.locomotion.GetStuckDuration();
            Log(format("bot %s stuck for %f at %s", this.uname, stuckTime, this.botEnt.GetOrigin().tostring()));
            if (stuckTime > 10.0)
            {
                this.botEnt.Kill();
                return;
            }
        }

        if (
            // time to recheck?
            time - this.targetCheckTime > TARGET_INTERVAL ||
            // has our previous target died?
            !IsValidAndAlive(this.targetEnt)
        )
        {
            this.targetCheckTime = time;
            this.targetEnt = this.FindTarget();
            this.hasNewTarget = true;
        }

        if (IsValidAndAlive(this.targetEnt))
        {
            local targetOrigin = this.targetEnt.GetOrigin();
            local myPos = this.botEnt.GetOrigin();
            local attackVec = targetOrigin - myPos;
            local inRange = attackVec.Length() <= this.botSettings["attack_range"];

            if (inRange)
            {
                local frontTowardEnemy = Vector(attackVec.x, attackVec.y, 0.0);
                this.botEnt.SetForwardVector(frontTowardEnemy);

                if (this.CanAttack(myPos))
                {
                    this.Attack(myPos, attackVec);
                }
                else
                {
                    this.Idle();
                }
            }
            else if (this.HasLOS(myPos + Vector(0, 0, 48), targetOrigin + Vector(0, 0, 48), this.targetEnt))
            {
                this.Move(targetOrigin);
            }
            else
            {
                this.PathFind();
            }
        }
        else
        {
            this.PathFind();
        }

        // loop anim
        if (this.botEnt.GetCycle() > 0.99)
		{
            this.botEnt.SetCycle(0.0);
        }

        // advance anim
        this.botEnt.StudioFrameAdvance();
        this.botEnt.DispatchAnimEvents(this.botEnt);
    }

    function HasLOS(startPos, endPos, targetEnt)
    {
        local tr =
        {
            "start": startPos,
            "end": endPos,
            "mask": MASK_ATTACK_TRACE,
            "ignore": this.botEnt
        };
        if (TraceLineEx(tr))
        {
            if (tr["fraction"] >= 1.0 - Constants.Math.Epsilon)
            {
                return true;
            }
            if (tr["enthit"] == targetEnt)
            {
                return true;
            }
        }
        return false;
    }

    function CanAttack(myPos)
    {
        if (Time() - this.lastAttackTime < this.botSettings["attack_interval"])
        {
            return false;
        }

        if (this.HasLOS(myPos + Vector(0, 0, 48), this.targetEnt.GetOrigin() + Vector(0, 0, 48), this.targetEnt))
        {
            return true;
        }

        return false;
    }

    function Attack(myPos, attackVec)
    {
        this.lastAttackTime = Time();
        this.PlayAnim(RandomElement(this.botSettings["model_anim_attack"]));
        this.SetPoseParameter("move_x", 0.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 1.0);
        }

        // TODO: direct hits are broken due to m_flFullDamage
        if (this.botType == TF_BOT_TYPE["SIEGE"])
        {
            local forward = this.botEnt.GetForwardVector();
            local startPos = myPos + Vector(0, 0, 48.0) + forward * 32.0;
            local startAng = this.botEnt.GetAbsAngles();
            local horizontalVel = this.botSettings["projectile_vel"];
            local verticalVel = TrajectoryVertVel(attackVec.Length2D(), horizontalVel, 800.0);
            local startVel = forward * horizontalVel + Vector(0.0, 0.0, verticalVel);

            // local nadeUname = UniqueString();
            // local targetname = "bot_" + this.uname + "_grenade_" + nadeUname;
            local nade = Entities.CreateByClassname("tf_projectile_pipe");

            nade.SetTeam(this.team);
            nade.SetOwner(this.botEnt);
            NetProps.SetPropEntity(nade, "m_hThrower", this.botEnt);
            NetProps.SetPropVector(nade, "m_vInitialVelocity", startVel);
            // TODO m_flFullDamage for direct hits
            // https://github.com/ValveSoftware/Source-1-Games/issues/4481#issuecomment-1344759066
            NetProps.SetPropFloat(nade, "m_flDamage", this.botSettings["damage"]);
            NetProps.SetPropFloat(nade, "m_DmgRadius", this.botSettings["damage_radius"]);
            NetProps.SetPropBool(nade, "m_bCritical", false);
            nade.DispatchSpawn();
            // needed for nades
            nade.Teleport(true, startPos, true, startAng, true, startVel);
        }
        else
        {
            if (this.targetEnt && this.targetEnt.IsValid())
            {
                this.targetEnt.TakeDamage(this.botSettings["damage"], this.botSettings["damage_type"], this.botEnt);
            }
        }
    }

    function PathFind()
    {
        local time = Time();

        if (time - this.pathTime > PATH_INTERVAL || this.navPath.len() <= 0 || this.hasNewTarget)
        {
            this.hasNewTarget = false;
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
            this.Move(moveTarget);
        }
        else
        {
            this.Idle();
        }
    }

    function Move(targetPos)
    {
        this.locomotion.Approach(targetPos, 0.1);
        this.locomotion.FaceTowards(targetPos);

        this.botEnt.SetForwardVector(this.locomotion.GetGroundMotionVector());

        this.PlayAnim(this.botSettings["model_anim_move"]);
        this.SetPoseParameter("move_x", 1.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 1.0);
        }
    }

    function Idle()
    {
        this.PlayAnim(this.botSettings["model_anim_idle"]);
        this.SetPoseParameter("move_x", 0.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 1.0);
        }
    }

    function FindTarget()
    {
        // classnames to target, in order of priority
        local nearest =
        {
            "base_boss":
            {
                "ent": null,
                "dist": FLT_BIG
            },
            "obj_sentrygun":
            {
                "ent": null,
                "dist": FLT_BIG
            },
            "player":
            {
                "ent": null,
                "dist": FLT_BIG
            },
        };

        local ent = null;
        local pos = this.botEnt.GetOrigin();
        local radius = this.botSettings["aggro_range"];
        local myTeam = this.botEnt.GetTeam();

        while (ent = Entities.FindInSphere(ent, pos, radius))
        {
            local team = ent.GetTeam();
            if (team == myTeam || (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE))
            {
                continue;
            }

            local classname = ent.GetClassname();
            if (!(classname in nearest))
            {
                continue;
            }

            local origin = ent.GetOrigin();
            local dist = (origin - pos).Length();
            if (dist < nearest[classname]["dist"])
            {
                nearest[classname]["dist"] = dist;
                nearest[classname]["ent"] = ent;
            }
        }

        foreach (type in nearest)
        {
            if (type["ent"] != null)
            {
                return type["ent"];
            }
        }

        return null;
    }

    function GetTargetPos()
    {
        if (this.targetEnt != null && this.targetEnt.IsValid())
        {
            this.targetPos = this.targetEnt.GetOrigin();
            return;
        }

        this.targetPos = this.lane.GetNextLanePoint(this.botEnt.GetOrigin(), this.team);
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
                /*
                // Don't add current area so bot will actually leave it...
                // Don't add end area, use actual targetPos for final point
                if (area != startArea && area != endArea)
                {
                    this.navPath.append(area.GetCenter());
                }
                */
                local parentArea = area.GetParent();
                if (parentArea)
                {
                    local portalPoint = area.ComputeClosestPointInPortal(parentArea, area.GetParentHow(), area.GetCenter());
                    this.navPath.append(portalPoint);
                }

                area = parentArea;
            }
        }

        /*
        foreach (p in this.navPath)
        {
            DebugDrawBox(p, Vector(-8.0, -8.0, -8.0), Vector(8.0, 8.0, 8.0), 255, 255, 255, 100, 1.0);
        }
        */
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

    function GetEnt()
    {
        return this.botEnt;
    }

    function OnTakeDamage(params)
    {
        // Climb up owner hierarchy for projectiles, etc.
        local inf = GetTrueInflictor(params.inflictor);

        if (inf.GetTeam() == this.team)
        {
            return false;
        }

        if (params.damage >= this.botEnt.GetHealth())
        {
            return true;
        }

        // If no target already, aggro on to whoever did damage to us
        if (!IsValidAndAlive(this.targetEnt))
        {
            this.targetEnt = inf;
            this.hasNewTarget = true;
            this.targetCheckTime = Time();
        }
        else if (this.targetEnt == inf)
        {
            // Reset timer if current aggro target
            this.targetCheckTime = Time();
        }

        return false;
    }

    function GetPos()
    {
        return this.botEnt.GetOrigin();
    }
}

function BotThink()
{
	return self.GetScriptScope().my_bot.Update();
}