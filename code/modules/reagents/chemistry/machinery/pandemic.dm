#define MAIN_SCREEN 1
#define SYMPTOM_DETAILS 2

/obj/machinery/computer/pandemic
	name = "PanD.E.M.I.C 2200"
	desc = "Used to work with viruses."
	density = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
	circuit = /obj/item/circuitboard/computer/pandemic
	use_power = TRUE
	idle_power_usage = 20
	resistance_flags = ACID_PROOF
	var/wait
	var/datum/symptom/selected_symptom
	var/obj/item/reagent_containers/beaker

/obj/machinery/computer/pandemic/Initialize()
	. = ..()
	update_icon()

/obj/machinery/computer/pandemic/Destroy()
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/computer/pandemic/handle_atom_del(atom/A)
	. = ..()
	if(A == beaker)
		beaker = null
		update_icon()

/obj/machinery/computer/pandemic/proc/get_by_index(thing, index)
	if(!beaker || !beaker.reagents)
		return
	var/datum/reagent/blood/B = locate() in beaker.reagents.reagent_list
	if(B && B.data[thing])
		return B.data[thing][index]

/obj/machinery/computer/pandemic/proc/get_virus_id_by_index(index)
	var/datum/disease/D = get_by_index("viruses", index)
	if(D)
		return D.GetDiseaseID()

/obj/machinery/computer/pandemic/proc/get_viruses_data(datum/reagent/blood/B)
	. = list()
	var/list/V = B.get_diseases()
	var/index = 1
	for(var/virus in V)
		var/datum/disease/D = virus
		if(!istype(D) || D.visibility_flags & HIDDEN_PANDEMIC)
			continue

		var/list/this = list()
		this["name"] = D.name
		if(istype(D, /datum/disease/advance))
			var/datum/disease/advance/A = D
			var/disease_name = SSdisease.get_disease_name(A.GetDiseaseID())
			this["can_rename"] = ((disease_name == "Unknown") && A.mutable)
			this["name"] = disease_name
			this["is_adv"] = TRUE
			this["symptoms"] = list()
			for(var/symptom in A.symptoms)
				var/datum/symptom/S = symptom
				var/list/this_symptom = list()
				this_symptom = get_symptom_data(S)
				this["symptoms"] += list(this_symptom)
			this["resistance"] = A.totalResistance()
			this["stealth"] = A.totalStealth()
			this["stage_speed"] = A.totalStageSpeed()
			this["transmission"] = A.totalTransmittable()
		this["index"] = index++
		this["agent"] = D.agent
		this["description"] = D.desc || "none"
		this["spread"] = D.spread_text || "none"
		this["cure"] = D.cure_text || "none"

		. += list(this)

/obj/machinery/computer/pandemic/proc/get_symptom_data(datum/symptom/S)
	. = list()
	var/list/this = list()
	this["name"] = S.name
	this["desc"] = S.desc
	this["stealth"] = S.stealth
	this["resistance"] = S.resistance
	this["stage_speed"] = S.stage_speed
	this["transmission"] = S.transmittable
	this["level"] = S.level
	this["neutered"] = S.neutered
	this["threshold_desc"] = S.threshold_desc
	. += this

/obj/machinery/computer/pandemic/proc/get_resistance_data(datum/reagent/blood/B)
	. = list()
	if(!islist(B.data["resistances"]))
		return
	var/list/resistances = B.data["resistances"]
	for(var/id in resistances)
		var/list/this = list()
		var/datum/disease/D = SSdisease.archive_diseases[id]
		if(D)
			this["id"] = id
			this["name"] = D.name

		. += list(this)

/obj/machinery/computer/pandemic/proc/reset_replicator_cooldown()
	wait = FALSE
	update_icon()
	playsound(loc, 'sound/machines/ping.ogg', 30, 1)

/obj/machinery/computer/pandemic/update_icon()
	if(stat & BROKEN)
		icon_state = (beaker ? "mixer1_b" : "mixer0_b")
		return

	icon_state = "mixer[(beaker) ? "1" : "0"][powered() ? "" : "_nopower"]"
	if(wait)
		add_overlay("waitlight")
	else
		cut_overlays()

/obj/machinery/computer/pandemic/ui_interact(mob/user, ui_key = "main", datum/tgui/ui, force_open = FALSE, datum/tgui/master_ui, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "pandemic", name, 520, 550, master_ui, state)
		ui.open()

/obj/machinery/computer/pandemic/ui_data(mob/user)
	var/list/data = list()
	data["is_ready"] = !wait
	if(beaker)
		data["has_beaker"] = TRUE
		data["beaker_empty"] = (!beaker.reagents.total_volume || !beaker.reagents.reagent_list)
		var/datum/reagent/blood/B = locate() in beaker.reagents.reagent_list
		if(B)
			data["has_blood"] = TRUE
			data[/datum/reagent/blood] = list()
			data[/datum/reagent/blood]["dna"] = B.data["blood_DNA"] || "none"
			data[/datum/reagent/blood]["type"] = B.data["blood_type"] || "none"
			data["viruses"] = get_viruses_data(B)
			data["resistances"] = get_resistance_data(B)
		else
			data["has_blood"] = FALSE
	else
		data["has_beaker"] = FALSE
		data["has_blood"] = FALSE

	return data

/obj/machinery/computer/pandemic/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("eject_beaker")
			replace_beaker(usr)
			. = TRUE
		if("empty_beaker")
			if(beaker)
				beaker.reagents.clear_reagents()
			. = TRUE
		if("empty_eject_beaker")
			if(beaker)
				beaker.reagents.clear_reagents()
				replace_beaker(usr)
			. = TRUE
		if("rename_disease")
			var/id = get_virus_id_by_index(text2num(params["index"]))
			var/datum/disease/advance/A = SSdisease.archive_diseases[id]
			if(!A.mutable)
				return
			if(A)
				var/new_name = sanitize_name(html_encode(params["name"]))
				if(!new_name || ..())
					return
				A.AssignName(new_name)
				. = TRUE
		if("create_culture_bottle")
			var/id = get_virus_id_by_index(text2num(params["index"]))
			var/datum/disease/advance/A = SSdisease.archive_diseases[id]
			if(!istype(A) || !A.mutable)
				to_chat(usr, "<span class='warning'>ERROR: Cannot replicate virus strain.</span>")
				return
			wait = TRUE
			addtimer(CALLBACK(src, .proc/reset_replicator_cooldown), 50)
			A = A.Copy()
			var/list/data = list("blood_DNA" = "UNKNOWN DNA", "blood_type" = "SY", "viruses" = list(A))
			var/obj/item/reagent_containers/glass/bottle/B = new(drop_location())
			B.name = "[A.name] culture bottle"
			B.desc = "A small bottle. Contains [A.agent] culture in synthblood medium."
			B.reagents.add_reagent(/datum/reagent/blood/synthetics, 10, data)
			update_icon()
			var/turf/source_turf = get_turf(src)
			log_virus("A culture bottle was printed for the virus [A.admin_details()] at [loc_name(source_turf)] by [key_name(usr)]")

			. = TRUE
		if("create_vaccine_bottle")
			wait = TRUE
			addtimer(CALLBACK(src, .proc/reset_replicator_cooldown), 400)
			var/id = params["index"]
			var/datum/disease/D = SSdisease.archive_diseases[id]
			var/obj/item/reagent_containers/glass/bottle/B = new(drop_location())
			B.name = "[D.name] vaccine bottle"
			B.reagents.add_reagent(/datum/reagent/vaccine, 15, list(id))

			update_icon()

			. = TRUE

/obj/machinery/computer/pandemic/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers) && !(I.item_flags & ABSTRACT) && I.is_open_container())
		. = TRUE //no afterattack
		if(stat & (NOPOWER|BROKEN))
			return
		var/obj/item/reagent_containers/B = I
		if(!user.transferItemToLoc(B, src))
			return
		replace_beaker(user, B)
		to_chat(user, "<span class='notice'>You insert [I] into [src].</span>")
	else
		return ..()

/obj/machinery/computer/pandemic/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	replace_beaker(user)
	return TRUE

/obj/machinery/computer/pandemic/proc/replace_beaker(mob/living/user, obj/item/reagent_containers/new_beaker)
	if(beaker)
		if(user && Adjacent(user) && user.can_hold_items())
			if(!user.put_in_hands(beaker))
				beaker.forceMove(drop_location())
	if(new_beaker)
		beaker = new_beaker
	else
		beaker = null
	update_icon()
	return TRUE

/obj/machinery/computer/pandemic/on_deconstruction()
	replace_beaker(usr)
	. = ..()
