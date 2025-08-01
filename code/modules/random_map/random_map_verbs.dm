/client/proc/print_random_map()
	set category = "Debug.Events"
	set name = "Display Random Map"
	set desc = "Show the contents of a random map."

	if(!check_rights_for(src, R_HOLDER))	return

	var/choice = tgui_input_list(usr, "Choose a map to display.", "Map Choice", GLOB.random_maps)
	if(!choice)
		return
	var/datum/random_map/M = GLOB.random_maps[choice]
	if(istype(M))
		M.display_map(usr)

/client/proc/delete_random_map()
	set category = "Debug.Events"
	set name = "Delete Random Map"
	set desc = "Delete a random map."

	if(!check_rights_for(src, R_HOLDER))	return

	var/choice = tgui_input_list(usr, "Choose a map to delete.", "Map Choice", GLOB.random_maps)
	if(!choice)
		return
	var/datum/random_map/M = GLOB.random_maps[choice]
	GLOB.random_maps[choice] = null
	if(istype(M))
		message_admins("[key_name_admin(usr)] has deleted [M.name].")
		log_admin("[key_name(usr)] has deleted [M.name].")
		qdel(M)

/client/proc/create_random_map()
	set category = "Debug.Events"
	set name = "Create Random Map"
	set desc = "Create a random map."

	if(!check_rights_for(src, R_HOLDER))	return

	var/map_datum = tgui_input_list(usr, "Choose a map to create.", "Map Choice", subtypesof(/datum/random_map))
	if(!map_datum)
		return

	var/datum/random_map/M
	if(tgui_alert(usr, "Do you wish to customise the map?","Customize",list("Yes","No")) == "Yes")
		var/seed = tgui_input_text(usr, "Seed? (blank for none)")
		var/lx =   tgui_input_number(usr, "X-size? (blank for default)")
		var/ly =   tgui_input_number(usr, "Y-size? (blank for default)")
		M = new map_datum(seed,null,null,null,lx,ly,1)
	else
		M = new map_datum(null,null,null,null,null,null,1)

	if(M)
		message_admins("[key_name_admin(usr)] has created [M.name].")
		log_admin("[key_name(usr)] has created [M.name].")

/client/proc/apply_random_map()
	set category = "Debug.Events"
	set name = "Apply Random Map"
	set desc = "Apply a map to the game world."

	if(!check_rights_for(src, R_HOLDER))	return

	var/choice = tgui_input_list(usr, "Choose a map to apply.", "Map Choice", GLOB.random_maps)
	if(!choice)
		return
	var/datum/random_map/M = GLOB.random_maps[choice]
	if(istype(M))
		var/tx = tgui_input_number(usr, "X? (default to current turf)")
		var/ty = tgui_input_number(usr, "Y? (default to current turf)")
		var/tz = tgui_input_number(usr, "Z? (default to current turf)")
		if(isnull(tx) || isnull(ty) || isnull(tz))
			var/turf/T = get_turf(usr)
			tx = !isnull(tx) ? tx : T.x
			ty = !isnull(ty) ? ty : T.y
			tz = !isnull(tz) ? tz : T.z
		message_admins("[key_name_admin(usr)] has applied [M.name] at x[tx],y[ty],z[tz].")
		log_admin("[key_name(usr)] has applied [M.name] at x[tx],y[ty],z[tz].")
		M.set_origins(tx,ty,tz)
		M.apply_to_map()

/client/proc/overlay_random_map()
	set category = "Debug.Events"
	set name = "Overlay Random Map"
	set desc = "Apply a map to another map."

	if(!check_rights_for(src, R_HOLDER))	return

	var/choice = tgui_input_list(usr, "Choose a map as base.", "Map Choice", GLOB.random_maps)
	if(!choice)
		return
	var/datum/random_map/base_map = GLOB.random_maps[choice]

	choice = null
	choice = tgui_input_list(usr, "Choose a map to overlay.", "Map Choice", GLOB.random_maps)
	if(!choice)
		return

	var/datum/random_map/overlay_map = GLOB.random_maps[choice]

	if(istype(base_map) && istype(overlay_map))
		var/tx = tgui_input_number(usr, "X? (default to 1)")
		var/ty = tgui_input_number(usr, "Y? (default to 1)")
		if(!tx) tx = 1
		if(!ty) ty = 1
		message_admins("[key_name_admin(usr)] has applied [overlay_map.name] to [base_map.name] at x[tx],y[ty].")
		log_admin("[key_name(usr)] has applied [overlay_map.name] to [base_map.name] at x[tx],y[ty].")
		overlay_map.overlay_with(base_map,tx,ty)
		base_map.display_map(usr)
