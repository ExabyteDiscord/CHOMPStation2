GLOBAL_VAR(antag_add_failed) // Used in antag type voting.
GLOBAL_LIST_EMPTY(additional_antag_types)

/datum/game_mode
	var/name = "invalid"
	var/round_description = "How did you even vote this in?"
	var/extended_round_description = "This roundtype should not be spawned, let alone votable. Someone contact a developer and tell them the game's broken again."
	var/config_tag = null
	var/votable = 1
	var/probability = 0

	var/required_players = 0                 // Minimum players for round to start if voted in.
	var/required_players_secret = 0          // Minimum number of players for that game mode to be chose in Secret
	var/required_enemies = 0                 // Minimum antagonists for round to start.
	var/newscaster_announcements = null
	var/end_on_antag_death = 0               // Round will end when all antagonists are dead.
	var/ert_disabled = 0                     // ERT cannot be called.
	var/deny_respawn = 0	                 // Disable respawn during this round.

	var/list/disabled_jobs = list()           // Mostly used for Malf.  This check is performed in job_controller so it doesn't spawn a regular AI.

	var/shuttle_delay = 1                    // Shuttle transit time is multiplied by this.
	var/auto_recall_shuttle = 0              // Will the shuttle automatically be recalled?

	var/list/antag_tags = list()             // Core antag templates to spawn.
	var/list/antag_templates                 // Extra antagonist types to include.
	var/list/latejoin_templates = list()
	var/round_autoantag = 0                  // Will this round attempt to periodically spawn more antagonists?
	var/antag_scaling_coeff = 5              // Coefficient for scaling max antagonists to player count.
	var/require_all_templates = 0            // Will only start if all templates are checked and can spawn.

	var/station_was_nuked = 0                // See nuclearbomb.dm and malfunction.dm.
	var/explosion_in_progress = 0            // Sit back and relax
	var/waittime_l = 600                     // Lower bound on time before intercept arrives (in tenths of seconds)
	var/waittime_h = 1800                    // Upper bound on time before intercept arrives (in tenths of seconds)

	var/event_delay_mod_moderate             // Modifies the timing of random events.
	var/event_delay_mod_major                // As above.

/datum/game_mode/New()
	..()

/datum/game_mode/Topic(href, href_list[])
	if(..())
		return
	if(href_list["toggle"])
		switch(href_list["toggle"])
			if("respawn")
				deny_respawn = !deny_respawn
			if("ert")
				ert_disabled = !ert_disabled
				announce_ert_disabled()
			if("shuttle_recall")
				auto_recall_shuttle = !auto_recall_shuttle
			if("autotraitor")
				round_autoantag = !round_autoantag
		message_admins("Admin [key_name_admin(usr)] toggled game mode option '[href_list["toggle"]]'.")
	else if(href_list["set"])
		var/choice = ""
		switch(href_list["set"])
			if("shuttle_delay")
				choice = tgui_input_number(usr, "Enter a new shuttle delay multiplier", null, null, 20, 1)
				if(!choice || choice < 1 || choice > 20)
					return
				shuttle_delay = choice
			if("antag_scaling")
				choice = tgui_input_number(usr, "Enter a new antagonist cap scaling coefficient.", null, null, 100, 0)
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				antag_scaling_coeff = choice
			if("event_modifier_moderate")
				choice = tgui_input_number(usr, "Enter a new moderate event time modifier.", null, null, 100, 0)
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				event_delay_mod_moderate = choice
				refresh_event_modifiers()
			if("event_modifier_severe")
				choice = tgui_input_number(usr, "Enter a new moderate event time modifier.", null, null, 100, 0)
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				event_delay_mod_major = choice
				refresh_event_modifiers()
		message_admins("Admin [key_name_admin(usr)] set game mode option '[href_list["set"]]' to [choice].")
	else if(href_list["debug_antag"])
		if(href_list["debug_antag"] == "self")
			usr.client.debug_variables(src)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types[href_list["debug_antag"]]
		if(antag)
			usr.client.debug_variables(antag)
			message_admins("Admin [key_name_admin(usr)] is debugging the [antag.role_text] template.")
	else if(href_list["remove_antag_type"])
		if(antag_tags && (href_list["remove_antag_type"] in antag_tags))
			to_chat(usr, "Cannot remove core mode antag type.")
			return
		var/datum/antagonist/antag = GLOB.all_antag_types[href_list["remove_antag_type"]]
		if(antag_templates && antag_templates.len && antag && (antag in antag_templates) && (antag.id in GLOB.additional_antag_types))
			antag_templates -= antag
			GLOB.additional_antag_types -= antag.id
			message_admins("Admin [key_name_admin(usr)] removed [antag.role_text] template from game mode.")
	else if(href_list["add_antag_type"])
		var/choice = tgui_input_list(usr, "Which type do you wish to add?", "Select Antag Type", GLOB.all_antag_types)
		if(!choice)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types[choice]
		if(antag)
			if(!islist(ticker.mode.antag_templates))
				ticker.mode.antag_templates = list()
			ticker.mode.antag_templates |= antag
			message_admins("Admin [key_name_admin(usr)] added [antag.role_text] template to game mode.")

	// I am very sure there's a better way to do this, but I'm not sure what it might be. ~Z
	spawn(1)
		for(var/datum/admins/admin in world)
			if(usr.client == admin.owner)
				admin.show_game_mode(usr)
				return

/datum/game_mode/proc/announce() //to be called when round starts
	to_world(span_world("The current game mode is [capitalize(name)]!"))
	if(round_description)
		to_world(span_filter_system("[round_description]"))
	if(round_autoantag)
		to_world(span_filter_system("Antagonists will be added to the round automagically as needed."))
	if(antag_templates && antag_templates.len)
		var/antag_summary = span_bold("Possible antagonist types:") + " "
		var/i = 1
		for(var/datum/antagonist/antag in antag_templates)
			if(i > 1)
				if(i == antag_templates.len)
					antag_summary += " and "
				else
					antag_summary += ", "
			antag_summary += "[antag.role_text_plural]"
			i++
		antag_summary += "."
		if(antag_templates.len > 1 && GLOB.master_mode != "secret")
			to_world(span_filter_system("[antag_summary]"))
		else
			message_admins("[antag_summary]")

///can_start()
///Checks to see if the game can be setup and ran with the current number of players or whatnot.
/datum/game_mode/proc/can_start(var/do_not_spawn)
	var/playerC = 0
	for(var/mob/new_player/player in GLOB.player_list)
		if((player.client)&&(player.ready))
			playerC++

	if(GLOB.master_mode=="secret")
		if(playerC < CONFIG_GET(keyed_list/player_requirements_secret)[config_tag])
			return 0
	else
		if(playerC < CONFIG_GET(keyed_list/player_requirements)[config_tag])
			return 0

	if(!(antag_templates && antag_templates.len))
		return 1

	var/enemy_count = 0
	if(antag_tags && antag_tags.len)
		for(var/antag_tag in antag_tags)
			var/datum/antagonist/antag = GLOB.all_antag_types[antag_tag]
			if(!antag)
				continue
			var/list/potential = list()
			if(antag.flags & ANTAG_OVERRIDE_JOB)
				potential = antag.pending_antagonists
			else
				potential = antag.candidates
			if(islist(potential))
				if(require_all_templates && potential.len < antag.initial_spawn_req)
					return 0
				enemy_count += potential.len
				if(enemy_count >= required_enemies)
					return 1
	return 0

/datum/game_mode/proc/refresh_event_modifiers()
	if(event_delay_mod_moderate || event_delay_mod_major)
		SSevents.report_at_round_end = TRUE
		if(event_delay_mod_moderate)
			var/datum/event_container/EModerate = SSevents.event_containers[EVENT_LEVEL_MODERATE]
			EModerate.delay_modifier = event_delay_mod_moderate
		if(event_delay_mod_moderate)
			var/datum/event_container/EMajor = SSevents.event_containers[EVENT_LEVEL_MAJOR]
			EMajor.delay_modifier = event_delay_mod_major

/datum/game_mode/proc/pre_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.build_candidate_list() //compile a list of all eligible candidates

		//antag roles that replace jobs need to be assigned before the job controller hands out jobs.
		if(antag.flags & ANTAG_OVERRIDE_JOB)
			antag.attempt_spawn() //select antags to be spawned

///post_setup()
/datum/game_mode/proc/post_setup()

	refresh_event_modifiers()

	spawn (ROUNDSTART_LOGOUT_REPORT_TIME)
		display_roundstart_logout_report()

	spawn (rand(waittime_l, waittime_h))
		spawn(rand(100,150))
			announce_ert_disabled()

	//Assign all antag types for this game mode. Any players spawned as antags earlier should have been removed from the pending list, so no need to worry about those.
	for(var/datum/antagonist/antag in antag_templates)
		if(!(antag.flags & ANTAG_OVERRIDE_JOB))
			antag.attempt_spawn() //select antags to be spawned
		antag.finalize_spawn() //actually spawn antags
		if(antag.is_latejoin_template())
			latejoin_templates |= antag

	if(emergency_shuttle && auto_recall_shuttle)
		emergency_shuttle.auto_recall = 1

	feedback_set_details("round_start","[time2text(world.realtime)]")
	INVOKE_ASYNC(SSdbcore, TYPE_PROC_REF(/datum/controller/subsystem/dbcore, SetRoundStart))
	if(ticker && ticker.mode)
		feedback_set_details("game_mode","[ticker.mode]")
	feedback_set_details("server_ip","[world.internet_address]:[world.port]")
	return 1

/datum/game_mode/proc/fail_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.reset()

/datum/game_mode/proc/announce_ert_disabled()
	if(!ert_disabled)
		return

	var/list/reasons = list(
		"political instability",
		"quantum fluctuations",
		"hostile raiders",
		"derelict station debris",
		"REDACTED",
		"ancient alien artillery",
		"solar magnetic storms",
		"sentient time-travelling killbots",
		"gravitational anomalies",
		"wormholes to another dimension",
		"a telescience mishap",
		"radiation flares",
		"supermatter dust",
		"leaks into a negative reality",
		"antiparticle clouds",
		"residual bluespace energy",
		"suspected criminal operatives",
		"malfunctioning von Neumann probe swarms",
		"shadowy interlopers",
		"a stranded alien arkship",
		"haywire IPC constructs",
		"rogue Unathi exiles",
		"artifacts of eldritch horror",
		"a brain slug infestation",
		"killer bugs that lay eggs in the husks of the living",
		"a deserted transport carrying alien specimens",
		"an emissary for the gestalt requesting a security detail",
		"a Tajaran slave rebellion",
		"radical Skrellian transevolutionaries",
		"classified security operations"
		)
	command_announcement.Announce("The presence of [pick(reasons)] in the region is tying up all available local emergency resources; emergency response teams cannot be called at this time, and post-evacuation recovery efforts will be substantially delayed.","Emergency Transmission")

/datum/game_mode/proc/check_finished()
	if(emergency_shuttle.returned() || station_was_nuked)
		return 1
	if(end_on_antag_death && antag_templates && antag_templates.len)
		for(var/datum/antagonist/antag in antag_templates)
			if(!antag.antags_are_dead())
				return 0
		if(CONFIG_GET(flag/continuous_rounds))
			emergency_shuttle.auto_recall = 0
			return 0
		return 1
	return 0

/datum/game_mode/proc/cleanup()	//This is called when the round has ended but not the game, if any cleanup would be necessary in that case.
	return

/datum/game_mode/proc/declare_completion()

	var/is_antag_mode = (antag_templates && antag_templates.len)
	check_victory()
	if(is_antag_mode)
		sleep(10)
		for(var/datum/antagonist/antag in antag_templates)
			sleep(10)
			antag.check_victory()
			antag.print_player_summary()
		sleep(10)

	var/clients = 0
	var/surviving_humans = 0
	var/surviving_total = 0
	var/ghosts = 0
	var/escaped_humans = 0
	var/escaped_total = 0
	var/escaped_on_pod_1 = 0
	var/escaped_on_pod_2 = 0
	var/escaped_on_pod_3 = 0
	var/escaped_on_pod_4 = 0 //CHOMP Add
	var/escaped_on_pod_5 = 0
	var/escaped_on_pod_6 = 0 //CHOMP Add
	var/escaped_on_shuttle = 0
	var/escaped_on_pod_large_1 = 0 //CHOMP Add
	var/escaped_on_pod_large_2 = 0 //CHOMP Add
	var/escaped_on_cryopod = 0 //CHOMP Add

	var/list/area/escape_locations = list(/area/shuttle/escape/centcom, /area/shuttle/cryo/centcom, /area/shuttle/escape_pod1/centcom, /area/shuttle/escape_pod2/centcom, /area/shuttle/escape_pod3/centcom, /area/shuttle/escape_pod5/centcom, /area/shuttle/escape_pod6/centcom, /area/shuttle/large_escape_pod1/centcom
, /area/shuttle/large_escape_pod2/centcom) //CHOMP Edit: Appended /centcom to the escape shuttle again to fix transfer message. Added some escape pods to the list.

	for(var/mob/M in GLOB.player_list)
		if(M.client)
			clients++
			var/M_area_type = (get_turf(M))?.loc?.type
			if(ishuman(M))
				if(M.stat != DEAD)
					surviving_humans++
					if(M_area_type in escape_locations)
						escaped_humans++
			if(M.stat != DEAD)
				surviving_total++
				if(is_path_in_list(M_area_type, escape_locations))
					escaped_total++

				if(M_area_type == /area/shuttle/escape/centcom)
					escaped_on_shuttle++

				if(M_area_type == /area/shuttle/escape_pod1/centcom)
					escaped_on_pod_1++
				if(M_area_type == /area/shuttle/escape_pod2/centcom)
					escaped_on_pod_2++
				if(M_area_type == /area/shuttle/escape_pod3/centcom)
					escaped_on_pod_3++
				if(M_area_type == /area/shuttle/escape_pod4/centcom) //CHOMP Add
					escaped_on_pod_4++
				if(M_area_type == /area/shuttle/escape_pod5/centcom)
					escaped_on_pod_5++
				if(M_area_type == /area/shuttle/escape_pod6/centcom) //CHOMP Add
					escaped_on_pod_6++
				if(M_area_type == /area/shuttle/large_escape_pod1/centcom) //CHOMP Add
					escaped_on_pod_large_1++
				if(M_area_type == /area/shuttle/large_escape_pod2/centcom) //CHOMP Add
					escaped_on_pod_large_2++
				if(M_area_type == /area/shuttle/cryo/centcom) //CHOMP Add
					escaped_on_cryopod++



			if(isobserver(M))
				ghosts++

	var/text = ""
	if(surviving_total > 0)
		text += "<br>There [surviving_total>1 ? ("were " + span_bold("[surviving_total] survivors")) : ("was " + span_bold("one survivor"))] ("
		text += span_bold("[escaped_total>0 ? escaped_total : "none"] [emergency_shuttle.evac ? "escaped" : "transferred"]") + ") and " + span_bold("[ghosts] ghosts")
		text += ".<br>"
	else
		text += "There were " + span_bold("no survivors") + " (" + span_bold("[ghosts] ghosts") + ")."
	to_world(span_filter_system(text))

	if(clients > 0)
		feedback_set("round_end_clients",clients)
	if(ghosts > 0)
		feedback_set("round_end_ghosts",ghosts)
	if(surviving_humans > 0)
		feedback_set("survived_human",surviving_humans)
	if(surviving_total > 0)
		feedback_set("survived_total",surviving_total)
	if(escaped_humans > 0)
		feedback_set("escaped_human",escaped_humans)
	if(escaped_total > 0)
		feedback_set("escaped_total",escaped_total)
	if(escaped_on_shuttle > 0)
		feedback_set("escaped_on_shuttle",escaped_on_shuttle)
	if(escaped_on_pod_1 > 0)
		feedback_set("escaped_on_pod_1",escaped_on_pod_1)
	if(escaped_on_pod_2 > 0)
		feedback_set("escaped_on_pod_2",escaped_on_pod_2)
	if(escaped_on_pod_3 > 0)
		feedback_set("escaped_on_pod_3",escaped_on_pod_3)
	if(escaped_on_pod_4 > 0) //CHOMP Add
		feedback_set("escaped_on_pod_4",escaped_on_pod_4)
	if(escaped_on_pod_5 > 0)
		feedback_set("escaped_on_pod_5",escaped_on_pod_5)
	if(escaped_on_pod_6 > 0) //CHOMP Add
		feedback_set("escaped_on_pod_6",escaped_on_pod_6)
	if(escaped_on_pod_large_1 > 0) //CHOMP Add
		feedback_set("escaped_on_pod_large_1",escaped_on_pod_large_1)
	if(escaped_on_pod_large_2 > 0) //CHOMP Add
		feedback_set("escaped_on_pod_large_2",escaped_on_pod_large_2)
	if(escaped_on_cryopod > 0) //CHOMP Add
		feedback_set("escaped_on_cryopod",escaped_on_cryopod)

	send2mainirc("A round of [src.name] has ended - [surviving_total] survivors, [ghosts] ghosts.")
	SSwebhooks.send(
		WEBHOOK_ROUNDEND,
		list(
			"survivors" = surviving_total,
			"escaped" = escaped_total,
			"ghosts" = ghosts,
			"clients" = clients
		)
	)

	return 0

/datum/game_mode/proc/check_win() //universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
	return 0

/datum/game_mode/proc/get_players_for_role(var/role, var/antag_id, var/ghosts_only)
	var/list/players = list()
	var/list/candidates = list()

	var/datum/antagonist/antag_template = GLOB.all_antag_types[antag_id]
	if(!antag_template)
		return candidates

	// If this is being called post-roundstart then it doesn't care about ready status.
	if(ticker && ticker.current_state == GAME_STATE_PLAYING)
		for(var/mob/player in GLOB.player_list)
			if(!player.client)
				continue
			if(isnewplayer(player))
				continue
			if(isobserver(player) && !ghosts_only)
				continue
			if(!role || (player.client.prefs.be_special & role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates |= player.mind
	else
		// Assemble a list of active players without jobbans.
		for(var/mob/new_player/player in GLOB.player_list)
			if( player.client && player.ready )
				players += player

		// Get a list of all the people who want to be the antagonist for this round
		for(var/mob/new_player/player in players)
			if(!role || (player.client.prefs.be_special & role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates += player.mind
				players -= player

		// Below is commented out as an attempt to solve an issue of too little people wanting to join the round due to wanting to have cake and eat it too.
		/*
		// If we don't have enough antags, draft people who voted for the round.
		if(candidates.len < required_enemies)
			for(var/mob/new_player/player in players)
				if(player.ckey in round_voters)
					log_debug("[player.key] voted for this round, so we are drafting them.")
					candidates += player.mind
					players -= player
					break
		*/

	return candidates		// Returns: The number of people who had the antagonist role set to yes, regardless of recomended_enemies, if that number is greater than required_enemies
							//			required_enemies if the number of people with that role set to yes is less than recomended_enemies,
							//			Less if there are not enough valid players in the game entirely to make required_enemies.

/datum/game_mode/proc/num_players()
	. = 0
	for(var/mob/new_player/P in GLOB.player_list)
		if(P.client && P.ready)
			. ++

/datum/game_mode/proc/check_antagonists_topic(href, href_list[])
	return 0

/datum/game_mode/proc/create_antagonists()

	if(!CONFIG_GET(flag/traitor_scaling))
		antag_scaling_coeff = 0

	if(antag_tags && antag_tags.len)
		antag_templates = list()
		for(var/antag_tag in antag_tags)
			var/datum/antagonist/antag = GLOB.all_antag_types[antag_tag]
			if(antag)
				antag_templates |= antag

	if(GLOB.additional_antag_types && GLOB.additional_antag_types.len)
		if(!antag_templates)
			antag_templates = list()
		for(var/antag_type in GLOB.additional_antag_types)
			var/datum/antagonist/antag = GLOB.all_antag_types[antag_type]
			if(antag)
				antag_templates |= antag

	newscaster_announcements = pick(GLOB.newscaster_standard_feeds)

/datum/game_mode/proc/check_victory()
	return

//////////////////////////
//Reports player logouts//
//////////////////////////
/proc/display_roundstart_logout_report()
	var/msg = span_bold("Roundstart logout report")
	msg += "<br><br>"
	for(var/mob/living/L in GLOB.living_mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in GLOB.clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "[span_bold(L.name)] ([L.ckey]), the [L.job] ([span_yellow(span_bold("Disconnected"))])<br>"

		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "[span_bold(L.name)] ([L.ckey]), the [L.job] ([span_yellow(span_bold("Connected, Inactive"))])<br>"
				continue //AFK client
			if(L.stat)
				if(L.suiciding)	//Suicider
					msg += "[span_bold(L.name)] ([L.ckey]), the [L.job] ([span_red(span_bold("Suicide"))])<br>"
					continue //Disconnected client
				if(L.stat == UNCONSCIOUS)
					msg += "[span_bold(L.name)] ([L.ckey]), the [L.job] (Dying)<br>"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "[span_bold(L.name)] ([L.ckey]), the [L.job] (Dead)<br>"
					continue //Dead

			continue //Happy connected client
		for(var/mob/observer/dead/D in GLOB.dead_mob_list)
			if(D.mind && (D.mind.original == L || D.mind.current == L))
				if(L.stat == DEAD)
					if(L.suiciding)	//Suicider
						msg += "[span_bold(L.name)] ([ckey(D.mind.key)]), the [L.job] ([span_red(span_bold("Suicide"))])<br>"
						continue //Disconnected client
					else
						msg += "[span_bold(L.name)] ([ckey(D.mind.key)]), the [L.job] (Dead)<br>"
						continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "[span_bold(L.name)] ([ckey(D.mind.key)]), the [L.job] ([span_red(span_bold("Adminghosted"))])<br>"
						continue //Lolwhat
					else
						msg += "[span_bold(L.name)] ([ckey(D.mind.key)]), the [L.job] ([span_red(span_bold("Ghosted"))])<br>"
						continue //Ghosted while alive

			continue // CHOMPEdit: Escape infinite loop in case there's nobody connected. Shouldn't happen ever, but.

	msg = span_notice(msg)// close the span from right at the top

	for(var/mob/M in GLOB.mob_list)
		if(M.client && check_rights_for(M.client, R_HOLDER))
			to_chat(M,msg)

/proc/get_nt_opposed()
	var/list/dudes = list()
	for(var/mob/living/carbon/human/man in GLOB.player_list)
		if(man.client)
			if(man.client.prefs.economic_status == CLASS_LOWER)
				dudes += man
			else if(man.client.prefs.economic_status == CLASS_LOWMID && prob(50))
				dudes += man
	if(dudes.len == 0) return null
	return pick(dudes)

/proc/show_objectives(var/datum/mind/player)

	if(!player || !player.current) return

	var/obj_count = 1
	to_chat(player.current, span_notice("Your current objectives:"))
	for(var/datum/objective/objective in player.objectives)
		to_chat(player.current, span_bold("Objective #[obj_count]") + ": [objective.explanation_text]")
		obj_count++

/mob/verb/check_round_info()
	set name = "Check Round Info"
	set category = "OOC.Game"

	if(!ticker || !ticker.mode)
		to_chat(usr, span_warning("Something is terribly wrong; there is no gametype."))
		return

	if(GLOB.master_mode != "secret")
		to_chat(usr, span_boldnotice("The roundtype is [capitalize(ticker.mode.name)]"))
		if(ticker.mode.round_description)
			to_chat(usr, span_notice(span_italics("[ticker.mode.round_description]")))
		if(ticker.mode.extended_round_description)
			to_chat(usr, span_notice("[ticker.mode.extended_round_description]"))
	else
		to_chat(usr, span_notice(span_italics("Shhhh") + ". It's a secret."))
	return
