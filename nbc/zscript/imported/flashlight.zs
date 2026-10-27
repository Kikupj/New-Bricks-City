Class FlashlightAngled : Weapon
{
Spotlight beam; //pointer to the spawned spotlight

	// Simple wrapper for A_WeaponReady. This makes sure
	// that Fire state cannot be called repeatedbly by
	// holding the attack button, so we don't cycle the
	// flashlight on/off too quickly:
	action void A_FlashlightReady()
	{
		int fflags = 0;
		// Check if player was holding fire button during last tic;
		// if so, disable the ability to fire:
		if (player.oldbuttons & BT_ATTACK)
		{
			fflags |= WRF_NOPRIMARY;
		}
		A_WeaponReady(fflags);
	}

	// Dedicated function that spawns/despawns the light:
	action void A_ToggleFlashlight()
	{
		// If light already exists, destroy it:
		if (invoker.beam)
		{
			invoker.beam.Destroy();
			A_StartSound("flashlight/off", CHAN_WEAPON); //flashlight sound
		}
		// Otherwise spawn it:
		else
		{
			// Spawn the light and pass values to it:
			invoker.beam = Spotlight(Spawn('Spotlight', (pos.xy, player.viewz - 10)));
			invoker.beam.args[0] = 255; //red
			invoker.beam.args[1] = 255; //green
			invoker.beam.args[2] = 255; //blue
			invoker.beam.args[3] = 512; //length of the spotllight
			invoker.beam.SpotInnerAngle = 8; //inner angle (brightest area)
			invoker.beam.SpotOuterAngle = 24; //outerangle (dimmer area)
			invoker.beam.bATTENUATE = true; //makes it attenuated (will interact with materials)
			A_StartSound("flashlight/on", CHAN_WEAPON); //flashlight sound
		}
	}
	
	action void A_LowerFlashlight()
	{
		// If light already exists, destroy it:
		if (invoker.beam)
		{
			invoker.beam.Destroy();
			A_StartSound("flashlight/off", CHAN_WEAPON); //flashlight sound
		}
	}
	override void DoEffect()
	{
		Super.DoEffect();
		// If there's no valid owner, or the owner switched to a different weapon
		// but the light still exists, remove it:
		if (!owner || !owner.player || !owner.player.readyweapon || owner.player.readyweapon != self)
		{
			if (beam)
			{
				beam.Destroy();
			}
			return;
		}

		// Otherwise keep adjusting the light's angle, pitch and position
		// so it's right below the player's view:
		if (beam)
		{
			beam.SetOrigin((owner.pos.x +1, owner.pos.y, owner.player.viewz - 10), true);
			beam.A_SetAngle(owner.angle +2, SPF_INTERPOLATE);
			beam.A_SetPitch(owner.pitch, SPF_INTERPOLATE);
		}
	}
Default
{
weapon.selectionorder 4000;
    Inventory.PickupSound "misc/p_pkup";
    Inventory.PickupMessage "Picked up a flashlight!";
    Scale 0.75;
    +WEAPON.NOALERT
    +WEAPON.NOAUTOFIRE
    +WEAPON.NOAUTOAIM
    +NOTRIGGER
	}
	States 
	{
	Ready:
		FLIT A 1 A_FlashlightReady();
		loop;
	Fire:
		FLIT A 10 A_ToggleFlashlight();
		goto Ready;
	Select:
		FLIT A 1 A_Raise;
		loop;
	Deselect:
		FLIT A 0 A_LowerFlashlight;
	TrueDeselect:
		FLIT A 1 A_Lower;
		loop;
		Spawn:
    FLSH A -1;
    Stop;
	}
}

Class FlashlightCentered : Weapon
{
Spotlight beam; //pointer to the spawned spotlight

	// Simple wrapper for A_WeaponReady. This makes sure
	// that Fire state cannot be called repeatedbly by
	// holding the attack button, so we don't cycle the
	// flashlight on/off too quickly:
	action void A_FlashlightReady()
	{
		int fflags = 0;
		// Check if player was holding fire button during last tic;
		// if so, disable the ability to fire:
		if (player.oldbuttons & BT_ATTACK)
		{
			fflags |= WRF_NOPRIMARY;
		}
		A_WeaponReady(fflags);
	}

	// Dedicated function that spawns/despawns the light:
	action void A_ToggleFlashlight()
	{
		// If light already exists, destroy it:
		if (invoker.beam)
		{
			invoker.beam.Destroy();
			A_StartSound("flashlight/off", CHAN_WEAPON); //flashlight sound
		}
		// Otherwise spawn it:
		else
		{
			// Spawn the light and pass values to it:
			invoker.beam = Spotlight(Spawn('Spotlight', (pos.xy, player.viewz - 10)));
			invoker.beam.args[0] = 255; //red
			invoker.beam.args[1] = 255; //green
			invoker.beam.args[2] = 255; //blue
			invoker.beam.args[3] = 512; //length of the spotllight
			invoker.beam.SpotInnerAngle = 8; //inner angle (brightest area)
			invoker.beam.SpotOuterAngle = 24; //outerangle (dimmer area)
			invoker.beam.bATTENUATE = true; //makes it attenuated (will interact with materials)
			A_StartSound("flashlight/on", CHAN_WEAPON); //flashlight sound
		}
	}
	
	action void A_LowerFlashlight()
	{
		// If light already exists, destroy it:
		if (invoker.beam)
		{
			invoker.beam.Destroy();
			A_StartSound("flashlight/off", CHAN_WEAPON); //flashlight sound
		}
	}
	override void DoEffect()
	{
		Super.DoEffect();
		// If there's no valid owner, or the owner switched to a different weapon
		// but the light still exists, remove it:
		if (!owner || !owner.player || !owner.player.readyweapon || owner.player.readyweapon != self)
		{
			if (beam)
			{
				beam.Destroy();
			}
			return;
		}

		// Otherwise keep adjusting the light's angle, pitch and position
		// so it's right below the player's view:
		if (beam)
		{
			beam.SetOrigin((owner.pos.xy, owner.player.viewz - 10), true);
			beam.A_SetAngle(owner.angle, SPF_INTERPOLATE);
			beam.A_SetPitch(owner.pitch, SPF_INTERPOLATE);
		}
	}
Default
{
weapon.selectionorder 4000;
    Inventory.PickupSound "misc/p_pkup";
    Inventory.PickupMessage "Picked up a flashlight!";
    Scale 0.75;
    +WEAPON.NOALERT
    +WEAPON.NOAUTOFIRE
    +WEAPON.NOAUTOAIM
    +NOTRIGGER
	}
	States 
	{
	Ready:
		FLIT B 1 A_FlashlightReady();
		loop;
	Fire:
		FLIT B 10 A_ToggleFlashlight();
		goto Ready;
	Select:
		FLIT B 1 A_Raise;
		loop;
	Deselect:
		FLIT B 0 A_LowerFlashlight;
	TrueDeselect:
		FLIT B 1 A_Lower;
		loop;
		Spawn:
    FLSH B -1;
    Stop;
	}
}