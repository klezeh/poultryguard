import 'package:poultryguard/models/poultry_task.dart';
import '../models/bird_batch.dart';
import '../models/batch_vaccination_event.dart'; // Import the new model
import 'package:hive/hive.dart'; // Import Hive for accessing the box

List<PoultryTask> generatePoultryChecklist(BirdBatch batch) {
  final DateTime today = DateTime.now();
  final int ageInDays = today.difference(batch.startDate).inDays;
  List<PoultryTask> tasks = [];

  // --- Daily Routines (Always present) ---

 if (ageInDays < 0) {
  tasks.addAll([
    PoultryTask(name: "Setup feeders and drinkers", category: "Prep", dueDate: today),
    PoultryTask(name: "Stock feeds that will last for at least until 8 weeks", category: "Prep", dueDate: today),
    PoultryTask(name: "Disinfect coop house thoroughly at least 2 weeks before arrival", category: "Prep", dueDate: today),
    PoultryTask(name: "Procure and Install thermometers for checking temperature and hygrometers for checking humidity", category: "Prep", dueDate: today),
    PoultryTask(name: "Ensure that temperature warming and cooling devices are in place for regulating temperature", category: "Prep", dueDate: today),
    PoultryTask(name: "", category: "Prep", dueDate: today),
    PoultryTask(name: "", category: "Prep", dueDate: today),
    PoultryTask(name: "", category: "Prep", dueDate: today),
    PoultryTask(name: "", category: "Prep", dueDate: today),
    PoultryTask(name: "", category: "Prep", dueDate: today),
    PoultryTask(name: "",category: 'Prep', dueDate: today),
  ]);
  }




  if (ageInDays == 0 && ageInDays <= 1000) {
  tasks.addAll([
    PoultryTask(name: "Check and replenish feed levels in all feeders", category: "Feeding", dueDate: today),
    PoultryTask(name: "Ensure fresh, clean water is continuously available and drinkers are functional", category: "Water Management", dueDate: today),
    PoultryTask(name: "Perform a thorough visual inspection of all birds for signs of illness, injury, or abnormal behavior.\n Isolate bird with suspicious appearance or behaviour", category: "Health", dueDate: today),
    PoultryTask(name: "Monitor and record house temperature and humidity levels to ensure optimal environmental conditions", category: "Environment", dueDate: today),
    PoultryTask(name: "Record daily mortality numbers, noting any specific observations for affected birds", category: "Monitoring", dueDate: today),
    PoultryTask(name: "Remove any dead birds promptly and dispose of them according to biosecurity protocols", category: "Biosecurity", dueDate: today),
    PoultryTask(name: "Record daily feed consumption to track flock performance and identify potential issues", category: "Monitoring", dueDate: today),
    PoultryTask(name: "Assess litter condition for moisture and caking; agitate or add fresh bedding as needed to maintain dryness", category: "Litter Management", dueDate: today),
    PoultryTask(name: "Inspect and clean water lines and drinkers to prevent biofilm buildup and ensure water quality", category: "Biosecurity", dueDate: today),
    PoultryTask(name: "Verify proper functioning of ventilation systems and confirm adequate air quality (absence of strong ammonia smell)", category: "Environment", dueDate: today),
    PoultryTask(name: "Take your time to do general observation and take notes if anything is not normal.\n Reach out to Kingsley to discuss your observations immediately",category: 'Management', dueDate: today, ),
  ]);
  }

  // --- Week 1: Brooder phase (ageInDays <= 7) ---
  if (ageInDays <= 7) {
    tasks.addAll([
      PoultryTask(name: "Maintain brooder temperature at recommended levels (start at ~32-33°C, gradually decreasing)", category: "Environment", dueDate: today),
      PoultryTask(name: "Observe chick distribution and activity under brooder heat sources (evenly spread indicates comfort)", category: "Observation", dueDate: today),
      PoultryTask(name: "Ensure easy access to feed and water for all chicks by distributing feeders and drinkers adequately", category: "Feeding", dueDate: today),
    ]);

    if (ageInDays == 0) {
      tasks.addAll([
        PoultryTask(name: "Upon chick arrival, ensure brooding area is pre-heated and ready", category: "Environment", dueDate: today),
        PoultryTask(name: "Conduct a crop fill check on a sample of chicks (aim for 90-95% full crops within 6-8 hours post-placement)", category: "Feeding", dueDate: today),
        PoultryTask(name: "Provide electrolyte and vitamin supplements in drinking water to aid stress recovery", category: "Feeding", dueDate: today),
        PoultryTask(name: "Confirm coccidiostat inclusion in starter feed (if applicable and not vaccinated)", category: "Feeding", dueDate: today),
        PoultryTask(name: "Perform chick body temperature checks (cloacal temperature) 4-6 hours post-placement", category: "Monitoring", dueDate: today),
        PoultryTask(name: "Ensure all drinkers are filled with fresh, clean water and easily accessible to newly placed chicks", category: "Biosecurity", dueDate: today),
        PoultryTask(name: "Verify proper lighting intensity for initial chick attraction to feed and water (e.g., 20-40 lux)", category: "Lighting", dueDate: today),
      ]);
    }
  }

  // --- Broiler-specific tasks ---
  if (batch.type == BirdType.broilers) { // Corrected: Used 'batch.type' instead of 'batch.birdType'
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
    }

    if (ageInDays >= 1 && ageInDays <= 14) {
      tasks.add(PoultryTask(name: "Gradually reduce brooder temperature by 2-3°C per week until ambient temperature is reached", category: "Environment", dueDate: today));
    }

    if (ageInDays == 14) {
      tasks.addAll([
        PoultryTask(name: "Conduct 14-day body weight check on a representative sample of birds to assess growth rate", category: "Monitoring", dueDate: today),
        PoultryTask(name: "Adjust height of feeders and drinkers to ensure comfortable access for growing birds", category: "Management", dueDate: today),
      ]);
    }

    if (ageInDays == 21 || ageInDays == 28) {
      tasks.add(PoultryTask(name: "Perform body weight checks and calculate Feed Conversion Ratio (FCR) to evaluate efficiency", category: "Monitoring", dueDate: today));
    }

    if (ageInDays == 28) {
      tasks.add(PoultryTask(name: "Begin planning for culling or harvesting based on target market weight and flock uniformity", category: "Production", dueDate: today));
    }

    if (ageInDays == 30) {
      tasks.add(PoultryTask(name: "Finalize processing or market logistics, including transportation and scheduling", category: "Management", dueDate: today));
    }

    if (ageInDays == 35 || ageInDays == 42) {
      tasks.add(PoultryTask(name: "Conduct final weight evaluations to confirm market readiness and calculate yield", category: "Monitoring", dueDate: today));
    }

    if (ageInDays == 42) {
      tasks.add(PoultryTask(name: "Harvest birds and arrange for transportation to processing facility or market", category: "Production", dueDate: today));
    }

    if (ageInDays >= 42) {
      tasks.addAll([
        PoultryTask(name: "Thoroughly clean and disinfect the poultry house after flock depopulation (all-in/all-out principle)", category: "Biosecurity", dueDate: today),
        PoultryTask(name: "Allow for a proper downtime period and litter rest before introducing a new flock", category: "Litter Management", dueDate: today),
        PoultryTask(name: "Perform comprehensive equipment maintenance and repair before the next batch arrives", category: "Maintenance", dueDate: today),
      ]);
    }
  }

  // --- Layer-specific tasks ---
  if (batch.type == BirdType.layers) { // Corrected: Used 'batch.type' instead of 'batch.birdType'
    if (ageInDays == 21) {
      tasks.add(PoultryTask(name: "Perform beak trimming (debeaking) if necessary to prevent feather pecking and cannibalism (consult local regulations)", category: "Management", dueDate: today));
    }

    if (ageInDays >= 28 && ageInDays < 56) { // Pullet Rearing Phase
      tasks.addAll([
        PoultryTask(name: "Transition birds from starter to grower mash feed, ensuring a gradual changeover", category: "Feeding", dueDate: today),
        PoultryTask(name: "Continue to gradually reduce brooder temperature as birds feather out and accilmate to house temperature", category: "Environment", dueDate: today),
      ]);
      if (ageInDays == 28) {
        tasks.addAll([
          PoultryTask(name: "Closely monitor the flock for any signs of feather pecking or cannibalism and implement preventative measures", category: "Health", dueDate: today),
        ]);
      }
    }

    if (ageInDays >= 56 && ageInDays <= 126) { // Pullet Rearing Phase
      if (ageInDays % 7 == 0) {
        tasks.addAll([
          PoultryTask(name: "Weigh a random sample of birds weekly to track growth and uniformity during the pullet rearing phase", category: "Monitoring", dueDate: today),
          PoultryTask(name: "Check flock uniformity (target >80%) to ensure consistent development of pullets", category: "Monitoring", dueDate: today),
        ]);
      }
      tasks.add(PoultryTask(name: "Gradually increase daily lighting duration (e.g., by 1 hour per week) to stimulate reproductive development", category: "Lighting", dueDate: today));
    }

    if (ageInDays >= 150) { // Onset of Laying
      tasks.addAll([
        PoultryTask(name: "Collect eggs at least twice daily to maintain egg quality and prevent breakage", category: "Production", dueDate: today),
        PoultryTask(name: "Record daily egg production numbers (e.g., total eggs, percentage lay)", category: "Production", dueDate: today),
        PoultryTask(name: "Inspect egg quality for shell integrity, size, and cleanliness", category: "Production", dueDate: today),
        PoultryTask(name: "Ensure adequate provision of calcium supplements (e.g., oyster shell) to support eggshell formation", category: "Feeding", dueDate: today),
      ]);
    }
  }

  // --- Shared weekly, monthly, quarterly, yearly tasks ---
  if (ageInDays % 7 == 0 && ageInDays <= 42) { // Weekly during broiler growing or early layer phase
    tasks.add(PoultryTask(name: "Perform weekly body weight checks and update Feed Conversion Ratio (FCR) for performance tracking", category: "Monitoring", dueDate: today));
  }
  if (ageInDays % 7 == 0) { // Weekly for all bird types
    tasks.add(PoultryTask(name: "Record cumulative mortality and culls for the week", category: "Monitoring", dueDate: today));
  }
  if (ageInDays > 30 && ageInDays % 30 == 0) { // Monthly from 1 month onwards
    tasks.add(PoultryTask(name: "Consider sending fecal samples for parasite testing (e.g., coccidia, worms) if clinical signs are present or as part of routine monitoring", category: "Health", dueDate: today));
  }
  if (ageInDays % 30 == 0) { // Monthly
    tasks.addAll([
      PoultryTask(name: "Update overall flock feed conversion ratio (FCR) to track efficiency over time", category: "Monitoring", dueDate: today),
      PoultryTask(name: "Update flock average body weight chart to visualize growth trends", category: "Monitoring", dueDate: today),
      PoultryTask(name: "Clean dust and debris from all light fixtures to maintain optimal light intensity", category: "Maintenance", dueDate: today),
      PoultryTask(name: "Thoroughly check all feeding and drinking equipment for any signs of wear, damage, or malfunction", category: "Maintenance", dueDate: today),
    ]);
  }
  if (ageInDays % 90 == 0) { // Quarterly
    tasks.add(PoultryTask(name: "Perform a comprehensive inspection of the house roof, walls, and ventilation system for structural integrity and functionality", category: "Maintenance", dueDate: today));
  }
  if (ageInDays % 365 == 0) { // Yearly
    tasks.add(PoultryTask(name: "Conduct a full litter replacement and thorough cleaning of the house (typically done between flocks)", category: "Litter Management", dueDate: today));
    tasks.add(PoultryTask(name: "Conduct a comprehensive biosecurity audit to review and update all biosecurity protocols and procedures", category: "Biosecurity", dueDate: today));
  }

  // --- NEW FEATURE: Add Vaccination Tasks from Schedule ---
  // Open the Hive box for BatchVaccinationEvent
  final vaccinationBox = Hive.box<BatchVaccinationEvent>('batch_vaccinations');

  // Filter vaccination events for the current batch and for today or past due dates
  final List<BatchVaccinationEvent> batchVaccinations = vaccinationBox.values
      .where((event) =>
          event.batchId == batch.name && // Corrected: 'event.batchId' matches 'batch.name'
          event.scheduledDate.isBefore(today.add(const Duration(days: 1)))) // Include today's and past vaccinations
      .toList();

  for (var event in batchVaccinations) {
    // Check if a similar task already exists to avoid duplicates
    // This assumes that regular checklist items don't exactly match the vaccination event names.
    // If there's a risk of overlap, a more sophisticated de-duplication might be needed.
    bool alreadyExists = tasks.any((task) =>
        task.name == event.vaccinationName && // Corrected: 'event.vaccinationName'
        task.category == "Vaccination" &&
        task.dueDate.day == event.scheduledDate.day &&
        task.dueDate.month == event.scheduledDate.month &&
        task.dueDate.year == event.scheduledDate.year);

    if (!alreadyExists) {
      tasks.add(
        PoultryTask(
          name: event.vaccinationName, // Corrected: 'event.vaccinationName'
          category: "Vaccination",
          dueDate: event.scheduledDate, // Use scheduled date
          isDone: event.isCompleted, // Use the completion status from BatchVaccinationEvent
          isAdhoc: false, // These are scheduled, not ad-hoc
          // You might want to store the event.key here if you intend to update BatchVaccinationEvent directly from PoultryTask's isDone status
          // For example: `firestoreDocId: event.key.toString()` if event.key is unique and can be used as an identifier
        ),
      );
    }
  }

  // Sort tasks by due date or category if desired
  // tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Example sort

  return tasks;
}
