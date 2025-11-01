// vaccination_schedule.dart
// This file defines the static, lifetime vaccination schedule for Layer chickens.
import 'package:poultryguard/models/vaccination_event.dart';



class LayerVaccinationSchedule {
  static final List<VaccinationEvent> schedule = [
    VaccinationEvent(name: "Marek's Disease", daysAfterBatchStart: 0, method: "Subcutaneous"), // Day 0 (Hatchery)
    VaccinationEvent(name: "New Castle Disease (ND) - Clone 30", daysAfterBatchStart: 7, method: "Eye Drop"),
    VaccinationEvent(name: "Infectious Bronchitis (IB) - H120", daysAfterBatchStart: 7, method: "Eye Drop"),
    VaccinationEvent(name: "Gumboro (IBD)", daysAfterBatchStart: 14, method: "Drinking Water"),
    VaccinationEvent(name: "New Castle Disease (ND) - LaSota", daysAfterBatchStart: 21, method: "Drinking Water"),
    VaccinationEvent(name: "Fowl Pox", daysAfterBatchStart: 28, method: "Wing Web Stab"),
    VaccinationEvent(name: "Infectious Coryza", daysAfterBatchStart: 42, method: "Injection"), // 6 weeks
    VaccinationEvent(name: "Egg Drop Syndrome (EDS)", daysAfterBatchStart: 56, method: "Injection"), // 8 weeks
    VaccinationEvent(name: "Avian Encephalomyelitis (AE)", daysAfterBatchStart: 70, method: "Drinking Water"), // 10 weeks
    VaccinationEvent(name: "Infectious Bronchitis (IB) - Massachusetts", daysAfterBatchStart: 84, method: "Drinking Water"), // 12 weeks
    VaccinationEvent(name: "New Castle Disease (ND) - K", daysAfterBatchStart: 98, method: "Injection"), // 14 weeks
    VaccinationEvent(name: "Fowl Cholera", daysAfterBatchStart: 112, method: "Injection"), // 16 weeks
    VaccinationEvent(name: "Infectious Laryngotracheitis (ILT)", daysAfterBatchStart: 126, method: "Eye Drop"), // 18 weeks
    // Add more vaccinations as needed for a complete layer life cycle
  ];
}

// You can add BroilerVaccinationSchedule or other types here as well
class BroilerVaccinationSchedule {
  static final List<VaccinationEvent> schedule = [
    // Define broiler specific schedule here
    VaccinationEvent(name: "Broiler Marek's", daysAfterBatchStart: 0, method: "Subcutaneous"),
    VaccinationEvent(name: "Newcastle Disease (NCD) + Infectious Bronchitis (IB)", daysAfterBatchStart: 0, method: "Coarse spray / Eyedrop"), // Day 0 (Hatchery), initial protection
    VaccinationEvent(name: "Infectious Bursal Disease (IBD) / Gumboro (Live Vaccine)", daysAfterBatchStart: 7, method: "Drinking Water"), // Day 7-10, crucial for IBD protection
    VaccinationEvent(name: "Newcastle Disease (NCD) (Live Vaccine - LaSota/B1)", daysAfterBatchStart: 14, method: "Drinking Water / Eyedrop"), // Day 14-18, booster for NCD
    VaccinationEvent(name: "Infectious Bronchitis (IB) (Live Vaccine)", daysAfterBatchStart: 14, method: "Drinking Water / Eyedrop"), // Day 14-18, booster for IB, often combined with NCD
    VaccinationEvent(name: "Fowl Pox", daysAfterBatchStart: 21, method: "Wing web stab"),
    VaccinationEvent(name: "Coccidiosis", daysAfterBatchStart: 0, method: "Coarse spray / Drinking Water"),
    VaccinationEvent(name: "Fowl Cholera (inactivated)", daysAfterBatchStart: 35, method: "Subcutaneous (SQ) / Intramuscular (IM)"),


    // ...
  ];
}
