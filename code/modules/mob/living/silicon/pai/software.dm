var/list/pai_emotions = list(
		"Neutral" = 1,
		"What" = 2,
		"Happy" = 3,
		"Cat" = 4,
		"Extremely Happy" = 5,
		"Face" = 6,
		"Laugh" = 7,
		"Sad" = 8,
		"Angry" = 9,
		"Silly" = 10,
		"Nose" = 11,
		"Smirk" = 12,
		"Exclamation Points" = 13,
		"Question Mark" = 14,
		"Blank" = 15,
		"Off" = 16
	)


GLOBAL_LIST_EMPTY(pai_software_by_key)
GLOBAL_LIST_EMPTY(default_pai_software)
/hook/startup/proc/populate_pai_software_list()
	var/r = 1 // I would use ., but it'd sacrifice runtime detection
	for(var/type in subtypesof(/datum/pai_software))
		var/datum/pai_software/P = new type()
		if(GLOB.pai_software_by_key[P.id])
			var/datum/pai_software/O = GLOB.pai_software_by_key[P.id]
			to_world(span_warning("pAI software module [P.name] has the same key as [O.name]!"))
			r = 0
			continue
		GLOB.pai_software_by_key[P.id] = P
		if(P.default)
			GLOB.default_pai_software[P.id] = P
	return r

/mob/living/silicon/pai/Initialize(mapload)
	. = ..()
	software = GLOB.default_pai_software.Copy()

/mob/living/silicon/pai/verb/paiInterface()
	set category = "Abilities.pAI Commands"
	set name = "Software Interface"

	tgui_interact(src)

/mob/living/silicon/pai/tgui_state(mob/user)
	return GLOB.tgui_self_state

/mob/living/silicon/pai/tgui_interact(mob/user, datum/tgui/ui, datum/tgui/parent_ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "pAIInterface", "pAI Software Interface")
		ui.open()

/mob/living/silicon/pai/tgui_data(mob/user, datum/tgui/ui, datum/tgui_state/state)
	var/list/data = ..()

	// Software we have bought
	var/list/bought_software = list()
	// Software we have not bought
	var/list/not_bought_software = list()

	for(var/key in GLOB.pai_software_by_key)
		var/datum/pai_software/S = GLOB.pai_software_by_key[key]
		var/software_data[0]
		software_data["name"] = S.name
		software_data["id"] = S.id
		if(key in software)
			software_data["on"] = S.is_active(src)
			bought_software.Add(list(software_data))
		else
			software_data["ram"] = S.ram_cost
			not_bought_software.Add(list(software_data))

	data["bought"] = bought_software
	data["not_bought"] = not_bought_software
	data["available_ram"] = ram

	// Emotions
	var/list/emotions = list()
	for(var/name in pai_emotions)
		var/list/emote = list()
		emote["name"] = name
		emote["id"] = pai_emotions[name]
		emotions.Add(list(emote))

	data["emotions"] = emotions
	data["current_emotion"] = card.current_emotion

	return data

/mob/living/silicon/pai/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return TRUE

	switch(action)
		if("software")
			var/soft = params["software"]
			var/datum/pai_software/S = software[soft]
			if(S.toggle)
				S.toggle(src)
			else
				S.tgui_interact(src, parent_ui = ui)
			return TRUE

		if("purchase")
			var/soft = params["purchase"]
			var/datum/pai_software/S = GLOB.pai_software_by_key[soft]
			if(S && (ram >= S.ram_cost))
				ram -= S.ram_cost
				software[S.id] = S
			return TRUE

		if("image")
			var/img = text2num(params["image"])
			if(1 <= img && img <= (pai_emotions.len))
				card.setEmotion(img)
			return TRUE
