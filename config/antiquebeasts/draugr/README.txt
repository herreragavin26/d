Mebahel's Draugr Creatures - Configuration Guide
================================================

This file explains what each field in the configuration JSON files does.
All configs are located in this folder.


1) bonus_health_config.json
--------------------------------
Controls extra health (in HP/health points) added on top of each mob's base health.
Valid values: 0 to 100 (anything outside this range will be reset to 0).

  - draugrBonusHealth
    Extra health added to basic Draugr melee units.
    Example: 10 => base HP + 10.

  - draugrArcherBonusHealth
    Extra health added to Draugr Archers.

  - draugrWightBonusHealth
    Extra health added to Draugr Wights (elite melee + magic).

  - draugrScourgeBonusHealth
    Extra health added to Draugr Scourges (stronger spellcaster).

  - draugrOverlordBonusHealth
    Extra health added to the Draugr Overlord boss.
    Useful if you want a longer, more epic fight.

  - skeletonWarriorBonusHealth
    Extra health added to Skeleton Warriors.

  - skeletonWarriorHeadBonusHealth
    Extra health added to the floating Skeleton Warrior Head phase.


2) combat_balancing_config.json
--------------------------------------
Controls combat-related behaviours and probabilities for Draugr entities.

  - draugrMinBlockProbability (float, default 8.0)
    Minimum chance (in %) for a Draugr to decide to block after an attack
    when its health is relatively high.
    Example: 8.0 => at high HP, ~8% chance to block.

  - draugrMaxBlockProbability (float, default 16.0)
    Maximum chance (in %) for a Draugr to block when its HP is low.
    The actual block chance interpolates between min and max based on current HP.
    Higher values => more defensive behaviour at low HP.

  - draugrSpawnWithPotionProbability (float, default 5.0)
    Chance (in %) for a Draugr to spawn with a potion (heal/strength/resistance/etc.).
    Valid range: 0 < value <= 100 (outside this range => reset to 5).
    Example: 5.0 => roughly 1 Draugr out of 20 spawns with a potion.

  - draugrRaidScalingDifficulty (boolean, default true)
    If true, Draugr raids scale with difficulty / wave progression.
    Typically used to make later waves stronger (more mobs).
    true  => raids become harder as if a player as entered the nether in your world.
    false => raids stay at a flat difficulty.


3) spawn_rate_config.json
---------------------------------
Controls the relative rarity / spawn frequency of each custom mob.
All values must be between 0 and 10.
These are NOT direct percentages but weights used in spawn checks.
Higher value => more likely to spawn when conditions are met.

  - draugrSpawnRate (int, default 10)
    Spawn weight for basic Draugr melee mobs.
    0 => effectively never spawns.
    10 => maximum spawn frequency for this mob type.

  - draugrArcherSpawnRate (int, default 9)
    Spawn weight for Draugr Archers.

  - draugrWightSpawnRate (int, default 7)
    Spawn weight for Draugr Wights (stronger unit).

  - draugrScourgeSpawnRate (int, default 5)
    Spawn weight for Draugr Scourges (rare/elite unit).

  - skeletonWarriorSpawnRate (int, default 8)
    Spawn weight for Skeleton Warriors.

Notes on spawn rates:
  - All these values are combined with vanilla spawn conditions (light level, biome, etc.).
  - Setting a value to 0 is a simple way to completely disable a mob type.
  - Values > 10 are automatically reset to defaults when the config loads.

