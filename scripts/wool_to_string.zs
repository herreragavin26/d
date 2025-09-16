// ===== RECIPE REMOVALS =====
// Remove crafting recipe for fire_for_standing_torch_s
craftingTable.remove(<item:additional_lights:fire_for_standing_torch_s>);

// ===== STACK SIZE CHANGES =====
// Change water bottle stack size to 8
<item:minecraft:potion>.withTag({Potion: "minecraft:water"}).maxStackSize = 8;

// Change purified water bottle stack size to 8
<item:toughasnails:purified_water_bottle>.maxStackSize = 8;

// ===== NEW RECIPES =====
// Convert any wool to string (4 string per wool block)
craftingTable.addShapeless("wool_to_string", <item:minecraft:string> * 4, [<tag:items:minecraft:wool>]);

// Charcoal filter recipe: 2 paper with charcoal in between
craftingTable.addShaped("charcoal_filter", <item:moditems:charcoal_filter>, [
    [<item:minecraft:paper>],
    [<item:minecraft:charcoal>],
    [<item:minecraft:paper>]
]);

// Clean dirty water canteen with charcoal filter
craftingTable.addShapeless("clean_water_canteen_leather", <item:toughasnails:leather_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:leather_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:leather_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("clean_water_canteen_copper", <item:toughasnails:copper_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:copper_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:copper_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("clean_water_canteen_iron", <item:toughasnails:iron_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:iron_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:iron_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("clean_water_canteen_gold", <item:toughasnails:gold_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:gold_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:gold_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("clean_water_canteen_diamond", <item:toughasnails:diamond_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:diamond_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:diamond_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("clean_water_canteen_netherite", <item:toughasnails:netherite_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:netherite_dirty_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:netherite_water_canteen>.withDamage(inputs[1].damage);
});

// Purify water canteen with charcoal filter
craftingTable.addShapeless("purify_water_canteen_leather", <item:toughasnails:leather_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:leather_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:leather_purified_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("purify_water_canteen_copper", <item:toughasnails:copper_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:copper_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:copper_purified_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("purify_water_canteen_iron", <item:toughasnails:iron_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:iron_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:iron_purified_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("purify_water_canteen_gold", <item:toughasnails:gold_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:gold_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:gold_purified_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("purify_water_canteen_diamond", <item:toughasnails:diamond_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:diamond_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:diamond_purified_water_canteen>.withDamage(inputs[1].damage);
});
craftingTable.addShapeless("purify_water_canteen_netherite", <item:toughasnails:netherite_purified_water_canteen>, [<item:moditems:charcoal_filter>, <item:toughasnails:netherite_water_canteen>.anyDamage()], (usualOut, inputs) => {
    return <item:toughasnails:netherite_purified_water_canteen>.withDamage(inputs[1].damage);
});

// Clean dirty water bottle with charcoal filter
craftingTable.addShapeless("clean_water_bottle", <item:minecraft:potion>.withTag({Potion: "minecraft:water"}), [<item:moditems:charcoal_filter>, <item:toughasnails:dirty_water_bottle>]);

// Purify water bottle with charcoal filter
craftingTable.addShapeless("purify_water_bottle", <item:toughasnails:purified_water_bottle>, [<item:moditems:charcoal_filter>, <item:minecraft:potion>.withTag({Potion: "minecraft:water"})]);

// Smelting water bottle to purified water bottle (furnace only)
furnace.addRecipe("water_bottle_purify", <item:toughasnails:purified_water_bottle>, <item:minecraft:potion>.withTag({Potion: "minecraft:water"}), 0.1, 200);

// Smelting canteens to purified (except leather which would burn)
furnace.addRecipe("copper_canteen_purify", <item:toughasnails:copper_purified_water_canteen>, <item:toughasnails:copper_water_canteen>, 0.1, 200);
furnace.addRecipe("iron_canteen_purify", <item:toughasnails:iron_purified_water_canteen>, <item:toughasnails:iron_water_canteen>, 0.1, 200);
furnace.addRecipe("gold_canteen_purify", <item:toughasnails:gold_purified_water_canteen>, <item:toughasnails:gold_water_canteen>, 0.1, 200);
furnace.addRecipe("diamond_canteen_purify", <item:toughasnails:diamond_purified_water_canteen>, <item:toughasnails:diamond_water_canteen>, 0.1, 200);
furnace.addRecipe("netherite_canteen_purify", <item:toughasnails:netherite_purified_water_canteen>, <item:toughasnails:netherite_water_canteen>, 0.1, 200);

// Smelting dirty canteens to clean (except leather which would burn)
furnace.addRecipe("copper_dirty_canteen_clean", <item:toughasnails:copper_water_canteen>, <item:toughasnails:copper_dirty_water_canteen>, 0.1, 200);
furnace.addRecipe("iron_dirty_canteen_clean", <item:toughasnails:iron_water_canteen>, <item:toughasnails:iron_dirty_water_canteen>, 0.1, 200);
furnace.addRecipe("gold_dirty_canteen_clean", <item:toughasnails:gold_water_canteen>, <item:toughasnails:gold_dirty_water_canteen>, 0.1, 200);
furnace.addRecipe("diamond_dirty_canteen_clean", <item:toughasnails:diamond_water_canteen>, <item:toughasnails:diamond_dirty_water_canteen>, 0.1, 200);
furnace.addRecipe("netherite_dirty_canteen_clean", <item:toughasnails:netherite_water_canteen>, <item:toughasnails:netherite_dirty_water_canteen>, 0.1, 200);