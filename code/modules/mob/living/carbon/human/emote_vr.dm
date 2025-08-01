#define SWITCH_TAIL_LAYER_UPPER    	"Upper"
#define SWITCH_TAIL_LAYER_STANDARD 	"Standard"
#define SWITCH_TAIL_LAYER_LOWER	   	"Lower"

/mob/living/carbon/human/verb/toggle_resizing_immunity()
	set name = "Toggle Resizing Immunity"
	set desc = "Toggles your ability to resist resizing attempts"
	set category = "IC.Settings"

	resizable = !resizable
	to_chat(src, span_notice("You are now [resizable ? "susceptible" : "immune"] to being resized."))


/mob/living/carbon/human/proc/handle_flip_vr()
	var/original_density = density
	var/original_passflags = pass_flags

	//Briefly un-dense to dodge projectiles
	density = FALSE

	//Parkour!
	var/parkour_chance = 20 //Default
	if(species)
		parkour_chance = species.agility
	if(prob(parkour_chance))
		pass_flags |= PASSTABLE
	else
		Confuse(1) //Thud

	if(dir & WEST)
		SpinAnimation(7,1,0)
	else
		SpinAnimation(7,1,1)

	spawn(7)
		density = original_density
		pass_flags = original_passflags

/mob/living/carbon/human/verb/toggle_gender_identity_vr()
	set name = "Set Gender Identity"
	set desc = "Sets the pronouns when examined and performing an emote."
	set category = "IC.Settings"
	var/new_gender_identity = tgui_input_list(src, "Please select a gender Identity:", "Set Gender Identity", list(FEMALE, MALE, NEUTER, PLURAL, HERM))
	if(!new_gender_identity)
		return 0
	change_gender_identity(new_gender_identity)
	return 1

/mob/living/carbon/human/verb/switch_tail_layer()
	set name = "Switch tail layer"
	set category = "IC.Game"
	set desc = "Switch tail layer to show below/above/between clothing or other things such as wings!."

	var/input = tgui_input_list(src, "Select a tail layer.", "Set Tail Layer", list(SWITCH_TAIL_LAYER_UPPER, SWITCH_TAIL_LAYER_STANDARD, SWITCH_TAIL_LAYER_LOWER))
	if(isnull(input))
		return
	switch(input)
		if(SWITCH_TAIL_LAYER_UPPER)
			tail_layering = input
			write_preference_directly(/datum/preference/numeric/human/tail_layering, TAIL_UPPER_LAYER_HIGH)
		if(SWITCH_TAIL_LAYER_STANDARD)
			tail_layering = input
			write_preference_directly(/datum/preference/numeric/human/tail_layering, TAIL_UPPER_LAYER)
		if(SWITCH_TAIL_LAYER_LOWER)
			tail_layering = input
			write_preference_directly(/datum/preference/numeric/human/tail_layering, TAIL_UPPER_LAYER_LOW)

	update_tail_showing()

/mob/living/carbon/human/verb/hide_wings_vr()
	set name = "Show/Hide wings"
	set category = "IC.Settings"
	set desc = "Hide your wings, or show them if you already hid them."
	wings_hidden = !wings_hidden
	update_wing_showing()
	var/message = ""
	if(!wings_hidden)
		message = "reveals their wings!"
	else
		message = "hides their wings."
	visible_message(span_filter_notice("[src] [message]"))

/mob/living/carbon/human/verb/hide_tail_vr()
	set name = "Show/Hide tail"
	set category = "IC.Settings"
	set desc = "Hide your tail, or show it if you already hid it."
	if(!tail_style) //Just some checks.
		to_chat(src,span_notice("You have no tail to hide!"))
		return
	else //They got a tail. Let's make sure it ain't hiding stuff!
		var/datum/sprite_accessory/tail/current_tail = tail_style
		if((current_tail.hide_body_parts && current_tail.hide_body_parts.len) || current_tail.clip_mask_state || current_tail.clip_mask)
			to_chat(src,span_notice("Your current tail is too considerable to hide!"))
			return
	if(species.tail) //If they're using this verb, they already have a custom tail. This prevents their species tail from showing.
		species.tail = null //Honestly, this should probably be done when a custom tail is chosen, but this is the only time it'd ever matter.
	tail_hidden = !tail_hidden
	update_tail_showing()
	var/message = ""
	if(!tail_hidden)
		message = "reveals their tail!"
	else
		message = "hides their tail."
	visible_message(span_filter_notice("[src] [message]"))

#undef SWITCH_TAIL_LAYER_UPPER
#undef SWITCH_TAIL_LAYER_STANDARD
#undef SWITCH_TAIL_LAYER_LOWER
