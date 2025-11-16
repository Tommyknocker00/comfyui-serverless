import runpod
import json
import urllib.request
import urllib.parse
import time
import base64
import os
import random

# ComfyUI server URL (local binnen container)
COMFY_URL = "http://127.0.0.1:8188"

def queue_prompt(prompt):
    """Stuur workflow naar ComfyUI queue"""
    data = json.dumps({"prompt": prompt}).encode('utf-8')
    req = urllib.request.Request(f"{COMFY_URL}/prompt", data=data, headers={'Content-Type': 'application/json'})
    response = urllib.request.urlopen(req)
    return json.loads(response.read())

def get_image(filename, subfolder, folder_type):
    """Haal gegenereerde image op van ComfyUI"""
    params = urllib.parse.urlencode({"filename": filename, "subfolder": subfolder, "type": folder_type})
    url = f"{COMFY_URL}/view?{params}"
    with urllib.request.urlopen(url) as response:
        return response.read()

def get_history(prompt_id):
    """Check of workflow klaar is"""
    with urllib.request.urlopen(f"{COMFY_URL}/history/{prompt_id}") as response:
        return json.loads(response.read())

def wait_for_completion(prompt_id, timeout=300):
    """Wacht tot image klaar is (max 5 min)"""
    start_time = time.time()
    while True:
        if time.time() - start_time > timeout:
            raise TimeoutError("Image generation timeout na 5 minuten")
        
        history = get_history(prompt_id)
        if prompt_id in history:
            outputs = history[prompt_id].get('outputs', {})
            # Zoek SaveImage node output (node 8)
            for node_id in outputs:
                node_output = outputs[node_id]
                if 'images' in node_output:
                    return node_output['images'][0]
        
        time.time()
        time.sleep(1)

def handler(job):
    """Main handler voor RunPod serverless"""
    job_input = job['input']
    
    # Validatie
    if 'prompt' not in job_input:
        return {"error": "Missing 'prompt' in request"}
    
    user_prompt = job_input['prompt']
    
    # Laad workflow template
    with open('/workspace/workflow_api.json', 'r') as f:
        workflow = json.load(f)
    
    # Inject user prompt + voeg Pony quality tags toe
    full_prompt = f"score_9, score_8_up, {user_prompt}"
    workflow["2"]["inputs"]["text"] = full_prompt
    
    # Random seed voor variatie
    workflow["5"]["inputs"]["seed"] = random.randint(0, 0xffffffffffffffff)
    
    print(f"Generating image met prompt: {full_prompt}")
    
    # Stuur naar ComfyUI
    response = queue_prompt(workflow)
    prompt_id = response['prompt_id']
    
    print(f"Queued met ID: {prompt_id}")
    
    # Wacht op completion
    image_info = wait_for_completion(prompt_id)
    
    # Download image
    image_data = get_image(
        image_info['filename'],
        image_info['subfolder'],
        image_info['type']
    )
    
    # Convert naar base64
    image_base64 = base64.b64encode(image_data).decode('utf-8')
    
    return {
        "image": image_base64,
        "prompt": full_prompt,
        "seed": workflow["5"]["inputs"]["seed"],
        "filename": image_info['filename']
    }

# Start RunPod handler
runpod.serverless.start({"handler": handler})
