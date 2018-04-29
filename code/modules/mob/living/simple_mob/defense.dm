// Hit by a projectile.
/mob/living/simple_mob/bullet_act(var/obj/item/projectile/P)
	//Projectiles with bonus SA damage
	if(!P.nodamage)
	//	if(!P.SA_vulnerability || P.SA_vulnerability == intelligence_level)
		if(P.SA_vulnerability & mob_class)
			P.damage += P.SA_bonus_damage

	. = ..()


// When someone clicks us with an empty hand
/mob/living/simple_mob/attack_hand(mob/living/L)
	..()

	switch(L.a_intent)
		if(I_HELP)
			if(health > 0)
				L.visible_message("<span class='notice'>\The [L] [response_help] \the [src].</span>")

		if(I_DISARM)
			L.visible_message("<span class='notice'>\The [L] [response_disarm] \the [src].</span>")
			L.do_attack_animation(src)
			//TODO: Push the mob away or something

		if(I_GRAB)
			if (L == src)
				return
			if (!(status_flags & CANPUSH))
				return
			if(!incapacitated(INCAPACITATION_ALL) && prob(grab_resist))
				L.visible_message("<span class='warning'>\The [L] tries to grab \the [src] but fails!</span>")
				return

			var/obj/item/weapon/grab/G = new /obj/item/weapon/grab(L, src)

			L.put_in_active_hand(G)

			G.synch()
			G.affecting = src
			LAssailant = L

			L.visible_message("<span class='warning'>\The [L] has grabbed [src] passively!</span>")
			L.do_attack_animation(src)

		if(I_HURT)
			var/armor = run_armor_check(def_zone = null, attack_flag = "melee")
			apply_damage(damage = harm_intent_damage, damagetype = BURN, def_zone = null, blocked = armor, blocked = resistance, used_weapon = null, sharp = FALSE, edge = FALSE)
			L.visible_message("<span class='warning'>\The [L] [response_harm] \the [src]!</span>")
			L.do_attack_animation(src)

	return


// When somoene clicks us with an item in hand
/mob/living/simple_mob/attackby(var/obj/item/O, var/mob/user)
	if(istype(O, /obj/item/stack/medical))
		if(stat != DEAD)
			// This could be done better.
			var/obj/item/stack/medical/MED = O
			if(health < getMaxHealth())
				if(MED.amount >= 1)
					adjustBruteLoss(-MED.heal_brute)
					MED.amount -= 1
					if(MED.amount <= 0)
						qdel(MED)
					visible_message("<span class='notice'>\The [user] applies the [MED] on [src].</span>")
		else
			var/datum/gender/T = gender_datums[src.get_visible_gender()]
			to_chat(user, "<span class='notice'>\The [src] is dead, medical items won't bring [T.him] back to life.</span>") // the gender lookup is somewhat overkill, but it functions identically to the obsolete gender macros and future-proofs this code
	if(meat_type && (stat == DEAD))	//if the animal has a meat, and if it is dead.
		if(istype(O, /obj/item/weapon/material/knife) || istype(O, /obj/item/weapon/material/knife/butch))
			harvest(user)

	return ..()


// Handles the actual harming by a melee weapon.
/mob/living/simple_mob/hit_with_weapon(obj/item/O, mob/living/user, var/effective_force, var/hit_zone)
	effective_force = O.force

	//Animals can't be stunned(?)
	if(O.damtype == HALLOSS)
		effective_force = 0
	if(supernatural && istype(O,/obj/item/weapon/nullrod))
		effective_force *= 2
		purge = 3
	if(O.force <= resistance)
		to_chat(user,"<span class='danger'>This weapon is ineffective, it does no damage.</span>")
		return 2 //???

//	react_to_attack(user)

	. = ..()


// Exploding.
/mob/living/simple_mob/ex_act(severity)
	if(!blinded)
		flash_eyes()
	var/armor = run_armor_check(def_zone = null, attack_flag = "bomb")
	var/bombdam = 500
	switch (severity)
		if (1.0)
			bombdam = 500
		if (2.0)
			bombdam = 60
		if (3.0)
			bombdam = 30

	apply_damage(damage = bombdam, damagetype = BRUTE, def_zone = null, blocked = armor, blocked = resistance, used_weapon = null, sharp = FALSE, edge = FALSE)

	if(bombdam > maxHealth)
		gib()


// Fire stuff. Not really exciting at the moment.
/mob/living/simple_mob/handle_fire()
	return
/mob/living/simple_mob/update_fire()
	return
/mob/living/simple_mob/IgniteMob()
	return
/mob/living/simple_mob/ExtinguishMob()
	return


// Electricity
/mob/living/simple_mob/electrocute_act(var/shock_damage, var/obj/source, var/siemens_coeff = 1.0, var/def_zone = null)
	shock_damage *= siemens_coeff
	if(shock_damage < 1)
		return 0

	apply_damage(damage = shock_damage, damagetype = BURN, def_zone = null, blocked = null, blocked = resistance, used_weapon = null, sharp = FALSE, edge = FALSE)
	playsound(loc, "sparks", 50, 1, -1)

	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(5, 1, loc)
	s.start()


// Shot with taser/stunvolver
/mob/living/simple_mob/stun_effect_act(var/stun_amount, var/agony_amount, var/def_zone, var/used_weapon=null)
	if(taser_kill)
		var/stunDam = 0
		var/agonyDam = 0
		var/armor = run_armor_check(def_zone = null, attack_flag = "energy")

		if(stun_amount)
			stunDam += stun_amount * 0.5
			apply_damage(damage = stunDam, damagetype = BURN, def_zone = null, blocked = armor, blocked = resistance, used_weapon = used_weapon, sharp = FALSE, edge = FALSE)

		if(agony_amount)
			agonyDam += agony_amount * 0.5
			apply_damage(damage = agonyDam, damagetype = BURN, def_zone = null, blocked = armor, blocked = resistance, used_weapon = used_weapon, sharp = FALSE, edge = FALSE)


// Electromagnetism
/mob/living/simple_mob/emp_act(severity)
	..() // To emp_act() its contents.
	if(!isSynthetic())
		return
	switch(severity)
		if(1)
		//	adjustFireLoss(rand(15, 25))
			adjustFireLoss(min(60, getMaxHealth()*0.5)) // Weak mobs will always take two direct EMP hits to kill. Stronger ones might take more.
		if(2)
			adjustFireLoss(min(30, getMaxHealth()*0.25))
		//	adjustFireLoss(rand(10, 18))
		if(3)
			adjustFireLoss(min(15, getMaxHealth()*0.125))
		//	adjustFireLoss(rand(5, 12))
		if(4)
			adjustFireLoss(min(7, getMaxHealth()*0.0625))
		//	adjustFireLoss(rand(1, 6))


// Armor
/mob/living/simple_mob/getarmor(def_zone, attack_flag)
	var/armorval = armor[attack_flag]
	if(!armorval)
		return 0
	else
		return armorval

/mob/living/simple_mob/getsoak(def_zone, attack_flag)
	var/armorval = armor_soak[attack_flag]
	if(!armorval)
		return 0
	else
		return armorval
