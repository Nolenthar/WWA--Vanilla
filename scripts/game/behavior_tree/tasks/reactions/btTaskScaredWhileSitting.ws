
abstract class CBTTaskShouldBeScaredOnOverlay extends IBehTreeTask
{
	protected var infantInHand : bool;
	var jobTreeType : EJobTreeType;
	
	function ShouldBeScaredOnOverlay() : bool
	{
		var isInLeaveAction : bool;
		var npc				: CNewNPC;
		
		if ( !GetNPC().IsAtWork() )
			return false;
			
		jobTreeType = GetNPC().GetCurrentJTType();
		
		if ( jobTreeType == EJTT_Sitting )
		{
			npc = GetNPC();
			isInLeaveAction = npc.IsInLeaveAction();
			return !isInLeaveAction;
		}
		
		if ( jobTreeType == EJTT_InfantInHand )
		{
			infantInHand = true;
			return true;
		}
		
		return false;
	}
	
	/*function HasItemInHand() : bool
	{
		var inv : CInventoryComponent;
		
		inv = GetNPC().GetInventory();
		
		if ( inv.IsIdValid(inv.GetItemFromSlot('r_weapon')) || inv.IsIdValid(inv.GetItemFromSlot('l_weapon')) )
			return true;
		
		return false;
	}*/
}

class CBTTaskScaredWhileSitting extends CBTTaskShouldBeScaredOnOverlay
{
	var leftItem : CDrawableComponent;
	var rightItem : CDrawableComponent;
	
	function IsAvailable() : bool
	{
		return ShouldBeScaredOnOverlay();
	}
	
	function OnActivate() : EBTNodeStatus
	{
		var inv : CInventoryComponent;
		var itemId : SItemUniqueId;
		
		leftItem = NULL;
		rightItem = NULL;
		
		if ( infantInHand )
			GetNPC().RaiseEvent('ScaredWithInfant');
		else
		{
			inv = GetNPC().GetInventory();
			itemId = inv.GetItemFromSlot( 'l_weapon' );
			if ( inv.IsIdValid(itemId) )
			{
				leftItem = (CDrawableComponent)((inv.GetItemEntityUnsafe(itemId)).GetMeshComponent());
				if ( leftItem )
					leftItem.SetVisible(false);
			}
			itemId = inv.GetItemFromSlot( 'r_weapon' );
			if ( inv.IsIdValid(itemId) )
			{
				rightItem = (CDrawableComponent)((inv.GetItemEntityUnsafe(itemId)).GetMeshComponent());
				if ( rightItem )
					rightItem.SetVisible(false);
			}
			
			GetNPC().RaiseEvent('ScaredWhileSitting');
		}
		
		GetNPC().SignalGameplayEvent( 'AI_PauseWorkAnimation' );
		
		GetNPC().GetMovingAgentComponent().SetUseExtractedMotion(false);
		
		return BTNS_Active;
	}
	
	function OnDeactivate()
	{
		if ( leftItem )
			leftItem.SetVisible(true);
		if ( rightItem )
			rightItem.SetVisible(true);
		GetNPC().RaiseEvent('ScaredOverlayEnd');
		GetNPC().SignalGameplayEvent( 'AI_UnPauseWorkAnimation' );
		
		GetNPC().GetMovingAgentComponent().SetUseExtractedMotion(true);
	}
	
	function OnListenedGameplayEvent( eventName : name ) : bool
	{
		if ( eventName == 'AI_ShouldBeScaredOnOverlay' )
		{
			if ( IsAvailable() )
				SetEventRetvalInt( 1 );
		}
		return false;
	}
}

class CBTTaskScaredWhileSittingDef extends IBehTreeReactionTaskDefinition
{
	default instanceClass = 'CBTTaskScaredWhileSitting';
	
	function InitializeEvents()
	{
		listenToGameplayEvents.PushBack( 'AI_ShouldBeScaredOnOverlay' );
	}
}


//------------------------------------------------------------------------
class CBTCondIsSittingInInterior extends CBTTaskShouldBeScaredOnOverlay
{
	function IsAvailable() : bool
	{
		return ShouldBeScaredOnOverlay();
	}
	
	function OnActivate() : EBTNodeStatus
	{
		return BTNS_Active;
	}
}

class CBTCondIsSittingInInteriorDef extends IBehTreeReactionTaskDefinition
{
	default instanceClass = 'CBTCondIsSittingInInterior';
}
