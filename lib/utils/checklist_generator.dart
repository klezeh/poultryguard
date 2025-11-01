import '../models/poultry_task.dart';
import '../models/bird_batch.dart';

// Paste the updated generatePoultryChecklist function here
List<PoultryTask> generatePoultryChecklist(DateTime batchStartDate, BirdType birdType) {
  final DateTime today = DateTime.now();
  final int ageInDays = today.difference(batchStartDate).inDays;
  List<PoultryTask> tasks = [];

  // --- Daily Routines (Always present) ---
  tasks.addAll([
    PoultryTask(name: "Check and replenish feed levels in all feeders", category: "Feeding", dueDate: today),
    PoultryTask(name: "Ensure fresh, clean water is continuously available and drinkers are functional", category: "Water Management", dueDate: today),
    PoultryTask(name: "Perform a thorough visual inspection of all birds for signs of illness, injury, or abnormal behavior", category: "Health", dueDate: today),
    PoultryTask(name: "Monitor and record house temperature and humidity levels to ensure optimal environmental conditions", category: "Environment", dueDate: today),
    PoultryTask(name: "Record daily mortality numbers, noting any specific observations for affected birds", category: "Monitoring", dueDate: today),
    PoultryTask(name: "Record daily feed consumption to track flock performance and identify potential issues", category: "Monitoring", dueDate: today),
    PoultryTask(name: "Assess litter condition for moisture and caking; agitate or add fresh bedding as needed to maintain dryness", category: "Litter Management", dueDate: today),
    PoultryTask(name: "Inspect and clean water lines and drinkers to prevent biofilm buildup and ensure water quality", category: "Biosecurity", dueDate: today),
    PoultryTask(name: "Verify proper functioning of ventilation systems and confirm adequate air quality (absence of strong ammonia smell)", category: "Environment", dueDate: today),
    PoultryTask(name: "Remove any dead birds promptly and dispose of them according to biosecurity protocols", category: "Biosecurity", dueDate: today),
    // PoultryTask(name: "Feed and water all birds", category: "Feeding", dueDate: today), // Original task
    // PoultryTask(name: "Clean and disinfect feeders and drinkers", category: "Biosecurity", dueDate: today), // Original task
    // PoultryTask(name: "Remove wet litter and droppings", category: "Litter Management", dueDate: today), // Original task
    // PoultryTask(name: "Observe birds for sickness or injury", category: "Health", dueDate: today), // Original task
    // PoultryTask(name: "Check room temperature and humidity", category: "Environment", dueDate: today), // Original task
    // PoultryTask(name: "Record daily mortality (if any)", category: "Monitoring", dueDate: today), // Original task
    // PoultryTask(name: "Record daily feed consumption", category: "Monitoring", dueDate: today), // Original task
    // PoultryTask(name: "Assess litter moisture and add bedding if necessary", category: "Litter Management", dueDate: today), // Original task
    // PoultryTask(name: "Check ventilation system and air quality", category: "Environment", dueDate: today), // Original task
    // PoultryTask(name: "Monitor water line pressure and leaks", category: "Water Management", dueDate: today), // Original task
  ]);

  // --- Week 1: Brooder phase (ageInDays <= 7) ---
  if (ageInDays <= 7) {
    tasks.addAll([
      PoultryTask(name: "Maintain brooder temperature at recommended levels (start at ~32-33°C, gradually decreasing)", category: "Environment", dueDate: today),
      PoultryTask(name: "Observe chick distribution and activity under brooder heat sources (evenly spread indicates comfort)", category: "Observation", dueDate: today),
      PoultryTask(name: "Ensure easy access to feed and water for all chicks by distributing feeders and drinkers adequately", category: "Feeding", dueDate: today),
      // PoultryTask(name: "Ensure brooder temp is ~32°C", category: "Environment", dueDate: today), // Original task
      // PoultryTask(name: "Check chick behavior under heat source", category: "Observation", dueDate: today), // Original task
      // if (ageInDays <= 3) PoultryTask(name: "Inspect feed trays for adequate feed distribution", category: "Feeding", dueDate: today), // Original task
    ]);

    if (ageInDays == 0) {
      tasks.addAll([
        PoultryTask(name: "Upon chick arrival, ensure brooding area is pre-heated and ready", category: "Environment", dueDate: today),
        PoultryTask(name: "Conduct a crop fill check on a sample of chicks (aim for 90-95% full crops within 6-8 hours post-placement)", category: "Feeding", dueDate: today),
        PoultryTask(name: "Administer initial vaccines (e.g., Marek's, Newcastle, IBD) as per vaccination program", category: "Vaccination", dueDate: today),
        PoultryTask(name: "Provide electrolyte and vitamin supplements in drinking water to aid stress recovery", category: "Feeding", dueDate: today),
        PoultryTask(name: "Confirm coccidiostat inclusion in starter feed (if applicable and not vaccinated)", category: "Feeding", dueDate: today),
        PoultryTask(name: "Perform chick body temperature checks (cloacal temperature) 4-6 hours post-placement", category: "Monitoring", dueDate: today),
        PoultryTask(name: "Ensure all drinkers are filled with fresh, clean water and easily accessible to newly placed chicks", category: "Biosecurity", dueDate: today),
        PoultryTask(name: "Verify proper lighting intensity for initial chick attraction to feed and water (e.g., 20-40 lux)", category: "Lighting", dueDate: today),
        // PoultryTask(name: "Administer Marek’s, Newcastle & IBD vaccine", category: "Vaccination", dueDate: today), // Original task
        // PoultryTask(name: "Start vitamin supplements in water", category: "Feeding", dueDate: today), // Original task
        // PoultryTask(name: "Verify proper coccidiostat inclusion in feed", category: "Feeding", dueDate: today), // Original task
        // PoultryTask(name: "Perform chick body temperature check (4–6 hours post-placement)", category: "Monitoring", dueDate: today), // Original task
        // PoultryTask(name: "Ensure all drinkers are clean and filled with fresh water", category: "Biosecurity", dueDate: today), // Original task
      ]);
    }
  }

  // --- Broiler-specific tasks ---
  if (birdType == BirdType.broilers) {
    if (ageInDays == 0) {
      tasks.addAll([
        PoultryTask(name: "Count received chicks and check for uniformity, activity, and signs of stress", category: "Monitoring", dueDate: today),
        PoultryTask(name: "Ensure adequate lighting (e.g., 20-40 lux for the first 24-48 hours) to encourage eating and drinking", category: "Lighting", dueDate: today),
        PoultryTask(name: "Confirm chick access to feed and water within 1 hour of placement", category: "Feeding", dueDate: today),
        PoultryTask(name: "Perform crop fill check – aim for >90% within 6-8 hours and >95% within 24 hours,\nA crop fill check on chicks is a simple but essential assessment done shortly after placement (typically 2–3 hours after arrival) to determine whether newly hatched chicks have successfully located and consumed feed and water.\nThe crop is a pouch-like part of the digestive tract located at the base of a chick's neck, slightly to the right. It temporarily stores food and water before digestion.\n✅ Purpose of Crop Fill Check\nAssess chick activity and comfort.\nVerify access to feed and water.\nIdentify placement or brooding problems early.", category: "Feeding", dueDate: today),
       
      ]);
    }

    if (ageInDays == 3) {
      tasks.add(PoultryTask(name: "Monitor chicks for pasting (pasty vent) and address underlying causes (e.g., temperature fluctuations)", category: "Health", dueDate: today));
      // PoultryTask(name: "Monitor for pasting (pasty vent)", category: "Health", dueDate: today), // Original task
    }

    if (ageInDays == 5) {
      tasks.add(PoultryTask(name: "Administer Gumboro vaccine (if applicable, based on local disease pressure and vaccination program)", category: "Vaccination", dueDate: today));
      // PoultryTask(name: "Administer Gumboro vaccine", category: "Vaccination", dueDate: today), // Original task
    }

    if (ageInDays == 10) {
      tasks.add(PoultryTask(name: "Administer second Gumboro vaccine or booster (if part of vaccination schedule)", category: "Vaccination", dueDate: today));
      // PoultryTask(name: "Administer second Gumboro vaccine", category: "Vaccination", dueDate: today), // Original task
    }

    if (ageInDays == 14) {
      tasks.addAll([
        PoultryTask(name: "Conduct 14-day body weight check on a representative sample of birds to assess growth rate", category: "Monitoring", dueDate: today),
        PoultryTask(name: "Administer Infectious Bronchitis (IB) vaccine or booster (if part of vaccination schedule)", category: "Vaccination", dueDate: today),
        PoultryTask(name: "Adjust height of feeders and drinkers to ensure comfortable access for growing birds", category: "Management", dueDate: today),
        // PoultryTask(name: "Weigh sample birds – 14-day check", category: "Monitoring", dueDate: today), // Original task
        // PoultryTask(name: "Administer Infectious Bronchitis (IB) vaccine", category: "Vaccination", dueDate: today), // Original task
        // PoultryTask(name: "Adjust feeder/drinker height for growing birds", category: "Management", dueDate: today), // Original task
      ]);
    }

    if (ageInDays >= 1 && ageInDays <= 14) {
      tasks.add(PoultryTask(name: "Gradually reduce brooder temperature by 2-3°C per week until ambient temperature is reached", category: "Environment", dueDate: today));
      // PoultryTask(name: "Maintain brooder temp, reduce 2–3°C weekly", category: "Environment", dueDate: today), // Original task
    }

    if (ageInDays == 21 || ageInDays == 28) {
      tasks.add(PoultryTask(name: "Perform body weight checks and calculate Feed Conversion Ratio (FCR) to evaluate efficiency", category: "Monitoring", dueDate: today));
      // PoultryTask(name: "Weigh birds and assess FCR", category: "Monitoring", dueDate: today), // Original task
    }

    if (ageInDays == 28) {
      tasks.add(PoultryTask(name: "Begin planning for culling or harvesting based on target market weight and flock uniformity", category: "Production", dueDate: today));
      // PoultryTask(name: "Plan culling/harvesting based on weight gain", category: "Production", dueDate: today), // Original task
    }

    if (ageInDays == 30) {
      tasks.add(PoultryTask(name: "Finalize processing or market logistics, including transportation and scheduling", category: "Management", dueDate: today));
      // PoultryTask(name: "Prepare processing/market logistics", category: "Management", dueDate: today), // Original task
    }

    if (ageInDays == 35 || ageInDays == 42) {
      tasks.add(PoultryTask(name: "Conduct final weight evaluations to confirm market readiness and calculate yield", category: "Monitoring", dueDate: today));
      // PoultryTask(name: "Final weigh and evaluate market readiness", category: "Monitoring", dueDate: today), // Original task
    }

    if (ageInDays == 42) {
      tasks.add(PoultryTask(name: "Harvest birds and arrange for transportation to processing facility or market", category: "Production", dueDate: today));
      // PoultryTask(name: "Harvest birds – transport to processing", category: "Production", dueDate: today), // Original task
    }

    if (ageInDays >= 42) {
      tasks.addAll([
        PoultryTask(name: "Thoroughly clean and disinfect the poultry house after flock depopulation (all-in/all-out principle)", category: "Biosecurity", dueDate: today),
        PoultryTask(name: "Allow for a proper downtime period and litter rest before introducing a new flock", category: "Litter Management", dueDate: today),
        PoultryTask(name: "Perform comprehensive equipment maintenance and repair before the next batch arrives", category: "Maintenance", dueDate: today),
        // PoultryTask(name: "Clean and disinfect house thoroughly after sale", category: "Biosecurity", dueDate: today), // Original task
        // PoultryTask(name: "Rest litter and prepare for new flock", category: "Litter Management", dueDate: today), // Original task
        // PoultryTask(name: "Perform equipment maintenance check before next batch", category: "Maintenance", dueDate: today), // Original task
      ]);
    }
  }

  // --- Layer-specific tasks ---
  if (birdType == BirdType.layers) {
    if (ageInDays == 7) {
      tasks.add(PoultryTask(name: "Administer booster vaccines for Newcastle or IBD, as per vaccination schedule", category: "Vaccination", dueDate: today));
      // PoultryTask(name: "Booster: Newcastle or IBD vaccine", category: "Vaccination", dueDate: today), // Original task
    }

    if (ageInDays == 14) {
      tasks.add(PoultryTask(name: "Apply spray or water vaccines for Gumboro/Newcastle, depending on the chosen method", category: "Vaccination", dueDate: today));
      // PoultryTask(name: "Spray or water vaccine for Gumboro/Newcastle", category: "Vaccination", dueDate: today), // Original task
    }

    if (ageInDays == 21) {
      tasks.add(PoultryTask(name: "Perform beak trimming (debeaking) if necessary to prevent feather pecking and cannibalism (consult local regulations)", category: "Management", dueDate: today));
      // PoultryTask(name: "Debeak chicks if needed", category: "Management", dueDate: today), // Original task
    }

    if (ageInDays >= 28 && ageInDays < 56) {
      tasks.addAll([
        PoultryTask(name: "Transition birds from starter to grower mash feed, ensuring a gradual changeover", category: "Feeding", dueDate: today),
        PoultryTask(name: "Continue to gradually reduce brooder temperature as birds feather out and acclimate to house temperature", category: "Environment", dueDate: today),
        // PoultryTask(name: "Switch to Grower mash feed", category: "Feeding", dueDate: today), // Original task
        // PoultryTask(name: "Reduce brooder temperature gradually", category: "Environment", dueDate: today), // Original task
      ]);
      if (ageInDays == 28) {
        tasks.addAll([
          PoultryTask(name: "Administer Infectious Bronchitis (IB) vaccine booster, if scheduled", category: "Vaccination", dueDate: today),
          PoultryTask(name: "Closely monitor the flock for any signs of feather pecking or cannibalism and implement preventative measures", category: "Health", dueDate: today),
          // PoultryTask(name: "Administer Infectious Bronchitis (IB) vaccine booster", category: "Vaccination", dueDate: today), // Original task
          // PoultryTask(name: "Monitor for feather pecking or cannibalism", category: "Health", dueDate: today), // Original task
        ]);
      }
    }

    if (ageInDays >= 56 && ageInDays <= 126) { // Pullet Rearing Phase
      if (ageInDays % 7 == 0) {
        tasks.addAll([
          PoultryTask(name: "Weigh a random sample of birds weekly to track growth and uniformity during the pullet rearing phase", category: "Monitoring", dueDate: today),
          PoultryTask(name: "Check flock uniformity (target >80%) to ensure consistent development of pullets", category: "Monitoring", dueDate: today),
          // PoultryTask(name: "Weigh random sample of birds", category: "Monitoring", dueDate: today), // Original task
          // PoultryTask(name: "Check uniformity (should be >80%)", category: "Monitoring", dueDate: today), // Original task
        ]);
      }
      tasks.add(PoultryTask(name: "Gradually increase daily lighting duration (e.g., by 1 hour per week) to stimulate reproductive development", category: "Lighting", dueDate: today));
      // PoultryTask(name: "Increase lighting by 1 hour weekly", category: "Lighting", dueDate: today), // Original task
    }

    if (ageInDays >= 150) { // Onset of Laying
      tasks.addAll([
        PoultryTask(name: "Collect eggs at least twice daily to maintain egg quality and prevent breakage", category: "Production", dueDate: today),
        PoultryTask(name: "Record daily egg production numbers (e.g., total eggs, percentage lay)", category: "Production", dueDate: today),
        PoultryTask(name: "Inspect egg quality for shell integrity, size, and cleanliness", category: "Production", dueDate: today),
        PoultryTask(name: "Ensure adequate provision of calcium supplements (e.g., oyster shell) to support eggshell formation", category: "Feeding", dueDate: today),
        // PoultryTask(name: "Collect eggs twice daily and record production", category: "Production", dueDate: today), // Original task
        // PoultryTask(name: "Inspect egg quality (shell integrity, size)", category: "Production", dueDate: today), // Original task
        // PoultryTask(name: "Ensure calcium supplements are adequately provided", category: "Feeding", dueDate: today), // Original task
      ]);
    }
  }

  // --- Shared weekly, monthly, quarterly, yearly tasks ---
  if (ageInDays % 7 == 0 && ageInDays <= 42) { // Weekly during broiler growing or early layer phase
    tasks.add(PoultryTask(name: "Perform weekly body weight checks and update Feed Conversion Ratio (FCR) for performance tracking", category: "Monitoring", dueDate: today));
    // PoultryTask(name: "Weekly weight check and FCR update", category: "Monitoring", dueDate: today), // Original task
  }
  if (ageInDays % 7 == 0) { // Weekly for all bird types
    tasks.add(PoultryTask(name: "Record cumulative mortality and culls for the week", category: "Monitoring", dueDate: today));
    // PoultryTask(name: "Record cumulative mortality and culls", category: "Monitoring", dueDate: today), // Original task
  }
  if (ageInDays > 30 && ageInDays % 30 == 0) { // Monthly from 1 month onwards
    tasks.add(PoultryTask(name: "Consider sending fecal samples for parasite testing (e.g., coccidia, worms) if clinical signs are present or as part of routine monitoring", category: "Health", dueDate: today));
    // PoultryTask(name: "Send fecal sample for parasite test", category: "Health", dueDate: today), // Original task
  }
  if (ageInDays % 30 == 0) { // Monthly
    tasks.addAll([
      PoultryTask(name: "Update overall flock feed conversion ratio (FCR) to track efficiency over time", category: "Monitoring", dueDate: today),
      PoultryTask(name: "Update flock average body weight chart to visualize growth trends", category: "Monitoring", dueDate: today),
      PoultryTask(name: "Clean dust and debris from all lighting fixtures to maintain optimal light intensity", category: "Maintenance", dueDate: today),
      PoultryTask(name: "Thoroughly check all feeding and drinking equipment for any signs of wear, damage, or malfunction", category: "Maintenance", dueDate: today),
      // PoultryTask(name: "Update feed conversion ratio (FCR)", category: "Monitoring", dueDate: today), // Original task
      // PoultryTask(name: "Update flock average weight chart", category: "Monitoring", dueDate: today), // Original task
      // PoultryTask(name: "Clean dust from lighting fixtures", category: "Maintenance", dueDate: today), // Original task
      // PoultryTask(name: "Check all feeding and drinking equipment for wear and tear", category: "Maintenance", dueDate: today), // Original task
    ]);
  }
  if (ageInDays % 90 == 0) { // Quarterly
    tasks.add(PoultryTask(name: "Perform a comprehensive inspection of the house roof, walls, and ventilation system for structural integrity and functionality", category: "Maintenance", dueDate: today));
    // PoultryTask(name: "Inspect roof and ventilation system", category: "Maintenance", dueDate: today), // Original task
  }
  if (ageInDays % 365 == 0) { // Yearly
    tasks.add(PoultryTask(name: "Conduct a full litter replacement and thorough cleaning of the house (typically done between flocks)", category: "Litter Management", dueDate: today));
    tasks.add(PoultryTask(name: "Conduct a comprehensive biosecurity audit to review and update all biosecurity protocols and procedures", category: "Biosecurity", dueDate: today));
    // PoultryTask(name: "Full litter replacement", category: "Litter Management", dueDate: today), // Original task
    // PoultryTask(name: "Perform comprehensive biosecurity audit", category: "Biosecurity", dueDate: today), // Original task
  }

  return tasks;
}