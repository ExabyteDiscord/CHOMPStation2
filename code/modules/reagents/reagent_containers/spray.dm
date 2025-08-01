/obj/item/reagent_containers/spray
	name = "spray bottle"
	desc = "A spray bottle, with an unscrewable top."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "cleaner"
	item_state = "cleaner"
	center_of_mass_x = 16
	center_of_mass_y = 10
	flags = OPENCONTAINER|NOBLUDGEON
	matter = list(MAT_GLASS = 300, MAT_STEEL = 300)
	slot_flags = SLOT_BELT
	throwforce = 3
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 10
	amount_per_transfer_from_this = 10
	unacidable = TRUE //plastic
	possible_transfer_amounts = list(5,10) //Set to null instead of list, if there is only one.
	var/spray_size = 3
	var/list/spray_sizes = list(1,3)
	volume = 250

/obj/item/reagent_containers/spray/Initialize(mapload)
	. = ..()
	src.verbs -= /obj/item/reagent_containers/verb/set_APTFT

/obj/item/reagent_containers/spray/afterattack(atom/A as mob|obj, mob/user as mob, proximity)
	if(istype(A, /obj/item/storage) || istype(A, /obj/structure/table) || istype(A, /obj/structure/closet) || istype(A, /obj/item/reagent_containers) || istype(A, /obj/structure/sink) || istype(A, /obj/structure/janitorialcart))
		return

	if(istype(A, /spell))
		return

	if(proximity)
		if(standard_dispenser_refill(user, A))
			return

	if(reagents.total_volume < amount_per_transfer_from_this)
		balloon_alert(user, "\the [src] is empty!")
		return

	Spray_at(A, user, proximity)

	user.setClickCooldown(4)

	if(reagents.has_reagent(REAGENT_ID_SACID))
		message_admins("[key_name_admin(user)] fired sulphuric acid from \a [src].")
		log_game("[key_name(user)] fired sulphuric acid from \a [src].")
	if(reagents.has_reagent(REAGENT_ID_PACID))
		message_admins("[key_name_admin(user)] fired Polyacid from \a [src].")
		log_game("[key_name(user)] fired Polyacid from \a [src].")
	if(reagents.has_reagent(REAGENT_ID_LUBE))
		message_admins("[key_name_admin(user)] fired Space lube from \a [src].")
		log_game("[key_name(user)] fired Space lube from \a [src].")
	return

/obj/item/reagent_containers/spray/proc/Spray_at(atom/A as mob|obj, mob/user, proximity)
	playsound(src, 'sound/effects/spray2.ogg', 50, 1, -6)
	if (A.density && proximity)
		A.visible_message("[user] sprays [A] with [src].")
		reagents.splash(A, amount_per_transfer_from_this)
	else
		spawn(0)
			var/obj/effect/effect/water/chempuff/D = new/obj/effect/effect/water/chempuff(get_turf(src))
			var/turf/my_target = get_turf(A)
			D.create_reagents(amount_per_transfer_from_this)
			if(!src)
				return
			reagents.trans_to_obj(D, amount_per_transfer_from_this)
			D.set_color()
			D.set_up(my_target, spray_size, 10)
	return

/obj/item/reagent_containers/spray/attack_self(var/mob/user)
	if(!possible_transfer_amounts)
		return
	amount_per_transfer_from_this = next_in_list(amount_per_transfer_from_this, possible_transfer_amounts)
	spray_size = next_in_list(spray_size, spray_sizes)
	balloon_alert(user, "pressure nozzle adjusted to [amount_per_transfer_from_this] units per spray.")

/obj/item/reagent_containers/spray/examine(mob/user)
	. = ..()
	if(loc == user)
		. += "[round(reagents.total_volume)] units left."

/obj/item/reagent_containers/spray/verb/empty()

	set name = "Empty Spray Bottle"
	set category = "Object"
	set src in usr

	if (tgui_alert(usr, "Are you sure you want to empty that?", "Empty Bottle:", list("Yes", "No")) != "Yes")
		return
	if(isturf(usr.loc))
		balloon_alert(usr, "emptied \the [src] onto the floor.")
		reagents.splash(usr.loc, reagents.total_volume)

//space cleaner
/obj/item/reagent_containers/spray/cleaner
	name = "space cleaner"
	desc = "BLAM!-brand non-foaming space cleaner!"

/obj/item/reagent_containers/spray/cleaner/drone
	name = "space cleaner"
	desc = "BLAM!-brand non-foaming space cleaner!"
	volume = 50

/obj/item/reagent_containers/spray/cleaner/Initialize(mapload)
	. = ..()
	reagents.add_reagent(REAGENT_ID_CLEANER, volume)

/obj/item/reagent_containers/spray/sterilizine
	name = REAGENT_ID_STERILIZINE
	desc = "Great for hiding incriminating bloodstains and sterilizing scalpels."

/obj/item/reagent_containers/spray/sterilizine/Initialize(mapload)
	. = ..()
	reagents.add_reagent(REAGENT_ID_STERILIZINE, volume)

/obj/item/reagent_containers/spray/pepper
	name = "pepperspray"
	desc = "Manufactured by UhangInc, used to blind and down an opponent quickly."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "pepperspray"
	item_state = "pepperspray"
	center_of_mass_x = 16
	center_of_mass_y = 16
	possible_transfer_amounts = null
	volume = 40
	var/safety = TRUE

/obj/item/reagent_containers/spray/pepper/Initialize(mapload)
	. = ..()
	reagents.add_reagent(REAGENT_ID_CONDENSEDCAPSAICIN, 40)

/obj/item/reagent_containers/spray/pepper/examine(mob/user)
	. = ..()
	if(Adjacent(user))
		. += "The safety is [safety ? "on" : "off"]."

/obj/item/reagent_containers/spray/pepper/attack_self(var/mob/user)
	safety = !safety
	balloon_alert(user, "safety [safety ? "on" : "off"].")

/obj/item/reagent_containers/spray/pepper/Spray_at(atom/A as mob|obj, mob/user)
	if(safety)
		to_chat(user, span_warning("The safety is on!"))
		return
	. = ..()

/obj/item/reagent_containers/spray/waterflower
	name = "water flower"
	desc = "A seemingly innocent sunflower...with a twist."
	icon = 'icons/obj/device.dmi'
	icon_state = "sunflower"
	item_state = "sunflower"
	amount_per_transfer_from_this = 1
	possible_transfer_amounts = null
	volume = 10
	drop_sound = 'sound/items/drop/herb.ogg'
	pickup_sound = 'sound/items/pickup/herb.ogg'

/obj/item/reagent_containers/spray/waterflower/Initialize(mapload)
	. = ..()
	reagents.add_reagent(REAGENT_ID_WATER, 10)

/obj/item/reagent_containers/spray/chemsprayer
	name = "chem sprayer"
	desc = "A utility used to spray large amounts of reagent in a given area."
	icon = 'icons/obj/gun.dmi'
	icon_state = "chemsprayer"
	item_state = "chemsprayer"
	item_icons = list(slot_l_hand_str = 'icons/mob/items/lefthand_guns.dmi', slot_r_hand_str = 'icons/mob/items/righthand_guns.dmi')
	center_of_mass_x = 16
	center_of_mass_y = 16
	throwforce = 3
	w_class = ITEMSIZE_NORMAL
	possible_transfer_amounts = null
	volume = 600
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 3, TECH_ENGINEERING = 3)

/obj/item/reagent_containers/spray/chemsprayer/Spray_at(atom/A as mob|obj, mob/user)
	playsound(src, 'sound/effects/spray3.ogg', rand(50,1), -6)
	var/direction = get_dir(src, A)
	var/turf/T = get_turf(A)
	var/turf/T1 = get_step(T,turn(direction, 90))
	var/turf/T2 = get_step(T,turn(direction, -90))
	var/list/the_targets = list(T, T1, T2)

	for(var/a = 1 to 3)
		spawn(0)
			if(reagents.total_volume < 1) break
			var/obj/effect/effect/water/chempuff/D = new/obj/effect/effect/water/chempuff(get_turf(src))
			var/turf/my_target = the_targets[a]
			D.create_reagents(amount_per_transfer_from_this)
			if(!src)
				return
			reagents.trans_to_obj(D, amount_per_transfer_from_this)
			D.set_color()
			D.set_up(my_target, rand(6, 8), 2)
	return

/obj/item/reagent_containers/spray/plantbgone
	name = REAGENT_PLANTBGONE
	desc = "Kills those pesky weeds!"
	icon = 'icons/obj/hydroponics_machines.dmi'
	icon_state = "plantbgone"
	item_state = "plantbgone"
	volume = 100

/obj/item/reagent_containers/spray/plantbgone/Initialize(mapload)
	. = ..()
	reagents.add_reagent(REAGENT_ID_PLANTBGONE, 100)

/obj/item/reagent_containers/spray/chemsprayer/hosed
	name = "hose nozzle"
	desc = "A heavy spray nozzle that must be attached to a hose."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "cleaner-industrial"
	item_state = "cleaner"
	center_of_mass_x = 16
	center_of_mass_y = 10

	possible_transfer_amounts = list(5,10,20)

	var/heavy_spray = FALSE
	var/spray_particles = 3

	var/icon/hose_overlay

/obj/item/reagent_containers/spray/chemsprayer/hosed/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/recursive_move)
	AddComponent(/datum/component/hose_connector/input)
	RegisterSignal(src, COMSIG_OBSERVER_MOVED, /obj/item/reagent_containers/spray/chemsprayer/hosed/proc/update_hose)

/obj/item/reagent_containers/spray/chemsprayer/hosed/Destroy()
	UnregisterSignal(src, COMSIG_OBSERVER_MOVED)
	. = ..()

/obj/item/reagent_containers/spray/chemsprayer/hosed/proc/update_hose(atom/source, atom/oldloc, direction, forced, list/old_locs, momentum_change)
	SIGNAL_HANDLER
	for(var/datum/component/hose_connector/HC in GetComponents(/datum/component/hose_connector))
		HC.update_hose_beam()

/obj/item/reagent_containers/spray/chemsprayer/hosed/update_icon()
	..()

	cut_overlays()

	if(!hose_overlay)
		hose_overlay = new/icon(icon, "[icon_state]+hose")

	for(var/datum/component/hose_connector/HC in GetComponents(/datum/component/hose_connector))
		if(HC.get_pairing())
			add_overlay(hose_overlay)
			break

/obj/item/reagent_containers/spray/chemsprayer/hosed/AltClick(mob/living/carbon/user)
	if(++spray_particles > 3) spray_particles = 1

	balloon_alert(user, "dial turned to [spray_particles].")
	return

/obj/item/reagent_containers/spray/chemsprayer/hosed/CtrlClick(var/mob/user)
	if(loc != get_turf(src))
		heavy_spray = !heavy_spray
	else
		. = ..()

/obj/item/reagent_containers/spray/chemsprayer/hosed/Spray_at(atom/A as mob|obj, mob/user)
	update_icon()

	var/direction = get_dir(src, A)
	var/turf/T = get_turf(A)
	var/turf/T1 = get_step(T,turn(direction, 90))
	var/turf/T2 = get_step(T,turn(direction, -90))
	var/list/the_targets = list(T, T1, T2)

	if(src.reagents.total_volume < 1)
		balloon_alert(user, "\the [src] is empty.")
		return

	if(!heavy_spray)
		for(var/a = 1 to 3)
			spawn(0)
				if(reagents.total_volume < 1) break
				playsound(src, 'sound/effects/spray2.ogg', 50, 1, -6)
				var/obj/effect/effect/water/chempuff/D = new/obj/effect/effect/water/chempuff(get_turf(src))
				var/turf/my_target = the_targets[a]
				D.create_reagents(amount_per_transfer_from_this)
				if(!src)
					return
				reagents.trans_to_obj(D, amount_per_transfer_from_this)
				D.set_color()
				D.set_up(my_target, rand(6, 8), 2)
		return

	else
		playsound(src, 'sound/effects/extinguish.ogg', 75, 1, -3)

		for(var/a = 1 to spray_particles)
			spawn(0)
				if(!src || !reagents.total_volume) return

				var/obj/effect/effect/water/W = new /obj/effect/effect/water(get_turf(src))
				var/turf/my_target
				if(a <= the_targets.len)
					my_target = the_targets[a]
				else
					my_target = pick(the_targets)
				W.create_reagents(amount_per_transfer_from_this)
				reagents.trans_to_obj(W, amount_per_transfer_from_this)
				W.set_color()
				W.set_up(my_target)

		return
