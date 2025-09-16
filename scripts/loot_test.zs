import crafttweaker.api.loot.modifier.CommonLootModifiers;
import crafttweaker.api.loot.condition.LootConditions;

// Add bedrock to battle towers top chest
loot.modifiers.register(
    "bt_top_chest_add_bedrock",
    LootConditions.table("battle_towers:top_chest"),
    CommonLootModifiers.add(<item:minecraft:bedrock>)
);
