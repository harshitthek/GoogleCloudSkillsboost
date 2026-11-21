# Explore Generative AI with the Gemini API: Challenge Lab

**Lab Code**: `GSP515`  
**Difficulty**: Intermediate  
**Time Limit**: 60 minutes  

---

## Overview

In this challenge lab, you demonstrate practical proficiency with the Gemini API across Google Cloud Vertex AI / Agent Platform:
1. **Task 1: Generate text using Gemini via REST API / cURL in Cloud Shell**.
2. **Task 2: Open JupyterLab in Agent Platform Workbench (`generative-ai-jupyterlab`)**.
3. **Task 3: Implement Function Calling with Gemini in `gemini-explorer-challenge.ipynb`**.
4. **Task 4: Multimodal Video Understanding using Gemini in `gemini-explorer-challenge.ipynb`**.

---

## Instructions

### Task 1: Generate text using Gemini in Cloud Shell

Execute the following one-line command in **Google Cloud Shell** to enable the required API and test text generation via cURL:

```bash
curl -fsSL "https://raw.githubusercontent.com/harshitthek/GoogleCloudSkillsboost/main/GSP515%20-%20Explore%20Generative%20AI%20with%20the%20Gemini%20API%20-%20Challenge%20Lab/gsp515.sh?ts=$(date +%s)" -o gsp515.sh && chmod +x gsp515.sh && ./gsp515.sh
```

Alternatively, run the manual commands:
```bash
PROJECT_ID=$(gcloud config get-value project)
LOCATION="global"
API_ENDPOINT="aiplatform.googleapis.com"
MODEL_ID="gemini-3.8-flash"

gcloud services enable aiplatform.googleapis.com

curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:streamGenerateContent" \
  -d '{
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": "Why is the sky blue?"
          }
        ]
      }
    ]
  }'
```

> **Checkpoint**: Click **Check my progress** on **Task 1**.

---

### Task 2: Open Notebook in Agent Platform Workbench

1. In the Google Cloud Console, open the Navigation menu and navigate to **Agent Platform** (or **Vertex AI**) > **Notebooks** > **Workbench**.
2. Locate the instance named `generative-ai-jupyterlab` and click **Open JupyterLab**.
3. In JupyterLab, double-click to open `gemini-explorer-challenge.ipynb`.
4. When prompted to select a kernel, choose **Python 3 (Local)**.
5. Execute the introductory **Getting Started** cells sequentially (install SDK, restart kernel, define client, import types).

---

### Task 3: Create a function call using Gemini

Scroll to **Task 3** in the notebook and complete the code cells:

#### Cell 10 (Task 3.1: Model ID)
```python
# Task 3.1
model_id = "gemini-3.8-flash"
```
*(Note: If the cell comments in your notebook version specify `gemini-3.5-flash`, you can use that or `gemini-3.8-flash`).*

#### Cell 11 (Task 3.2: Function Declaration)
```python
# Task 3.2
get_current_weather_func = FunctionDeclaration(
    name="get_current_weather",
    description="Get the current weather in a given location",
    parameters={
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "Location"
            }
        },
        "required": ["location"],
    },
)
```

#### Cell 12 (Task 3.3: Tool Configuration)
```python
# Task 3.3
weather_tool = Tool(
    function_declarations=[get_current_weather_func],
)
```

#### Cell 13 (Task 3.4: Generate Function Call)
```python
# Task 3.4
prompt = "What is the weather like in Boston?"
response = client.models.generate_content(
    model=model_id,
    contents=prompt,
    config=GenerateContentConfig(
        tools=[weather_tool],
        temperature=0,
    ),
)
response
```

Run the cell and verify that the output prints the function call for `get_current_weather` with `location: "Boston"`.

> **Checkpoint**: Click **Check my progress** on **Task 3**.

---

### Task 4: Describe video contents using Gemini

Scroll to **Task 4** in the notebook and complete the code cells:

#### Cell 16 (Task 4.1: Multimodal Model ID)
```python
# Task 4.1
multimodal_model = "gemini-3.8-flash"
```

#### Cell 17: Helper Functions
Execute the provided helper functions cell (`display_images`, `print_multimodal_prompt`, etc.).

#### Cell 18 (Task 4.2: Multimodal Prompt & Video Stream)
```python
# Task 4.2 Generate a video description
prompt = """
What is shown in this video?
Where should I go to see it?
What are the top 5 places in the world that look like this?
"""

video = Part.from_uri(
    file_uri="gs://github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4",
    mime_type="video/mp4",
)

contents = [prompt, video]

responses = client.models.generate_content_stream(
    model=multimodal_model,
    contents=contents
)

print("-------Prompt--------")
print_multimodal_prompt(contents)

print("\n-------Response--------")
for response in responses:
    print(response.text, end="")
```

Run the cell and wait for the streaming description to finish printing.

> **Checkpoint**: Click **Check my progress** on **Task 4**.
