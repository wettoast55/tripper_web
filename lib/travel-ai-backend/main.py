
# # Import necessary modules
# from fastapi import FastAPI, Request
# from pydantic import BaseModel
# from openai import OpenAI
# import os

# # Initialize OpenAI client using API key from env or hardcoded (not recommended for prod)
# client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# # Initialize FastAPI app
# app = FastAPI()


# # Define request body schema
# class RecommendationRequest(BaseModel):
#     activities: list[str]
#     budget: str
#     month: str


# # Define POST endpoint to get travel recommendations using OpenAI
# @app.post("/recommendations")
# async def get_recommendations(req: RecommendationRequest):

#     # Build the prompt based on input parameters
#     user_prompt = (
#         f"Suggest 3 travel destinations for someone with a {req.budget} budget "
#         f"interested in the following activities: {', '.join(req.activities)}. "
#         f"The trip should be in the month of {req.month}. "
#         f"For each destination, include a name, brief description, estimated flight price, and top attraction."
#     )

#     # Build the messages for OpenAI Chat API
#     messages = [
#         {
#             "role": "system",
#             "content": "You are a helpful travel assistant that suggests personalized vacation destinations."
#         },
#         {
#             "role": "user",
#             "content": user_prompt
#         }
#     ]

#     # Call the ChatGPT API to generate a response
#     try:
#         completion = client.chat.completions.create(
#             model="gpt-3.5-turbo",  # Use "gpt-4-turbo" if your key has access
#             messages=messages,
#             temperature=0.7
#         )

#         # Extract the content from the response
#         result = completion.choices[0].message.content

#         # Return the response wrapped in a dict
#         return {"recommendations": result}

#     # Catch OpenAI model access errors
#     except Exception as e:
#         return {"error": str(e)}


# # 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
# using openrouter instead of open ai above


#---------------------------------------------

# cleanup groups with no users
from apscheduler.schedulers.background import BackgroundScheduler
from firebase_admin import firestore
import firebase_admin

# Import required modules
from fastapi import FastAPI
from pydantic import BaseModel
import httpx

# Initialize FastAPI app
app = FastAPI()

# Set your OpenRouter API key here (never commit this in production)
OPENROUTER_API_KEY = "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"

# Define headers required by OpenRouter
headers = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://localhost:8000",  # required by OpenRouter
    "X-Title": "TripCliques Travel AI"        # optional, for dashboard tracking
}

#---------- FOR AUTO GROUPS CLEANUP EVERY 12 HRS
# Initialize Firebase Admin
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()
scheduler = BackgroundScheduler()

def delete_empty_groups():
    groups = db.collection('groups').stream()
    for group in groups:
        group_id = group.id
        members = db.collection('groups').document(group_id).collection('members').get()
        if not members:
            print(f"Deleting empty group: {group_id}")
            db.collection('groups').document(group_id).delete()

# Schedule every 12 hours (adjust as needed)
scheduler.add_job(delete_empty_groups, 'interval', hours=12)
scheduler.start()
#_----------------------------

# Define the request body schema using Pydantic
class RecommendationRequest(BaseModel):
    activities: list[str]
    budget: str
    month: str


# Define the POST endpoint for travel recommendations
@app.post("/recommendations")
async def get_recommendations(req: RecommendationRequest):

    # Build a natural language prompt based on user's travel preferences
    user_prompt = (
        f"Suggest 3 travel destinations for someone with a {req.budget} budget "
        f"interested in: {', '.join(req.activities)}. Month: {req.month}. "
        f"Include a name, brief description, flight price, and top attraction."
    )

    # Define the full payload expected by OpenRouter's chat completions API
    data = {
        "model": "openai/gpt-3.5-turbo",  # you can try others like "mistral", "claude", etc.
        "messages": [
            {"role": "system", "content": "You are a helpful travel assistant."},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.7
    }

    # Send the request to OpenRouter and await the response
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                json=data
            )

        # Raise exception if OpenRouter returns error status
        response.raise_for_status()

        # Extract the content string from the GPT response
        result = response.json()["choices"][0]["message"]["content"]

        # Return the recommendation text to the client
        return {"recommendations": result}

    # Handle any unexpected exceptions and return as error JSON
    except Exception as e:
        return {"error": str(e)}
