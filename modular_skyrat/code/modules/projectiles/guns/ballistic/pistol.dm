/obj/item/gun/ballistic/automatic/pistol/makeshift
	name = "pipe pistol"
	desc = "A somewhat bulky aberration of pipes and wood, in the form of a pistol. It probably should get the job done, still."
	icon = 'modular_skyrat/icons/obj/guns/projectile.dmi'
	icon_state = "pistolms"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/m10mm/makeshift
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 3
	actions_types = list()

/obj/item/gun/ballistic/automatic/pistol/makeshift/update_icon()
	..()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

//USP Match

/obj/item/gun/ballistic/automatic/pistol/uspm
	name = "USP Match"
	desc = "A standard-issued security handgun, chambered in 9mm, refitted to be only capable of firing non-lethal rounds."
	icon = 'modular_skyrat/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_skyrat/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_skyrat/icons/mob/inhands/weapons/guns_righthand.dmi'
	item_state = "usp-m"
	icon_state = "usp-m"
	fire_sound = 'modular_skyrat/sound/weapons/uspshot.ogg'
	mag_type = /obj/item/ammo_box/magazine/usp
	can_suppress = FALSE