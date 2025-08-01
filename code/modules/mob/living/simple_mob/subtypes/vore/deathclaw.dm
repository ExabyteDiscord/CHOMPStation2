/datum/category_item/catalogue/fauna/deathclaw
	name = "Creature - Deathclaw"
	desc = "Classification: Trioceros dominus\
	<br><br>\
	Originally the deathclaw was a top secret genetics project that was run by ancestral zorren. \
	While it is not immediately evident in their body structure, these creatures bare a \
	subtle genetic connection to Zorren, however, this connection is marred by the other genes that \
	have been grafted onto the DNA structure of the Deathclaw. The creatures are known to attack humans \
	and other animals regularly to protect their territory or to hunt for food. It is speculated that \
	they escaped roughly around the time as whatever calamity befell the zorren many centuries ago \
	as sighting of these beasts in the wild began around that time according to recovered zorren texts. \
	<br>\
	Deathclaws are a large, carnivorous, bipedal reptile species, designed for maximum lethality. \
	Deathclaws are made even more dangerous by their reproductive instincts. deathclaws are an oviparous species, \
	female deathclaws will lay eggs in clusters, sired by the strongest male deathclaws in the pack, typically the alpha male.\
	<br>\
	These creatures are considered an invasive species, and thus hunters are encouraged to hunt them \
	although they are cautioned when doing so due to the danger that the creature poses." //CHOMPedit
	value = CATALOGUER_REWARD_HARD

/mob/living/simple_mob/vore/aggressive/deathclaw
	name = "deathclaw"
	desc = "Big! Big! The size of three men! Claws as long as my forearm! Ripped apart! Ripped apart!"
	tt_desc = "Trioceros dominus"
	catalogue_data = list(/datum/category_item/catalogue/fauna/deathclaw)

	icon_dead = "deathclaw-dead"
	icon_living = "deathclaw"
	icon_state = "deathclaw"
	icon = 'modular_chomp/icons/mob/vore64x64_ch.dmi' //CHOMPEdit changed filepath
	vis_height = 64

	attacktext = list("mauled")

	faction = FACTION_AWAYMISSION //makes away mobs fuckin' be on the same side.

	maxHealth = 200
	health = 200
	see_in_dark = 8

	melee_damage_lower = 5
	melee_damage_upper = 30

	meat_amount = 8
	meat_type = /obj/item/reagent_containers/food/snacks/meat

	old_x = -16
	old_y = 0
	default_pixel_x = -16
	pixel_x = -16
	pixel_y = 0

	max_buckled_mobs = 1 //Yeehaw
	can_buckle = TRUE
	buckle_movable = TRUE
	buckle_lying = FALSE
	mount_offset_x = 5
	mount_offset_y = 30

	ai_holder_type = /datum/ai_holder/simple_mob/melee/deathclaw

	allow_mind_transfer = TRUE

// Activate Noms!
/mob/living/simple_mob/vore/aggressive/deathclaw
	vore_active = 1
	vore_capacity = 2
	vore_max_size = RESIZE_HUGE
	vore_min_size = RESIZE_SMALL
	vore_pounce_chance = 0 // Beat them into crit before eating.
	vore_icons = SA_ICON_LIVING

	can_be_drop_prey = FALSE //CHOMP Add

/mob/living/simple_mob/vore/aggressive/deathclaw/Login()
	. = ..()
	if(!riding_datum)
		riding_datum = new /datum/riding/simple_mob(src)
	add_verb(src, /mob/living/simple_mob/proc/animal_mount)
	add_verb(src, /mob/living/proc/toggle_rider_reins)
	movement_cooldown = 0

/mob/living/simple_mob/vore/aggressive/deathclaw/MouseDrop_T(mob/living/M, mob/living/user)
	return

/mob/living/simple_mob/vore/aggressive/deathclaw/load_default_bellies()
	. = ..()
	var/obj/belly/B = vore_selected
	B.name = "stomach"
	B.desc = "The giant mutant of a lizard finishes stuffing you into its jaws and down its ravenously clenching gullet with a worrying ease and efficiency. An assortment of slick, slimy noises assault your senses for a few gulp-filled moments... before you spill out into the apex predator's swelteringly hot stomach, its walls already possessively grinding into your body."

	B.emote_lists[DM_HOLD] = list(
		"Your surroundings are momentarily filled with the deathclaw's pleased rumbling, its claws stroking over the taut swell you make in its belly.",
		"As time passes, the stiflingly warm atmosphere filling the deathclaw's stuffed gut saps your will to struggle, replacing it with an odd relaxation.",
		"The mutant reptilian wanders about, its stomping footsteps thoroughly jostling your slimy confines in a way that constantly douses you in hot, thick stomach ooze.",
		"The restless, muscular flesh that surrounds you constantly ripples and clenches into you, harrassing you with one possessive, full-body hug after another.",
		"Your gooey surroundings suddenly quiver a little more tightly as the deathclaw lets out a belch, before you're rocked about by its patting claw.",
		"Try as you might, the armored hide and impressive muscles sported by your mutant predator resist  most of your attempts to squirm, and its periodically aggressive, two-armed hugs coerce you into a tight, manageable ball. Now, you're little more than its filling, and it seems keen on keeping you that way.")

	B.emote_lists[DM_DIGEST] = list(
		"The creature emits a pleased rumble before pressing one of its claws against its belly, smushing you up into a tightly packed ball for a couple moments!",
		"The thick, hazy heat permeating the deathclaw's stomach leaves you feeling increasingly faint and disoriented!",
		"As the deathclaw stomps around, you are jostled around with every heavy footfall, leaving you steadily dizzier and thoroughly coated with gutslime!",
		"Every clench of the giant predator's stomach grinds powerful digestive fluids into your body, forcibly churning away your strength!",
		"The deathclaw licks its lips in delight over your flavor before patting its taut gut a few times, filling the roiling chamber with muted, reverberating thuds!",
		"The creature's thick scales make it difficult to move around in that organ, and the clenches it gives whenever you try don't help the situation, those confines churning a little closer every time. You're its meal now, and it has no intention of letting you out easily!")

/datum/ai_holder/simple_mob/melee/deathclaw
	can_breakthrough = TRUE
	violent_breakthrough = TRUE

//YW Addition
/mob/living/simple_mob/vore/aggressive/deathclaw/den

	maxHealth = 400
	health = 400
	see_in_dark = 8
	desc = "Big! Big! The size of three men! Claws as long as my forearm! Ripped apart! Ripped apart! This one seems angrier than most."
	melee_damage_lower = 10
	melee_damage_upper = 40
