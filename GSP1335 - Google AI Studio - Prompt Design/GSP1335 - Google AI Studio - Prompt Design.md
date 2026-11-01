# Google AI Studio: Prompt Design

**Lab Code**: `GSP1335`  
**Difficulty**: Introductory  
**Time Limit**: 45 minutes  
**Interface**: [Google AI Studio](https://aistudio.google.com/) (Web UI)  

---

## Overview

In this lab, you explore prompt engineering fundamentals and best practices using **Google AI Studio** with the Gemini family of models:
1. **Task 1**: Create a zero-shot prompt and save it to Google Drive as `Rugged Space Freighter Names`.
2. **Task 2**: Add system instructions (persona definition) and one-shot examples for structured output.
3. **Task 3**: Switch Gemini models and adjust temperature settings (`0.1` and `1.8`).
4. **Task 4**: Experiment with model tools (**Structured output** for JSON and **Grounding with Google Search**).
5. **Task 5**: Review saved prompts from the Google AI Studio History.

---

## Step-by-Step Walkthrough

### Initial Setup: Sign in to Google AI Studio
1. Open an **Incognito / Private** browser window.
2. Navigate to [Google AI Studio](https://aistudio.google.com/) and click **Get Started**.
3. Sign in using the temporary student credentials provided in your lab access panel (`student-XX-YYYY@qwiklabs.net`).
4. Accept all terms and conditions to enter the studio.

---

### Task 1: Create a basic prompt
1. In the left navigation menu, click **Playground** (or **Create new prompt**).
2. In the prompt field at the bottom, enter:
   ```text
   Suggest 5 names for a rugged space freighter.
   ```
3. Click the **Run** button (arrow icon next to the prompt).
4. When prompted with **Save your conversations in Google Drive (Recommended)**:
   - Click **Enable Google Drive**.
   - Select your active student account and click **Allow** / **Continue**.
5. Click the **Pencil icon** (or **Save** at the top right) to name the prompt:
   - Name: `Rugged Space Freighter Names`
   - Click **Save**.
6. Return to the lab page and click **Check my progress** for **Task 1**.

---

### Task 2: Add context and structure to prompts
1. Click **Playground** to open a fresh chat session.
2. Click the **System instructions** icon (clipboard icon).
3. In the System instructions box, enter:
   ```text
   You are a science fiction author known for hard sci-fi and gritty, realistic world-building.
   ```
4. In the main prompt box, enter:
   ```text
   Write a one-paragraph ship description for a long-haul mining vessel named 'The Odyssey'.
   ```
5. Click **Run** and review the styled output.
6. Now replace the prompt with a **one-shot example**:
   ```text
   You are a science fiction author. Create a ship description. **Example:** Name: The Serenity Class: Firefly Description: A small, versatile transport ship, old but reliable, with many hidden compartments. **My Request:** Name: The Odyssey Class: Long-Haul Miner Description:
   ```
7. Click **Run**.
8. Return to the lab page and click **Check my progress** for **Task 2**.

---

### Task 3: Explore Gemini models and adjust temperature
1. Open a new chat session by clicking **Playground**.
2. Enter the prompt:
   ```text
   Suggest an exciting event that could happen aboard a spaceship.
   ```
3. In the **Run settings** panel on the right:
   - Adjust the **Temperature** slider down to `0.1`.
   - Click **Run** and review the deterministic output.
4. Next, slide the **Temperature** slider up to `1.8`.
5. Click **Run** again and notice the increased creative variation.
6. Return to the lab page and click **Check my progress** for **Task 3**.

---

### Task 4: Experiment with tools to adjust the model's output
#### Sub-step A: Structured JSON Output
1. Open a new chat session.
2. In the prompt field, enter:
   ```text
   Generate a list of three planets in the Tau Ceti system, including their name, type, and a fictional key resource. Provide the output in JSON format.
   ```
3. In the right panel under **Tools**, toggle **Structured output** to **ON**.
4. Click **Run** and observe the cleanly formatted JSON output.

#### Sub-step B: Grounding with Google Search
1. Open a new chat session.
2. In the right panel under **Tools**, toggle **Structured output** to **OFF** and toggle **Grounding with Google Search** to **ON**.
3. In the prompt field, enter:
   ```text
   Using Google Search, what is the latest news about the James Webb Space Telescope? Then, write a short, inspirational journal entry from an astronomer working on the project.
   ```
4. Click **Run** and observe the cited, grounded search results.
5. Return to the lab page and click **Check my progress** for **Task 4**.

---

### Task 5: View the saved prompt in history
1. In the left navigation menu, click **History**.
2. In the list of saved sessions, click **Rugged Space Freighter Names**.
3. The conversation will load from your connected Google Drive storage.
4. Return to the lab page and click **Check my progress** (if applicable) or finish the lab for **100/100**.
