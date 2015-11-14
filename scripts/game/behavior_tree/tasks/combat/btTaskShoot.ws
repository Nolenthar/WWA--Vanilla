class CBTTaskShoot extends CBTTaskPlayAnimationEventDecorator
{
	public var useCombatTarget 	: bool;
	public var attackRange		: float;
	public var setArrowOnFire 	: bool;
	public var dodgeable 		: bool;
	
	private var arrow 			: W3ArrowProjectile;
	private var projShot 		: bool;
	
	
	function IsAvailable() : bool
	{
		InitializeCombatDataStorage();
		if ( !((CHumanAICombatStorage)combatDataStorage).GetProjectile() )
		{
			GetNPC().SignalGameplayEvent('TakeBowArrow');
			return false;
		}
		return true;
	}
	
	function OnActivate() : EBTNodeStatus
	{
		InitializeCombatDataStorage();
		projShot = false;
		arrow = (W3ArrowProjectile)(((CHumanAICombatStorage)combatDataStorage).GetProjectile());
		if ( setArrowOnFire )
			arrow.ToggleFire(true);
		return super.OnActivate();
	}
	
	function OnDeactivate()
	{
		super.OnDeactivate();
	}
	
	function OnAnimEvent( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo ) : bool
	{
		var res : bool;
		
		res = super.OnAnimEvent(animEventName,animEventType, animInfo);
		
		if ( animEventName == 'ShootProjectile' && arrow )
		{
			ShootProjectile();
			if ( setArrowOnFire )
				arrow.OnFireHit(NULL);
			combatDataStorage.SetIsShooting( false );
			((CHumanAICombatStorage)combatDataStorage).SetProjectile(NULL);
			return true;
		}
		else if ( animEventName == 'TakeBowArrow' )
		{
			GetActor().SignalGameplayEvent('ShouldSwitchToMelee');
			return true;
		}
		
		return res;
	}
	
	function ShootProjectile()
	{
		var npc 					: CNewNPC = GetNPC();
		var target 					: CNode;
		var targetEntity			: CGameplayEntity;
		var desiredHeadingVec 		: Vector;
		var distanceToTarget 		: float;
		var projectileFlightTime 	: float;
		var targetPos 				: Vector;
		var collisionGroups 		: array<name>;
		var headBoneIdx 			: int;
		var entMat					: Matrix;
		var targetMAC				: CMovingPhysicalAgentComponent;
		var yrdenShockEntity		: W3YrdenEntityStateYrdenShock;
				
		collisionGroups.PushBack('Ragdoll');
		collisionGroups.PushBack('Terrain');
		collisionGroups.PushBack('Static');
		
		if ( this.useCombatTarget )
		{
			target = GetCombatTarget();
			targetPos = npc.GetBehaviorVectorVariable('lookAtTarget');
		}
		else
		{
			target = GetActionTarget();
			if ( (CActor)target )
			{
				headBoneIdx = ((CActor)target).GetHeadBoneIndex();
				if ( headBoneIdx >= 0 )
				{
					targetPos = MatrixGetTranslation( ((CActor)target).GetBoneWorldMatrixByIndex( headBoneIdx ) );
				}
				else
				{
					targetPos = target.GetWorldPosition();
					targetPos.Z += ((CMovingPhysicalAgentComponent)((CActor)target).GetMovingAgentComponent()).GetCapsuleHeight() * 0.75;
				}
			}
			else if ( (CGameplayEntity)target )
			{
				targetEntity = (CGameplayEntity)target;
				if ( !( targetEntity.aimVector.X == 0 && targetEntity.aimVector.Y == 0 && targetEntity.aimVector.Z == 0 ) )
				{
					entMat = targetEntity.GetLocalToWorld();
					targetPos = VecTransform( entMat, targetEntity.aimVector );
				}
			}
			else
			{
				targetPos = target.GetWorldPosition();
			}
		}
		
		distanceToTarget = VecDistance(npc.GetWorldPosition(),targetPos);
		
		//desiredHeadingVec = target.GetWorldPosition() - npc.GetWorldPosition();
		desiredHeadingVec = arrow.GetHeadingVector();
		
		
		if ( targetPos == Vector(0,0,0) || distanceToTarget < 6.f )
		{
			targetPos = npc.GetWorldPosition();
			
			if ( (CActor)target )
			{
				targetMAC = (CMovingPhysicalAgentComponent)((CActor)target).GetMovingAgentComponent();
				if ( targetMAC )
					targetPos.Z += 0.8 * targetMAC.GetCapsuleHeight();
			}
			targetPos = targetPos +  desiredHeadingVec*distanceToTarget;
		}
		
		arrow.BreakAttachment();
		arrow.Init( npc );
		
		if ( arrow.yrdenAlternate )
		{
			yrdenShockEntity = (W3YrdenEntityStateYrdenShock)arrow.yrdenAlternate.GetCurrentState();
			if( yrdenShockEntity )
				yrdenShockEntity.ShootDownProjectile( arrow );
			projShot = false;
		}
		else
		{
			arrow.ShootProjectileAtPosition( 7, arrow.projSpeed, targetPos, attackRange, collisionGroups );
			projShot = true;
		}
		
		if ( projShot && dodgeable )
		{
			// used to dodge projectile before it hits
			projectileFlightTime = distanceToTarget / arrow.projSpeed;
			
			((CActor)target).SignalGameplayEventParamFloat('Time2DodgeProjectile', projectileFlightTime );
		}
		npc.SetCounterWindowStartTime(theGame.GetEngineTime());
		npc.BlinkWeapon();
	}
}

class CBTTaskShootDef extends CBTTaskPlayAnimationEventDecoratorDef
{
	default instanceClass = 'CBTTaskShoot';

	editable var useCombatTarget 	: bool;
	editable var attackRange 		: CBehTreeValFloat;
	editable var dodgeable 			: bool;
	editable var setArrowOnFire 	: CBehTreeValBool;
	
	default dodgeable = true;
	default useCombatTarget = true;
	
	public function Initialize()
	{
		SetValFloat(attackRange,10.f);
	}
}
