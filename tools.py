"""
MediGuide AI - Tools for Agentic Loop
=====================================
Meta + Hugging Face Hackathon 2026

Mock tool functions for Llama 3.2 tool-calling agent.
These simulate real medical resource lookups.
"""

from typing import Dict, List, Any, Optional
import random


# ============================================================
# MOCK MEDICAL RESOURCES DATABASE
# ============================================================
INDIA_PHC_DATABASE = {
    "maharashtra": [
        {
            "name": "PHC Pachora",
            "type": "Primary Health Centre",
            "phone": "02596-234567",
            "services": ["Emergency", "Pediatrics", "General"],
        },
        {
            "name": "PHC Jalgaon",
            "type": "Primary Health Centre",
            "phone": "02593-222222",
            "services": ["Emergency", "Surgery", "General"],
        },
        {
            "name": "PHC Nagpur Rural",
            "type": "Primary Health Centre",
            "phone": "0712-234567",
            "services": ["Emergency", "Maternity", "General"],
        },
    ],
    "delhi": [
        {
            "name": "PHC Najafgarh",
            "type": "Primary Health Centre",
            "phone": "011-23456789",
            "services": ["Emergency", "General", "Dental"],
        },
        {
            "name": "PHC Sarita Vihar",
            "type": "Primary Health Centre",
            "phone": "011-29876543",
            "services": ["Emergency", "Pediatrics", "General"],
        },
    ],
    "karnataka": [
        {
            "name": "PHC Mysore Rural",
            "type": "Primary Health Centre",
            "phone": "0821-234567",
            "services": ["Emergency", "General", "Ortho"],
        },
        {
            "name": "PHC Bangalore Rural",
            "type": "Primary Health Centre",
            "phone": "080-23456789",
            "services": ["Emergency", "Surgery", "General"],
        },
    ],
    "tamil_nadu": [
        {
            "name": "PHC Chennai Rural",
            "type": "Primary Health Centre",
            "phone": "044-23456789",
            "services": ["Emergency", "General", "Cardio"],
        },
        {
            "name": "PHC Coimbatore",
            "type": "Primary Health Centre",
            "phone": "0422-234567",
            "services": ["Emergency", "Pediatrics", "General"],
        },
    ],
    "uttar_pradesh": [
        {
            "name": "PHC Lucknow Rural",
            "type": "Primary Health Centre",
            "phone": "0522-2345678",
            "services": ["Emergency", "General", "Maternity"],
        },
        {
            "name": "PHC Varanasi",
            "type": "Primary Health Centre",
            "phone": "0542-234567",
            "services": ["Emergency", "General", "Digestive"],
        },
    ],
    "default": [
        {
            "name": "PHC District Hospital",
            "type": "Primary Health Centre",
            "phone": "108",
            "services": ["Emergency", "All Services"],
        },
    ],
}

SPECIALIST_CLINICS = {
    "skin": ["Dermatologist", "Skin Specialist"],
    "heart": ["Cardiologist", "Cardiac Center"],
    "bone": ["Orthopedic", "Joint Specialist"],
    "child": ["Pediatrician", "Child Specialist"],
    "eye": ["Ophthalmologist", "Eye Specialist"],
    "digestive": ["Gastroenterologist", "Digestive Specialist"],
}


# ============================================================
# TOOL FUNCTIONS
# ============================================================
def search_medical_resources(query: str, location: str = "default") -> Dict[str, Any]:
    """
    Mock function to search for nearby medical resources in India.

    Args:
        query: Medical specialty or service type (e.g., "cardiac", "skin", "emergency")
        location: State/region in India (e.g., "maharashtra", "delhi", "karnataka")

    Returns:
        Dict with search results and recommendations
    """
    location_lower = location.lower().replace(" ", "_")

    # Get resources for location
    resources = INDIA_PHC_DATABASE.get(location_lower, INDIA_PHC_DATABASE["default"])

    # Filter by query
    query_lower = query.lower()
    matched = []
    for resource in resources:
        for service in resource["services"]:
            if (
                query_lower in service.lower()
                or query_lower in resource["name"].lower()
            ):
                matched.append(resource)
                break

    if not matched:
        matched = resources[:2]  # Return defaults

    return {
        "query": query,
        "location": location,
        "results": matched,
        "count": len(matched),
        "recommendation": f"Visit {matched[0]['name']} for {query} services"
        if matched
        else "Call 108 for emergency",
    }


def search_specialist_clinics(specialty: str, city: str = "") -> Dict[str, Any]:
    """
    Search for specialist clinics based on medical specialty.

    Args:
        specialty: Medical specialty (skin, heart, bone, child, eye, digestive)
        city: City name (optional)

    Returns:
        Dict with specialist recommendations
    """
    specialists = SPECIALIST_CLINICS.get(specialty.lower(), ["General Physician"])

    return {
        "specialty": specialty,
        "specialist_types": specialists,
        "city": city,
        "advice": f"Consult a {specialists[0]} for {specialty} conditions",
        "emergency_if": "If severe, call 108 immediately",
    }


def get_emergency_contacts(state: str = "") -> Dict[str, Any]:
    """
    Get emergency contact numbers for a specific state/region.

    Args:
        state: Indian state name

    Returns:
        Dict with emergency numbers
    """
    base_numbers = {
        "ambulance": "108",
        "police": "100",
        "fire": "101",
        "national_emergency": "112",
        "poison_control": "1066",
    }

    state_numbers = {
        "maharashtra": {"ambulance": "102", "medical_emergency": "108"},
        "delhi": {"ambulance": "102", "medical_emergency": "103"},
        "karnataka": {"ambulance": "102", "medical_emergency": "108"},
    }

    numbers = state_numbers.get(state.lower().replace(" ", "_"), {})
    numbers.update(base_numbers)

    return {
        "state": state if state else "All India",
        "emergency_numbers": numbers,
        "note": "Dial 108 for life-threatening emergencies",
    }


def calculate_distance_estimation(
    from_location: str, to_facility: str
) -> Dict[str, Any]:
    """
    Mock function to estimate travel distance/time to a medical facility.

    Args:
        from_location: Starting location
        to_facility: Destination facility name

    Returns:
        Dict with distance and time estimates
    """
    # Mock estimates
    distances = ["2 km", "5 km", "10 km", "15 km", "25 km"]
    times = ["10 mins", "20 mins", "30 mins", "45 mins", "1 hour"]

    return {
        "from": from_location,
        "to": to_facility,
        "estimated_distance": random.choice(distances),
        "estimated_time": random.choice(times),
        "transport_options": ["Auto", "Ambulance", "Private Vehicle"],
        "note": "Call 108 for ambulance in emergencies",
    }


# ============================================================
# TOOL REGISTRY (for Llama tool-calling)
# ============================================================
TOOL_REGISTRY = {
    "search_medical_resources": {
        "name": "search_medical_resources",
        "description": "Search for Primary Health Centres (PHCs) and medical facilities in India by location and service type.",
        "parameters": {
            "query": {
                "type": "string",
                "description": "Medical service or specialty to search for",
            },
            "location": {
                "type": "string",
                "description": "State or region in India (e.g., maharashtra, delhi)",
            },
        },
    },
    "search_specialist_clinics": {
        "name": "search_specialist_clinics",
        "description": "Find specialist doctors and clinics based on medical specialty.",
        "parameters": {
            "specialty": {
                "type": "string",
                "description": "Medical specialty (skin, heart, bone, child, eye, digestive)",
            },
            "city": {"type": "string", "description": "City name (optional)"},
        },
    },
    "get_emergency_contacts": {
        "name": "get_emergency_contacts",
        "description": "Get emergency contact numbers for Indian states.",
        "parameters": {
            "state": {"type": "string", "description": "Indian state name (optional)"}
        },
    },
}


# ============================================================
# TOOL CALL HANDLER
# ============================================================
def execute_tool(tool_name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute a tool based on name and parameters.

    Args:
        tool_name: Name of the tool to execute
        parameters: Parameters for the tool

    Returns:
        Tool execution result
    """
    tool_functions = {
        "search_medical_resources": search_medical_resources,
        "search_specialist_clinics": search_specialist_clinics,
        "get_emergency_contacts": get_emergency_contacts,
    }

    if tool_name in tool_functions:
        return tool_functions[tool_name](**parameters)
    else:
        return {"error": f"Unknown tool: {tool_name}"}
