//The UI portion. Should probably be made its own thing/made into a NanoUI thing later.
/datum/controller/subsystem/events
	var/window_x = 700
	var/window_y = 600
	var/report_at_round_end = 0
	var/table_options = " align='center'"
	var/row_options1 = " width='85px'"
	var/row_options2 = " width='260px'"
	var/row_options3 = " width='150px'"
	var/datum/event_container/selected_event_container = null

/datum/controller/subsystem/events/proc/Interact(var/mob/living/user)

	var/html = GetInteractWindow()

	var/datum/browser/popup = new(user, "event_manager", "Event Manager", window_x, window_y)
	popup.set_content(html)
	popup.open()

/datum/controller/subsystem/events/proc/GetInteractWindow()
	var/html = "<A align='right' href='byond://?src=\ref[src];refresh=1'>Refresh</A>"
	html += "<A align='right' href='byond://?src=\ref[src];pause_all=[!CONFIG_GET(flag/allow_random_events)]'>Pause All - [CONFIG_GET(flag/allow_random_events) ? "Pause" : "Resume"]</A>"

	if(selected_event_container)
		var/event_time = max(0, selected_event_container.next_event_time - world.time)
		html += "<A align='right' href='byond://?src=\ref[src];back=1'>Back</A><br>"
		html += "Time till start: [round(event_time / 600, 0.1)]<br>"
		html += "<div class='block'>"
		html += "<h2>Available [GLOB.severity_to_string[selected_event_container.severity]] Events (queued & running events will not be displayed)</h2>"
		html += "<table[table_options]>"
		html += "<tr><td[row_options2]>Name </td><td>Weight </td><td>MinWeight </td><td>MaxWeight </td><td>OneShot </td><td>Enabled </td><td>" + span_alert("CurrWeight") + " </td><td>Remove</td></tr>"
		var/list/active_with_role = number_active_with_role()
		for(var/datum/event_meta/EM in selected_event_container.available_events)
			html += "<tr>"
			html += "<td>[EM.name]</td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];set_weight=\ref[EM]'>[EM.weight]</A></td>"
			html += "<td>[EM.min_weight]</td>"
			html += "<td>[EM.max_weight]</td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];toggle_oneshot=\ref[EM]'>[EM.one_shot]</A></td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];toggle_enabled=\ref[EM]'>[EM.enabled]</A></td>"
			html += "<td>" + span_alert("[selected_event_container.get_weight(EM, active_with_role)]") + "</td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];remove=\ref[EM];EC=\ref[selected_event_container]'>Remove</A></td>"
			html += "</tr>"
		html += "</table>"
		html += "</div>"

		html += "<div class='block'>"
		html += "<h2>Add Event</h2>"
		html += "<table[table_options]>"
		html += "<tr><td[row_options2]>Name</td><td[row_options2]>Type</td><td[row_options1]>Weight</td><td[row_options1]>OneShot</td></tr>"
		html += "<tr>"
		html += "<td><A align='right' href='byond://?src=\ref[src];set_name=\ref[new_event]'>[new_event.name ? new_event.name : "Enter Event"]</A></td>"
		html += "<td><A align='right' href='byond://?src=\ref[src];set_type=\ref[new_event]'>[new_event.event_type ? new_event.event_type : "Select Type"]</A></td>"
		html += "<td><A align='right' href='byond://?src=\ref[src];set_weight=\ref[new_event]'>[new_event.weight ? new_event.weight : 0]</A></td>"
		html += "<td><A align='right' href='byond://?src=\ref[src];toggle_oneshot=\ref[new_event]'>[new_event.one_shot]</A></td>"
		html += "</tr>"
		html += "</table>"
		html += "<A align='right' href='byond://?src=\ref[src];add=\ref[selected_event_container]'>Add</A><br>"
		html += "</div>"
	else
		html += "<A align='right' href='byond://?src=\ref[src];toggle_report=1'>Round End Report: [report_at_round_end ? "On": "Off"]</A><br>"
		html += "<div class='block'>"
		html += "<h2>Event Start</h2>"

		html += "<table[table_options]>"
		html += "<tr><td[row_options1]>Severity</td><td[row_options1]>Starts At</td><td[row_options1]>Starts In</td><td[row_options3]>Adjust Start</td><td[row_options1]>Pause</td><td[row_options1]>Interval Mod</td></tr>"
		for(var/severity = EVENT_LEVEL_MUNDANE to EVENT_LEVEL_MAJOR)
			var/datum/event_container/EC = event_containers[severity]
			var/next_event_at = max(0, EC.next_event_time - world.time)
			html += "<tr>"
			html += "<td>[GLOB.severity_to_string[severity]]</td>"
			html += "<td>[worldtime2stationtime(max(EC.next_event_time, world.time))]</td>"
			html += "<td>[round(next_event_at / 600, 0.1)]</td>"
			html += "<td>"
			html +=   "<A align='right' href='byond://?src=\ref[src];dec_timer=2;event=\ref[EC]'>--</A>"
			html +=   "<A align='right' href='byond://?src=\ref[src];dec_timer=1;event=\ref[EC]'>-</A>"
			html +=   "<A align='right' href='byond://?src=\ref[src];inc_timer=1;event=\ref[EC]'>+</A>"
			html +=   "<A align='right' href='byond://?src=\ref[src];inc_timer=2;event=\ref[EC]'>++</A>"
			html += "</td>"
			html += "<td>"
			html +=   "<A align='right' href='byond://?src=\ref[src];pause=\ref[EC]'>[EC.delayed ? "Resume" : "Pause"]</A>"
			html += "</td>"
			html += "<td>"
			html +=   "<A align='right' href='byond://?src=\ref[src];interval=\ref[EC]'>[EC.delay_modifier]</A>"
			html += "</td>"
			html += "</tr>"
		html += "</table>"
		html += "</div>"

		html += "<div class='block'>"
		html += "<h2>Next Event</h2>"
		html += "<table[table_options]>"
		html += "<tr><td[row_options1]>Severity</td><td[row_options2]>Name</td><td[row_options3]>Event Rotation</td><td>Clear</td></tr>"
		for(var/severity = EVENT_LEVEL_MUNDANE to EVENT_LEVEL_MAJOR)
			var/datum/event_container/EC = event_containers[severity]
			var/datum/event_meta/EM = EC.next_event
			html += "<tr>"
			html += "<td>[GLOB.severity_to_string[severity]]</td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];select_event=\ref[EC]'>[EM ? EM.name : "Random"]</A></td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];view_events=\ref[EC]'>View</A></td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];clear=\ref[EC]'>Clear</A></td>"
			html += "</tr>"
		html += "</table>"
		html += "</div>"

		html += "<div class='block'>"
		html += "<h2>Running Events</h2>"
		html += "Estimated times, affected by process scheduler delays."
		html += "<table[table_options]>"
		html += "<tr><td[row_options1]>Severity</td><td[row_options2]>Name</td><td[row_options1]>Ends At</td><td[row_options1]>Ends In</td><td[row_options3]>Stop</td></tr>"
		for(var/datum/event/E in active_events)
			if(!E.event_meta)
				continue
			var/datum/event_meta/EM = E.event_meta
			var/ends_at = E.startedAt + (E.lastProcessAt() * 20)	// A best estimate, based on how often the alarm manager processes
			var/ends_in = max(0, round((ends_at - world.time) / 600, 0.1))
			html += "<tr>"
			html += "<td>[GLOB.severity_to_string[EM.severity]]</td>"
			html += "<td>[EM.name]</td>"
			html += "<td>[worldtime2stationtime(ends_at)]</td>"
			html += "<td>[ends_in]</td>"
			html += "<td><A align='right' href='byond://?src=\ref[src];stop=\ref[E]'>Stop</A></td>"
			html += "</tr>"
		html += "</table>"
		html += "</div>"

	return html

/datum/controller/subsystem/events/Topic(href, href_list)
	if(..())
		return

	if(href_list["toggle_report"])
		report_at_round_end = !report_at_round_end
		log_and_message_admins("has [report_at_round_end ? "enabled" : "disabled"] the round end event report.")
	else if(href_list["dec_timer"])
		var/datum/event_container/EC = locate(href_list["event"])
		var/decrease = 60 * (10 ** text2num(href_list["dec_timer"]))
		EC.next_event_time -= decrease
		log_and_message_admins("decreased timer for [GLOB.severity_to_string[EC.severity]] events by [decrease/600] minute(s).")
	else if(href_list["inc_timer"])
		var/datum/event_container/EC = locate(href_list["event"])
		var/increase = 60 * (10 ** text2num(href_list["inc_timer"]))
		EC.next_event_time += increase
		log_and_message_admins("increased timer for [GLOB.severity_to_string[EC.severity]] events by [increase/600] minute(s).")
	else if(href_list["select_event"])
		var/datum/event_container/EC = locate(href_list["select_event"])
		var/datum/event_meta/EM = EC.SelectEvent()
		if(EM)
			log_and_message_admins("has queued the [GLOB.severity_to_string[EC.severity]] event '[EM.name]'.")
	else if(href_list["pause"])
		var/datum/event_container/EC = locate(href_list["pause"])
		EC.delayed = !EC.delayed
		log_and_message_admins("has [EC.delayed ? "paused" : "resumed"] countdown for [GLOB.severity_to_string[EC.severity]] events.")
	else if(href_list["pause_all"])
		CONFIG_SET(flag/allow_random_events, text2num(href_list["pause_all"]))
		log_and_message_admins("has [CONFIG_GET(flag/allow_random_events) ? "resumed" : "paused"] countdown for all events.")
	else if(href_list["interval"])
		var/delay = tgui_input_number(usr, "Enter delay modifier. A value less than one means events fire more often, higher than one less often.", "Set Interval Modifier")
		if(delay && delay > 0)
			var/datum/event_container/EC = locate(href_list["interval"])
			EC.delay_modifier = delay
			log_and_message_admins("has set the interval modifier for [GLOB.severity_to_string[EC.severity]] events to [EC.delay_modifier].")
	else if(href_list["stop"])
		if(tgui_alert(usr, "Stopping an event may have unintended side-effects. Continue?","Stopping Event!",list("Yes","No")) != "Yes")
			return
		var/datum/event/E = locate(href_list["stop"])
		var/datum/event_meta/EM = E.event_meta
		log_and_message_admins("has stopped the [GLOB.severity_to_string[EM.severity]] event '[EM.name]'.")
		E.kill()
	else if(href_list["view_events"])
		selected_event_container = locate(href_list["view_events"])
	else if(href_list["back"])
		selected_event_container = null
	else if(href_list["set_name"])
		var/name = sanitize(tgui_input_text(usr, "Enter event name.", "Set Name"))
		if(name)
			var/datum/event_meta/EM = locate(href_list["set_name"])
			EM.name = name
	else if(href_list["set_type"])
		var/type = tgui_input_list(usr, "Select event type.", "Select", allEvents)
		if(type)
			var/datum/event_meta/EM = locate(href_list["set_type"])
			EM.event_type = type
	else if(href_list["set_weight"])
		var/weight = tgui_input_number(usr, "Enter weight. A higher value means higher chance for the event of being selected.", "Set Weight")
		if(weight && weight > 0)
			var/datum/event_meta/EM = locate(href_list["set_weight"])
			EM.weight = weight
			if(EM != new_event)
				log_and_message_admins("has changed the weight of the [GLOB.severity_to_string[EM.severity]] event '[EM.name]' to [EM.weight].")
	else if(href_list["toggle_oneshot"])
		var/datum/event_meta/EM = locate(href_list["toggle_oneshot"])
		EM.one_shot = !EM.one_shot
		if(EM != new_event)
			log_and_message_admins("has [EM.one_shot ? "set" : "unset"] the oneshot flag for the [GLOB.severity_to_string[EM.severity]] event '[EM.name]'.")
	else if(href_list["toggle_enabled"])
		var/datum/event_meta/EM = locate(href_list["toggle_enabled"])
		EM.enabled = !EM.enabled
		log_and_message_admins("has [EM.enabled ? "enabled" : "disabled"] the [GLOB.severity_to_string[EM.severity]] event '[EM.name]'.")
	else if(href_list["remove"])
		if(tgui_alert(usr, "This will remove the event from rotation. Continue?","Removing Event!",list("Yes","No")) != "Yes")
			return
		var/datum/event_meta/EM = locate(href_list["remove"])
		var/datum/event_container/EC = locate(href_list["EC"])
		EC.available_events -= EM
		log_and_message_admins("has removed the [GLOB.severity_to_string[EM.severity]] event '[EM.name]'.")
	else if(href_list["add"])
		if(!new_event.name || !new_event.event_type)
			return
		if(tgui_alert(usr, "This will add a new event to the rotation. Continue?","Add Event!",list("Yes","No")) != "Yes")
			return
		new_event.severity = selected_event_container.severity
		selected_event_container.available_events += new_event
		log_and_message_admins("has added \a [GLOB.severity_to_string[new_event.severity]] event '[new_event.name]' of type [new_event.event_type] with weight [new_event.weight].")
		new_event = new
	else if(href_list["clear"])
		var/datum/event_container/EC = locate(href_list["clear"])
		if(EC.next_event)
			log_and_message_admins("has dequeued the [GLOB.severity_to_string[EC.severity]] event '[EC.next_event.name]'.")
			EC.next_event = null

	Interact(usr)

/client/proc/forceEvent(var/type in SSevents.allEvents)
	set name = "Trigger Event (Debug Only)"
	set category = "Debug.Dangerous"

	if(!check_rights_for(src, R_HOLDER))
		return

	if(ispath(type))
		new type(new /datum/event_meta(EVENT_LEVEL_MAJOR))
		message_admins("[key_name_admin(usr)] has triggered an event. ([type])", 1)

/client/proc/event_manager_panel()
	set name = "Event Manager Panel"
	set category = "Admin.Events"
	SSevents.Interact(usr)
	feedback_add_details("admin_verb","EMP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
