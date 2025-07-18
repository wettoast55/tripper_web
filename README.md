# tripper_web

# Tripper: Group Travel Planning with AI

Tripper is a cross-platform group travel planning app built with Flutter, Firebase, and FastAPI. It helps groups collaboratively select trip destinations based on survey consensus, then uses AI and real-time flight deals to recommend optimized travel plans. Each user fills out a travel preferences survey, and Tripper intelligently recommends destinations that best match the group.

---

## 🌐 App Overview

### Purpose

To streamline group trip planning by combining:

* **Individual surveys** for travel preferences.
* **AI-generated destination recommendations** using GPT (via OpenRouter).
* **Live travel deals** from Amadeus APIs.
* **Group consensus detection** with dynamic filtering and survey conflict resolution.

---

## ⚖️ Technologies Used

### Frontend (Flutter)

* `flutter` (web and mobile)
* `cloud_firestore` for Firebase
* `shared_preferences` for user session
* `http` for backend API calls
* `intl` for formatting dates

### Backend (FastAPI)

* `fastapi` for building the API
* `httpx` for outbound API calls
* `firebase_admin` for Firestore admin access
* `apscheduler` for scheduled cleanups
* Integration with:

  * OpenRouter.ai (GPT-3.5)
  * Amadeus (live flight deals)

### Firebase

* Firestore database
* Collections:

  * `groups`
  * `surveys`
  * `users`

---

## ⚡ Key Features

### Surveys

Each user fills out a survey that includes:

* Budget: Budget, Medium, High
* Travel Month
* Activities
* Travel Methods (car, plane, etc.)
* Accommodation Preferences
* Preferred Destinations/Regions
* Interests
* Travel Date Range (start + end)

### Group Trip Recommendation

* Users in the same group submit surveys.
* When ready, the group can tap the FAB (Floating Action Button) to fetch group AI recommendations.
* The AI endpoint filters for consensus and shared preferences.
* Outlier responses are highlighted visually if there's no consensus.

### Live Flight Deals

* Tapping on a destination suggestion shows the cheapest flights (origin currently static, to be dynamic later).

---

## 📊 Data Model Overview

### Firestore Collections:

#### `users`

```json
{
  "userId": "abc123",
  "displayName": "Kevin",
  "email": "kevin@example.com"
}
```

#### `groups`

```json
{
  "groupId": "groupABC",
  "name": "Friends NYC Trip",
  "members": ["abc123", "def456"]
}
```

#### `surveys`

```json
{
  "userId": "abc123",
  "groupId": "groupABC",
  "budget": "Medium",
  "month": "June",
  "activities": ["hiking", "nightlife"],
  "travelMethods": ["plane"],
  "accommodations": ["hotel"],
  "destinations": ["Europe", "Asia"],
  "interests": ["culture", "food"],
  "startDate": Timestamp,
  "endDate": Timestamp,
  "completed": true,
  "timestamp": Timestamp,
  "userName": "Kevin"
}
```

---

## 📝 How to Use the App

1. **Join a Group**: User joins or is added to a group.
2. **Take the Survey**: Users input preferences (budget, dates, interests).
3. **Trigger AI Search**:

   * Go to the group page and tap the FAB.
   * If all users completed the survey, AI will suggest trips.
   * If not, a prompt will ask them to take the survey first.
4. **View Recommendations**: Three destination cards are shown with descriptions, attractions, and average prices.
5. **See Flight Deals**: Tap a destination to view real-time flight deals within the group’s consensus date range.

---

## 🤖 Local Setup Instructions

### Requirements

* Flutter SDK
* Firebase account + Firestore setup
* Python 3.11+
* Amadeus API credentials
* OpenRouter API key

### 1. Clone the Repo

```bash
git clone https://github.com/your-org/tripper.git
```

### 2. Set Up Backend (FastAPI)

```bash
cd tripper_web/lib/travel-ai-backend
pip install -r requirements.txt
uvicorn main:app --reload
```

> Replace the `OPENROUTER_API_KEY`, `AMADEUS_CLIENT_ID`, and `AMADEUS_CLIENT_SECRET` with your values.

### 3. Configure Firebase

* Add your `serviceAccountKey.json` to `travel-ai-backend/`
* Update Firebase project credentials in main.py

### 4. Start Flutter App

```bash
flutter run -d chrome
```

### 5. Configure Firestore Rules

Ensure your Firestore rules allow reading/writing to `users`, `groups`, `surveys` collections based on user auth.

---

## 🔹 To-Do / Upcoming Features

* [ ] Dynamic origin detection (based on geolocation or user profile)
* [ ] Highlight conflicting surveys (glow UI)
* [ ] Exclude certain surveys before AI search
* [ ] Invite friends to group via link/email

---

## 🚀 Demo Scripts

* **User A logs in** and joins group
* **User A takes the survey**
* **User B joins group and completes survey**
* **FAB triggers AI trip search**
* **Destinations appear**
* **Tapping destination reveals live flight deals**

---

## ⚖️ License

Custom internal license - Kevin Y. 2025

----------------------------------------------------

TripCliques RoadMap


July 2025   
            - Domain registration www.tripcliques.com
            - Skeleton Web App
            - Firebase/Email setup
                - using mailgun free account email servers to send "survey invites" max 100 a month
            - Live production
            - API links
            - REMOVED EMAIL INVITES... USING CODE GENERATION FOR EASE

TODO

            - UI revamp
            - Secure and robust
            - Customer Test
            - Web release
            - IOS/Android builds

Prompt the user to optionally exclude any group members’ surveys before searching.

Ensure all criteria (dates, interests, destinations, etc.) overlap.

Visually highlight outlier/conflicting answers if no consensus is found.

            - Home Page
                - Showcase/Trending Destinations
                - UI, invite code or discover input
            
            - Mygroup page
                - if in group
                    - show survey/invite status
                    - show "find trips button"
                    - update page based on if in group
                - if NOT in group
                    - show create group option
                        - generate group id/pin for sharing
                        - set creator as admin
                    - show join group option (pin)

                    -first time user on device creates username
                - UI
            
             - find trips page
                - toggle options, params given based off survey
                - big find buttod with params like number of people, cost, cost per person, dates, activities/vibe, ai will take and find in season best deals
                - show as list or on map with pins

            - saved trips/history, if in group is shared with others




