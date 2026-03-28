class AccidentData {
  static List<Map<String, dynamic>> get accidents => [
    {
      "type": "Road Accident",
      "icon": "🚗",
      "severity": "high",
      "keywords": ["crash", "vehicle", "road", "collision", "accident"],
      "situations": [
        "Bike crashes into car",
        "Highway collision at high speed",
        "Chain accident in traffic",
        "Vehicle skids in rain",
        "Pedestrian hit",
        "Fog visibility crash",
        "Brake failure downhill",
        "Animal crossing suddenly"
      ],
      "immediate_steps": [
        "Move to safe area",
        "Call 112 emergency",
        "Turn on hazard lights",
        "Do not move injured"
      ],
      "first_aid": [
        "Stop visible bleeding",
        "Check breathing",
        "Keep person still",
        "Recovery position"
      ],
      "prevention": [
        "Follow traffic rules",
        "Avoid phone while driving",
        "Always wear helmet/seatbelt"
      ],
      "emergency_numbers": ["112", "108", "100"],
      "voice_guide": "Stay calm. Move to safe area. Call emergency 112. Do not move injured person."
    },
    {
      "type": "Heart Attack",
      "icon": "❤️",
      "severity": "critical",
      "keywords": ["heart", "chest pain", "cardiac", "coronary"],
      "situations": [
        "Chest pain suddenly",
        "Collapse while walking",
        "Heavy sweating",
        "Pain in arm/jaw",
        "Shortness of breath",
        "Nausea with chest discomfort"
      ],
      "immediate_steps": [
        "Call emergency immediately",
        "Make person sit down",
        "Keep calm and still",
        "Loosen tight clothing"
      ],
      "first_aid": [
        "Start CPR if unconscious",
        "Check for pulse",
        "Give aspirin if conscious",
        "AED if available"
      ],
      "prevention": [
        "Healthy low-fat diet",
        "Regular exercise",
        "Avoid smoking",
        "Control blood pressure"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Call emergency now. Sit down. Take aspirin. If unconscious, start CPR."
    },
    {
      "type": "Stroke",
      "icon": "🧠",
      "severity": "critical",
      "keywords": ["brain", "paralysis", "facial droop", "slurred speech"],
      "situations": [
        "Face drooping on one side",
        "Speech problem",
        "One side body weakness",
        "Sudden confusion",
        "Loss of balance",
        "Severe headache"
      ],
      "immediate_steps": [
        "Call emergency immediately",
        "Note the time symptoms started",
        "Lay person on side",
        "Do not give food/water"
      ],
      "first_aid": [
        "Check breathing",
        "Keep airway clear",
        "Monitor vitals",
        "Prepare for CPR"
      ],
      "prevention": [
        "Control blood pressure",
        "Healthy lifestyle",
        "Regular checkups",
        "Stop smoking"
      ],
      "emergency_numbers": ["112", "108"],
      "voice_guide": "Call emergency. Note time. Keep calm. Do not give anything by mouth."
    },
    {
      "type": "Electric Shock",
      "icon": "⚡",
      "severity": "high",
      "keywords": ["electric", "shock", "current", "lightning"],
      "situations": [
        "Touching live wire",
        "Faulty appliance",
        "Wet hands on switch",
        "Broken cable",
        "Lightning strike"
      ],
      "immediate_steps": [
        "Turn off power source",
        "Use dry object to separate",
        "Call emergency",
        "Do not touch victim directly"
      ],
      "first_aid": [
        "Start CPR if not breathing",
        "Treat electrical burns",
        "Check for injuries",
        "Keep warm"
      ],
      "prevention": [
        "Proper electrical wiring",
        "Avoid handling with wet hands",
        "Regular inspection",
        "Use surge protectors"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Turn off power first. Do not touch. Call emergency. Start CPR if needed."
    },
    {
      "type": "Fire Accident",
      "icon": "🔥",
      "severity": "high",
      "keywords": ["fire", "burn", "smoke", "explosion"],
      "situations": [
        "Gas leak explosion",
        "Short circuit fire",
        "House fire",
        "Factory fire",
        "Kitchen fire"
      ],
      "immediate_steps": [
        "Evacuate immediately",
        "Call fire brigade",
        "Use fire extinguisher",
        "Close doors behind you"
      ],
      "first_aid": [
        "Cool burns with water",
        "Cover with clean cloth",
        "Do not break blisters",
        "Treat for shock"
      ],
      "prevention": [
        "Check wiring regularly",
        "Install smoke alarms",
        "Keep fire extinguisher",
        "Never leave cooking unattended"
      ],
      "emergency_numbers": ["112", "101", "102"],
      "voice_guide": "Get out fast. Call fire brigade. Cool burns with water. Do not use ice."
    },
    {
      "type": "Drowning",
      "icon": "🌊",
      "severity": "critical",
      "keywords": ["water", "drowning", "pool", "river", "flood"],
      "situations": [
        "Fall into river",
        "Pool accident",
        "Boat capsizing",
        "Flood emergency",
        "Bathtub incident"
      ],
      "immediate_steps": [
        "Remove from water safely",
        "Call emergency",
        "Check breathing",
        "Start rescue if trained"
      ],
      "first_aid": [
        "Start CPR immediately",
        "Remove water from lungs",
        "Keep warm",
        "Watch for vomiting"
      ],
      "prevention": [
        "Learn to swim",
        "Always wear life jacket",
        "Never swim alone",
        "Supervise children"
      ],
      "emergency_numbers": ["112", "108", "1091"],
      "voice_guide": "Remove from water. Call emergency. Start CPR if not breathing. Keep warm."
    },
    {
      "type": "Choking",
      "icon": "🍽️",
      "severity": "high",
      "keywords": ["choking", "throat", "food stuck", "airway"],
      "situations": [
        "Food stuck in throat",
        "Child swallows small toy",
        "Eating too fast",
        "Laughing while eating",
        "Denture swallowing"
      ],
      "immediate_steps": [
        "Encourage coughing",
        "Call emergency if fails",
        "Stay calm"
      ],
      "first_aid": [
        "Heimlich maneuver",
        "Back blows for infants",
        "Chest thrusts",
        "CPR if unconscious"
      ],
      "prevention": [
        "Chew food properly",
        "Avoid talking while eating",
        "Cut food small for kids",
        "Supervise children eating"
      ],
      "emergency_numbers": ["112", "108"],
      "voice_guide": "Cough if you can. If not, I will help you with Heimlich maneuver."
    },
    {
      "type": "Poisoning",
      "icon": "☠️",
      "severity": "high",
      "keywords": ["poison", "toxic", "overdose", "chemical"],
      "situations": [
        "Chemical intake",
        "Food poisoning",
        "Gas inhalation",
        "Medicine overdose",
        "Alcohol poisoning"
      ],
      "immediate_steps": [
        "Call emergency",
        "Identify the poison",
        "Do not induce vomiting",
        "Fresh air if gas"
      ],
      "first_aid": [
        "Do not make vomit",
        "Give water if conscious",
        "Monitor breathing",
        "Save poison container"
      ],
      "prevention": [
        "Store chemicals safely",
        "Check medicine expiry",
        "Keep away from children",
        "Proper food storage"
      ],
      "emergency_numbers": ["112", "108", "104"],
      "voice_guide": "Do not vomit. Call emergency. Tell them what was swallowed."
    },
    {
      "type": "Snake Bite",
      "icon": "🐍",
      "severity": "high",
      "keywords": ["snake", "bite", "venom", "reptile"],
      "situations": [
        "Walking in field",
        "Sleeping on floor",
        "Night walking",
        "Forest work",
        "Collecting firewood"
      ],
      "immediate_steps": [
        "Stay calm and still",
        "Immobilize the limb",
        "Call emergency",
        "Do not run"
      ],
      "first_aid": [
        "Do not cut the wound",
        "Do not suck venom",
        "Keep limb below heart",
        "Remove tight items"
      ],
      "prevention": [
        "Wear boots in fields",
        "Use torch at night",
        "Check bed before sleeping",
        "Clear around house"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Stay calm. Do not move. Keep limb still. Call emergency now."
    },
    {
      "type": "Dog Bite",
      "icon": "🐕",
      "severity": "medium",
      "keywords": ["dog", "bite", "animal", "rabies"],
      "situations": [
        "Stray dog attack",
        "Pet dog bite",
        "Child playing with dog",
        "Feeding unknown dog"
      ],
      "immediate_steps": [
        "Move away from dog",
        "Wash wound with soap",
        "Apply antiseptic",
        "Visit doctor immediately"
      ],
      "first_aid": [
        "Wash with soap 10 min",
        "Apply antiseptic",
        "Cover with clean cloth",
        "Get rabies vaccine"
      ],
      "prevention": [
        "Do not provoke dogs",
        "Vaccinate pets",
        "Supervise children",
        "Avoid unknown dogs"
      ],
      "emergency_numbers": ["112", "108"],
      "voice_guide": "Wash wound thoroughly. Get medical help. Rabies vaccine is important."
    },
    {
      "type": "Fracture",
      "icon": "🦴",
      "severity": "medium",
      "keywords": ["bone", "fracture", "break", "injury"],
      "situations": [
        "Fall from height",
        "Sports injury",
        "Accident impact",
        "Twisted ankle"
      ],
      "immediate_steps": [
        "Do not move injured part",
        "Support the limb",
        "Call emergency",
        "Keep still"
      ],
      "first_aid": [
        "Apply splint",
        "Ice pack for swelling",
        "Do not force movement",
        "Pain relief"
      ],
      "prevention": [
        "Use safety gear",
        "Safe ladder practices",
        "Exercise properly",
        "Calcium rich diet"
      ],
      "emergency_numbers": ["112", "108"],
      "voice_guide": "Do not move. Support the injured part. Call emergency."
    },
    {
      "type": "Burn Injury",
      "icon": "🔥",
      "severity": "high",
      "keywords": ["burn", "scald", "hot", "skin"],
      "situations": [
        "Hot liquid spill",
        "Fire burn",
        "Electric burn",
        "Chemical burn",
        "Sunburn"
      ],
      "immediate_steps": [
        "Remove heat source",
        "Cool area with water",
        "Do not apply ice",
        "Cover loosely"
      ],
      "first_aid": [
        "Run cool water 15 min",
        "Do not break blisters",
        "Cover with clean cloth",
        "Take pain medicine"
      ],
      "prevention": [
        "Handle fire carefully",
        "Keep hot liquids away",
        "Use protective gear",
        "Child proof kitchen"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Cool with water for 15 minutes. Do not apply ice or butter."
    },
    {
      "type": "Fall from Height",
      "icon": "⬇️",
      "severity": "critical",
      "keywords": ["fall", "height", "building", "tree"],
      "situations": [
        "Falling from building",
        "Tree fall",
        "Ladder slip",
        "Roof accident",
        "Cliff fall"
      ],
      "immediate_steps": [
        "Do not move victim",
        "Call emergency immediately",
        "Check breathing",
        "Keep still"
      ],
      "first_aid": [
        "Check breathing",
        "Stabilize spine",
        "Control bleeding",
        "Treat for shock"
      ],
      "prevention": [
        "Use safety harness",
        "Secure ladders",
        "Install railings",
        "Never work alone"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Do not move the person. Call emergency. Check breathing."
    },
    {
      "type": "Heat Stroke",
      "icon": "🌡️",
      "severity": "high",
      "keywords": ["heat", "sun", "temperature", "dehydration"],
      "situations": [
        "Working in direct sun",
        "Dehydration",
        "Long heat exposure",
        "Hot environment work"
      ],
      "immediate_steps": [
        "Move to shade",
        "Give water to drink",
        "Remove excess clothes",
        "Call emergency"
      ],
      "first_aid": [
        "Cool body with water",
        "Apply wet cloths",
        "Fan the person",
        "Give ORS solution"
      ],
      "prevention": [
        "Stay hydrated",
        "Avoid peak sun hours",
        "Wear light clothes",
        "Take breaks in shade"
      ],
      "emergency_numbers": ["112", "108", "102"],
      "voice_guide": "Move to shade. Drink water. Cool body. Call if no improvement."
    },
    {
      "type": "Hypothermia",
      "icon": "❄️",
      "severity": "high",
      "keywords": ["cold", "freezing", "shivering", "weather"],
      "situations": [
        "Extreme cold exposure",
        "Wet clothes in cold",
        "Mountain trekking",
        "Stranded in snow"
      ],
      "immediate_steps": [
        "Move to warm place",
        "Remove wet clothes",
        "Call emergency",
        "Cover with blankets"
      ],
      "first_aid": [
        "Warm slowly",
        "Give warm drinks",
        "Do not rub skin",
        "Monitor breathing"
      ],
      "prevention": [
        "Wear warm layers",
        "Stay dry",
        "Check weather",
        "Emergency supplies"
      ],
      "emergency_numbers": ["112", "108"],
      "voice_guide": "Get warm slowly. Remove wet clothes. Warm drinks help. Do not rub."
    },
    {
      "type": "Explosion Accident",
      "icon": "💥",
      "severity": "critical",
      "keywords": ["explosion", "blast", "bomb", "gas"],
      "situations": [
        "Gas cylinder blast",
        "Factory explosion",
        "Firecracker blast",
        "Bomb explosion"
      ],
      "immediate_steps": [
        "Move away from blast",
        "Call emergency",
        "Find safe cover",
        "Help others if safe"
      ],
      "first_aid": [
        "Treat burns",
        "Control bleeding",
        "Check for fractures",
        "Shock treatment"
      ],
      "prevention": [
        "Handle gas safely",
        "No fire near gas",
        "Regular cylinder check",
        "Safe storage"
      ],
      "emergency_numbers": ["112", "101", "102", "100"],
      "voice_guide": "Get far from explosion. Call emergency. Help with burns if safe."
    }
  ];

  static List<String> get categories => [
    "🚗 Transport",
    "❤️ Medical",
    "🔥 Fire",
    "⚡ Electrical",
    "🌊 Water",
    "🐍 Animal",
    "🧠 Brain",
    "🌡️ Weather",
    "💥 Explosion"
  ];

  static List<Map<String, dynamic>> getByCategory(String category) {
    switch(category) {
      case "🚗 Transport":
        return accidents.where((a) => a["type"].toString().contains("Road")).toList();
      case "❤️ Medical":
        return accidents.where((a) => a["type"].toString().contains("Heart")).toList();
      case "🔥 Fire":
        return accidents.where((a) => a["type"].toString().contains("Fire") || a["type"].toString().contains("Burn")).toList();
      case "⚡ Electrical":
        return accidents.where((a) => a["type"].toString().contains("Electric")).toList();
      case "🌊 Water":
        return accidents.where((a) => a["type"].toString().contains("Drown")).toList();
      case "🐍 Animal":
        return accidents.where((a) => a["type"].toString().contains("Snake") || a["type"].toString().contains("Dog")).toList();
      case "🧠 Brain":
        return accidents.where((a) => a["type"].toString().contains("Stroke")).toList();
      case "🌡️ Weather":
        return accidents.where((a) => a["type"].toString().contains("Heat") || a["type"].toString().contains("Hypo")).toList();
      case "💥 Explosion":
        return accidents.where((a) => a["type"].toString().contains("Explosion")).toList();
      default:
        return accidents;
    }
  }
}