/***********************************************************************/
/** Copyright © 2014
/** Author : Tomek Kozera
/***********************************************************************/

//assumes dawn and dusk won't be at 0:00
class W3Mutagen23_Effect extends W3Mutagen_Effect
{
	default effectType = EET_Mutagen23;
	default dontAddAbilityOnTarget = true;
	
	event OnUpdate(dt : float)
	{
		var currentHour, currentMinutes, i : int;
		var gameTime : GameTime;
		var params : SCustomEffectParams;
		var shrineBuffs : array<EEffectType>;
		var addBuff : bool;
		var shrineParams : W3ShrineEffectParams;
		
		super.OnUpdate(dt);
		
		if(effectManager.HasAnyMutagen23ShrineBuff())
			return true;
		
		gameTime = theGame.GetGameTime();
		currentHour = GameTimeHours(gameTime);
		currentMinutes = GameTimeMinutes(gameTime);	

		if( (currentHour == GetHourForDayPart(EDP_Dawn) && currentMinutes < 15) || ( (currentHour == (GetHourForDayPart(EDP_Dawn) - 1)) && currentMinutes > 45) )
		{
			addBuff = true;
		}
		else
		{
			if( (currentHour == GetHourForDayPart(EDP_Dusk) && currentMinutes < 15) || ( ( currentHour == (GetHourForDayPart(EDP_Dusk) - 1)) && currentMinutes > 45) )
				addBuff = true;
			else
				addBuff = false;
		}
		
		if(addBuff)
		{			
			shrineBuffs = GetMinorShrineBuffs();
			
			//select only from buffs player doesn't already have
			for(i=shrineBuffs.Size()-1; i>=0; i-=1)
			{
				if(target.HasBuff(shrineBuffs[i]))
					shrineBuffs.Erase(i);
			}
			
			//if he has all pick random
			if(shrineBuffs.Size() == 0)
				shrineBuffs = GetMinorShrineBuffs();
			
			params.effectType = shrineBuffs[ RandRange(shrineBuffs.Size()) ];
			params.sourceName = 'Mutagen23';
			params.duration = ConvertGameSecondsToRealTimeSeconds(60 * 60 * 6);
			shrineParams = new W3ShrineEffectParams in theGame;
			shrineParams.isFromMutagen23 = true;
			params.buffSpecificParams = shrineParams;
			
			target.AddEffectCustom(params);
			
			delete shrineParams;
		}
	}
}