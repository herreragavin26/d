import csv

input_file = r"C:\Users\Administrator\Desktop\modded server\config\spawnbalanceutility\BiomeMobWeight.csv"
output_file = r"C:\Users\Administrator\Desktop\modded server\config\spawnbalanceutility\BiomeMobWeight_reduced.csv"

with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
    for line in infile:
        # Keep comment lines as-is
        if line.startswith('*'):
            outfile.write(line)
            continue

        # Parse CSV line
        parts = line.strip().split(',')
        if len(parts) < 7:
            outfile.write(line)
            continue

        mob_name = parts[4].strip()
        try:
            spawn_weight = int(parts[5].strip())
        except:
            outfile.write(line)
            continue

        # Don't modify vanilla main mobs (zombie, skeleton, creeper, spider already at 400)
        if mob_name in ['minecraft:zombie', 'minecraft:skeleton', 'minecraft:creeper', 'minecraft:spider']:
            outfile.write(line)
            continue

        # Reduce modded mob spawn weights
        if spawn_weight == 80:
            parts[5] = ' 15'  # Common modded mobs
        elif spawn_weight >= 40 and spawn_weight < 80:
            parts[5] = ' 10'  # Uncommon modded mobs

        outfile.write(','.join(parts) + '\n')

print("Done!")
