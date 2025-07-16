from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

app = FastAPI()

class RecommendationRequest(BaseModel):
    activities: List[str]
    budget: str
    month: str

@app.post("/recommendations")
async def get_recommendations(request: RecommendationRequest):
    # For now, we will use mock destinations
    mock_destinations = [
        {
            "name": "Bali, Indonesia",
            "avg_flight": "$600",
            "hotels": "$80–$120/night",
            "best_months": "April–June",
            "activities": ["Beach", "Food Tour", "Hiking"],
        },
        {
            "name": "Lisbon, Portugal",
            "avg_flight": "$700",
            "hotels": "$100–$150/night",
            "best_months": "May–September",
            "activities": ["Museum", "Food Tour", "Beach"],
        },
        {
            "name": "Kyoto, Japan",
            "avg_flight": "$900",
            "hotels": "$120–$200/night",
            "best_months": "March–April",
            "activities": ["Museum", "Food Tour"],
        },
    ]

    # Prepare prompt for GPT
    prompt = f"""
You are a travel assistant helping a group plan their trip.

Group Preferences:
- Preferred activities: {", ".join(request.activities)}
- Budget: {request.budget}
- Preferred month: {request.month}

Below are some possible destinations:

{mock_destinations}

Please recommend the top 3 destinations, and for each, provide:
- Name
- Estimated flight price
- Hotel price range
- Best months to visit
- A short description explaining why it matches the group's preferences.

Respond in JSON array format.
Each item should be:
{{
  "name": "...",
  "flight": "...",
  "hotels": "...",
  "season": "...",
  "description": "..."
}}
"""

    completion = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a helpful travel advisor."},
            {"role": "user", "content": prompt},
        ],
        temperature=0.3,
    )

    # Extract GPT response
    response_text = completion.choices[0].message.content.strip()

    # Return raw GPT text (you can json.loads it if you prefer strict JSON)
    return {"recommendations": response_text}
