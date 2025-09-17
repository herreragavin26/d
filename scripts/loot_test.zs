import crafttweaker.api.loot.modifier.CommonLootModifiers;
import crafttweaker.api.loot.condition.LootTableIdLootCondition;
import crafttweaker.api.loot.condition.LootConditions;

loot.modifiers.register(
    // The name, as explained above
    "its_raining_cats_and_dogs",
    // We create a single condition, which is a 'WeatherCheckLootCondition', i.e. the weather
    // must be in a certain way for this loot modifier to pass.
    LootConditions.only(LootTableIdLootCondition.create("battle_towers:top_chest")),
    // If the conditions match, then we add 5 ghast tears to the loot
    CommonLootModifiers.clearLoot()
);

loot.modifiers.register(
    // The name, as explained above
    "its_raining",
    // We create a single condition, which is a 'WeatherCheckLootCondition', i.e. the weather
    // must be in a certain way for this loot modifier to pass.
    LootConditions.only(LootTableIdLootCondition.create("battle_towers:floor_chest")),
    // If the conditions match, then we add 5 ghast tears to the loot
    CommonLootModifiers.clearLoot()
);