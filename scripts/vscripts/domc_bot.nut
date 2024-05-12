DoIncludeScript("domc_util.nut", null);
DoIncludeScript("domc_settings.nut", null);

const PATH_INTERVAL = 1.0;
const TARGET_INTERVAL = 3.0;
const PATH_MARGIN = 64.0;
const STEP_HEIGHT = 32.0;
const BOT_XP_AWARD_BASE = 100.0;

BOT_SETTINGS <-
{
	"melee":
	{
		"health": 350,
		"damage": 15.0,
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
        "model_anim_victory": "taunt04",
        "model_anim_lose": "Stand_LOSER",
        "weapon_model": null,
        "move_speed": 150,
        "death_particle": "ExplosionCore_buildings"
	},
	"ranged":
	{
		"health": 200,
		"damage": 20.0,
        "damage_type": Constants.FDmgType.DMG_BULLET,
        "attack_interval": 1.5,
		"attack_range": 400.0,
		"aggro_range": 512.0,
		"class": Constants.ETFClass.TF_CLASS_SNIPER,
		"model": "models/bots/sniper/bot_sniper.mdl",
		"model_scale": 0.6,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_PRIMARY",
		"model_anim_move": "Run_PRIMARY",
		"model_anim_attack": ["AttackStand_PRIMARY"],
        "model_anim_victory": "taunt01",
        "model_anim_lose": "Stand_LOSER",
        "weapon_model": "models/weapons/w_models/w_sniperrifle.mdl",
        "move_speed": 145,
        "death_particle": "ExplosionCore_buildings"
	},
	"siege":
	{
		"health": 600,
		"damage": 80.0,
        "damage_type": Constants.FDmgType.DMG_BLAST,
        "damage_radius": 192.0,
        "projectile_vel": 600.0, // horizontal
        "attack_interval": 3.0,
		"attack_range": 520.0,
		"aggro_range": 540.0,
		"class": Constants.ETFClass.TF_CLASS_DEMOMAN,
		"model": "models/bots/demo_boss/bot_demo_boss.mdl",
		"model_scale": 0.8,
		"model_skin_blu": 1,
		"model_skin_red": 0,
		"model_anim_idle": "Stand_PRIMARY",
		"model_anim_move": "Run_PRIMARY",
		"model_anim_attack": ["AttackStand_PRIMARY"],
        "model_anim_victory": "taunt01",
        "model_anim_lose": "Stand_LOSER",
        "weapon_model": "models/weapons/w_models/w_grenadelauncher.mdl",
        "move_speed": 145,
        "death_particle": "rd_robot_explosion"
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
    weaponModel = null;

    runSequence = null;
    idleSequence = null;
    attackSequences = [];
    victorySequence = null;
    loseSequence = null;

    roundOver = false;
    roundWinner = false;

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
        this.botEnt.SetTeam(team);

        this.locomotion.SetDesiredSpeed(this.botSettings["move_speed"]);
        this.locomotion.SetSpeedLimit(this.botSettings["move_speed"]);
        EntFireByHandle(this.botEnt, "SetStepHeight", STEP_HEIGHT.tostring(), 0, null, null);

        if (!this.botEnt.ValidateScriptScope())
        {
            Log("Failed to validate bot script scope");
            return;
        }

        this.runSequence = this.botEnt.LookupSequence(this.botSettings["model_anim_move"]);
        this.idleSequence = this.botEnt.LookupSequence(this.botSettings["model_anim_idle"]);
        for (local i = 0; i < this.botSettings["model_anim_attack"].len(); i++)
        {
            this.attackSequences.append(this.botEnt.LookupSequence(this.botSettings["model_anim_attack"][i]));
        }
        this.victorySequence = this.botEnt.LookupSequence(this.botSettings["model_anim_victory"]);
        this.loseSequence = this.botEnt.LookupSequence(this.botSettings["model_anim_lose"]);

        this.botEnt.GetScriptScope().my_bot <- this;
        AddThinkToEnt(this.botEnt, "BotThink");

        if (this.botSettings["weapon_model"])
        {
            this.weaponModel = Entities.CreateByClassname("prop_dynamic");
            this.weaponModel.SetTeam(team);
            this.weaponModel.SetOwner(this.botEnt);
            this.weaponModel.ClearSolidFlags();
            this.weaponModel.SetSolidFlags(Constants.FSolid.FSOLID_NOT_SOLID);
            this.weaponModel.SetCollisionGroup(Constants.ECollisionGroup.COLLISION_GROUP_NONE);
            this.weaponModel.SetModelSimple(this.botSettings["weapon_model"]);
            this.weaponModel.SetModelScale(this.botSettings["model_scale"], 0.0);
            this.weaponModel.DispatchSpawn();

            EntFireByHandle(this.weaponModel, "SetParent", "bot_" + this.uname, 0.1, null, null);

            // FIXME: doesn't seem to work
            local bone = this.botEnt.LookupBone("weapon_bone");
            if (bone >= 0)
            {
                this.weaponModel.SetAbsOrigin(this.botEnt.GetBoneOrigin(bone));
                this.weaponModel.SetAbsAngles(this.botEnt.GetBoneAngles(bone));
            }
            else
            {
                this.weaponModel.SetAbsOrigin(pos + Vector(0, 0, 40.0 * this.botSettings["model_scale"]));
                this.weaponModel.SetAbsAngles(this.botEnt.GetAbsAngles());
            }
        }
    }

    function Update()
    {
        if (!IsValidAndAlive(this.botEnt))
        {
            return 1.0;
        }

        if (this.roundOver)
        {
            this.locomotion.Stop();
            this.Animate();
            return 0.0;
        }

        local time = Time();

        if (this.locomotion.IsStuck())
        {
            local stuckTime = this.locomotion.GetStuckDuration();

            if (stuckTime > 0.1)
            {
                local origin = this.botEnt.GetOrigin();
                local navArea = NavMesh.GetNearestNavArea(origin + Vector(0, 0, 32), 64, false, true);
                if (navArea)
                {
                    local newPos = navArea.FindRandomSpot();
                    Log(format(
                        "bot %s stuck at %s, teleporting to %s",
                        this.uname,
                        origin.tostring(),
                        newPos.tostring()
                    ));
                    this.locomotion.DriveTo(newPos);
                    this.locomotion.ClearStuckStatus("force unstuck");
                    return 0.0;
                }

                Log(format(
                    "bot %s stuck at %s, killing",
                    this.uname,
                    origin.tostring()
                ));
                this.Kill();
                return 1.0;
            }
        }

        if (
            // time to recheck?
            time - this.targetCheckTime > TARGET_INTERVAL ||
            // has our previous target died?
            !IsValidAndAlive(this.targetEnt)
        )
        {
            local prevTarget = this.targetEnt;
            this.targetCheckTime = time;
            this.targetEnt = this.FindTarget();
            if (prevTarget != this.targetEnt && IsValidAndAlive(this.targetEnt))
            {
                this.hasNewTarget = true;
            }
        }

        if (IsValidAndAlive(this.targetEnt))
        {
            local targetOrigin = this.targetEnt.GetOrigin();
            local myPos = this.botEnt.GetOrigin();
            local attackVec = targetOrigin - myPos;
            local inRange = attackVec.Length() <= this.botSettings["attack_range"];
            local hasLOS = this.HasLOS(
                myPos + Vector(0, 0, 48),
                targetOrigin + Vector(0, 0, 48),
                this.targetEnt
            );

            if (hasLOS)
            {
                if (inRange)
                {
                    local frontTowardEnemy = Vector(attackVec.x, attackVec.y, 0.0);
                    this.botEnt.SetForwardVector(frontTowardEnemy);

                    if (this.CanAttack())
                    {
                        this.Attack(myPos, attackVec);
                    }
                    else
                    {
                        this.Idle();
                    }
                }
                else
                {
                    this.Move(targetOrigin);
                }
            }
            else
            {
                this.FindPath();
            }
        }
        else
        {
            this.FindPath();
        }

        this.Animate();

        return 0.0;
    }

    function Animate()
    {
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

    function CanAttack()
    {
        if (Time() - this.lastAttackTime < this.botSettings["attack_interval"])
        {
            return false;
        }

        return true;
    }

    function Attack(myPos, attackVec)
    {
        this.lastAttackTime = Time();
        this.botEnt.ResetSequence(RandomElement(this.attackSequences));
        this.SetPoseParameter("move_x", 0.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 0.0);
        }

        if (this.botType == TF_BOT_TYPE["SIEGE"])
        {
            local forward = this.botEnt.GetForwardVector();
            local startPos = myPos + Vector(0, 0, 48.0) + forward * 32.0;
            local horizontalVel = this.botSettings["projectile_vel"];
            local verticalVel = TrajectoryVertVel(attackVec.Length2D(), horizontalVel, 800.0);
            local startVel = forward * horizontalVel + Vector(0.0, 0.0, verticalVel);
            local startAng = VectorAngles(startVel);

            // local nadeUname = UniqueString();
            // local targetname = "bot_" + this.uname + "_grenade_" + nadeUname;
            local nade = Entities.CreateByClassname("tf_projectile_pipe");

            nade.SetTeam(this.team);
            nade.SetOwner(this.botEnt);
            NetProps.SetPropEntity(nade, "m_hThrower", this.botEnt);
            NetProps.SetPropVector(nade, "m_vInitialVelocity", startVel);
            NetProps.SetPropInt(nade, "m_iType", 0); // pipe
            NetProps.SetPropFloat(nade, "m_flDamage", this.botSettings["damage"]);
            NetProps.SetPropFloat(nade, "m_DmgRadius", this.botSettings["damage_radius"]);
            NetProps.SetPropBool(nade, "m_bCritical", false);
            nade.DispatchSpawn();
            // needed for nades
            nade.Teleport(true, startPos, true, startAng, true, startVel);
            AddThinkToEnt(nade, "GrenadeThink");
        }
        else
        {
            if (this.targetEnt && this.targetEnt.IsValid())
            {
                this.targetEnt.TakeDamage(this.botSettings["damage"], this.botSettings["damage_type"], this.botEnt);
            }
        }
    }

    function FindPath()
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
        local goal = targetPos;
        local origin = this.botEnt.GetOrigin();

        // Make sure goal isn't too far, otherwise avoidance wont have much impact
        local toGoal = goal - origin;
        local goalDist = toGoal.Norm();
        if (goalDist > 64.0)
        {
            goalDist = 64.0;
        }
        toGoal = toGoal * goalDist;
        goal = origin + toGoal;

        local avoid =
        [
            "base_boss",
            "obj_sentrygun",
            "obj_dispenser",
            "player"
        ];
        local ent = null;
        local avoidWeight = 0.0;
        local avoidVec = Vector();
        local avoidDistance = 16.0;
        local boundsDist = this.botEnt.GetBoundingMaxs().Length2D(); 
        local queryDistance = boundsDist * 5.0;
        while (ent = Entities.FindInSphere(ent, origin, queryDistance))
        {
            if (!IsValidAndAlive(ent))
            {
                continue;
            }

            local classname = ent.GetClassname();
            if (!ArrayContains(avoid, classname))
            {
                //DebugDrawLine(origin, ent.GetOrigin(), 0, 0, 255, true, 0.02);
                continue;
            }

            local toEnt = ent.GetOrigin() - origin;
            local range = toEnt.Norm() - boundsDist - ent.GetBoundingMaxs().Length2D();
            if (range < avoidDistance)
            {
                local depen = avoidDistance - range;
                local weight = 1.0 + 150.0 * depen/avoidDistance;
                avoidVec += toEnt * -weight;
                avoidWeight += weight;
                //DebugDrawLine(origin, ent.GetOrigin(), 255, 0, 0, true, 0.02);
            }
        }

        //DebugDrawBox(goal, Vector(-8.0, -8.0, -8.0), Vector(8.0, 8.0, 8.0), 0, 255, 0, 100, 0.02);

        if (avoidWeight > 0.0)
        {
            local oldGoal = goal;
            goal += avoidVec;
            //DebugDrawBox(goal, Vector(-8.0, -8.0, -8.0), Vector(8.0, 8.0, 8.0), 255, 0, 0, 100, 0.02);
            //DebugDrawLine(oldGoal, goal, 255, 255, 255, true, 0.02);
        }

        this.locomotion.FaceTowards(goal);
        this.locomotion.Approach(goal, 1.0);

        if (this.botType == TF_BOT_TYPE["SIEGE"])
        {
            // wtf
            this.botEnt.SetForwardVector(this.locomotion.GetGroundMotionVector() * -1);
        }
        else
        {
            this.botEnt.SetForwardVector(this.locomotion.GetGroundMotionVector());
        }

        this.botEnt.ResetSequence(this.runSequence);
        this.SetPoseParameter("move_x", 1.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 1.0);
        }
    }

    function Idle()
    {
        this.botEnt.ResetSequence(this.idleSequence);
        this.SetPoseParameter("move_x", 0.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 0.0);
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
            "obj_dispenser":
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
            if (!IsValidAndAlive(ent))
            {
                continue;
            }

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
        local builtPath = NavMesh.GetNavAreasFromBuildPath(
            startArea,
            endArea,
            this.targetPos,
            10000.0,
            this.team,
            false,
            pathTable
        );
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
                    local portalPoint = area.ComputeClosestPointInPortal(
                        parentArea,
                        area.GetParentHow(),
                        area.GetCenter()
                    );
                    this.navPath.append(portalPoint);
                }
                /*
                if (area != startArea && area != endArea)
                {
                    this.navPath.append(area.FindRandomSpot());
                }
                */

                area = parentArea;
            }
        }

        /*
        foreach (p in this.navPath)
        {
            DebugDrawBox(p, Vector(-8.0, -8.0, -8.0), Vector(8.0, 8.0, 8.0), 255, 255, 255, 100, 0.1);
        }
        */
    }

    function SetPoseParameter(name, val)
    {
        local index = this.botEnt.LookupPoseParameter(name);
        if (index > 0)
        {
            this.botEnt.SetPoseParameter(index, val);
        }
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
            DispatchParticleEffect(
                this.botSettings["death_particle"],
                this.botEnt.GetOrigin() + Vector(0, 0, 32),
                Vector()
            );
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

    function Kill()
    {
        if (IsValid(this.botEnt))
        {
            this.botEnt.Kill();
        }
    }

    function OnRoundEnd(isWinner)
    {
        if (!IsValidAndAlive(this.botEnt))
        {
            return;
        }

        this.roundOver = true;
        this.roundWinner = isWinner;

        if (this.roundWinner)
        {
            this.botEnt.ResetSequence(this.victorySequence);
        }
        else
        {
            this.botEnt.ResetSequence(this.loseSequence);
        }

        this.SetPoseParameter("move_x", 0.0);
        if (this.botType == TF_BOT_TYPE["RANGED"])
        {
            this.SetPoseParameter("move_scale", 0.0);
        }
    }
}

function BotThink()
{
	return self.GetScriptScope().my_bot.Update();
}

// m_flFullDamage is not exposed as a netprop,
// so we need to fudge direct hit grenades... :(
function GrenadeThink()
{
    local aboutToCollide = false;
    local origin = self.GetOrigin() - Vector(0, 0, 16);
    local vel = self.GetAbsVelocity();

    local tr =
    {
        "start": origin,
        "end": origin + vel * 0.05,
        "mask": MASK_BOT_PIPE,
        "ignore": self,
        "hullmin": self.GetBoundingMins(),
        "hullmax": self.GetBoundingMaxs()
    };
    if (TraceHull(tr))
    {
        if (tr["hit"])
        {
            aboutToCollide = true;
        }
    }

    if (aboutToCollide)
    {
        local radius = BOT_SETTINGS["siege"]["damage_radius"];
        local damage = BOT_SETTINGS["siege"]["damage"];
        local damageType = BOT_SETTINGS["siege"]["damage_type"];
        local myTeam = self.GetTeam();
        local bot = NetProps.GetPropEntity(self, "m_hThrower");
        local ent = null;
        while (ent = Entities.FindInSphere(ent, origin, radius))
        {
            local team = ent.GetTeam();
            if (team == myTeam || (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE))
            {
                continue;
            }

            local pos = ent.GetOrigin();
            local dist = (pos - origin).Length();
            local damageScale = 1.0 - (dist / radius);
            ent.TakeDamageEx(self, bot, null, Vector(), origin, damage * damageScale, damageType);
        }

        DispatchParticleEffect("ExplosionCore_MidAir", origin, Vector());
        self.Kill();
    }

    return 0.0;
}

