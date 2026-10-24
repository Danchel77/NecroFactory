#!/usr/bin/env python3
"""
tools/generate_3d.py - 3D model generator using free Hugging Face Spaces (Image-to-3D).
Supports TRELLIS (high quality) and Stable Fast 3D (fast fallback).
"""

import sys
import os
import shutil
from pathlib import Path

# Clean up NO_PROXY if it contains invalid IPv6 brackets for httpx
for key in ["NO_PROXY", "no_proxy"]:
    if key in os.environ and "[::1]" in os.environ[key]:
        os.environ[key] = "localhost,127.0.0.1"

from dotenv import load_dotenv
load_dotenv()

from gradio_client import Client, handle_file

DEFAULT_PRIMARY_SPACE = "trellis-community/TRELLIS"
DEFAULT_FALLBACK_SPACE = "stabilityai/stable-fast-3d"

def generate_with_trellis(image_path: str, output_glb_path: str, token: str) -> bool:
    print(f"[*] Trying primary engine: {DEFAULT_PRIMARY_SPACE}...")
    try:
        client = Client(DEFAULT_PRIMARY_SPACE, token=token)
        result = client.predict(
            image=handle_file(image_path),
            multiimages=[],
            seed=0,
            ss_guidance_strength=7.5,
            ss_sampling_steps=12,
            slat_guidance_strength=3.0,
            slat_sampling_steps=12,
            multiimage_algo="stochastic",
            mesh_simplify=0.95,
            texture_size=1024,
            api_name="/generate_and_extract_glb"
        )
        # result: (generated_3d_asset_video, extracted_glbgaussian, download_glb)
        download_glb = result[2] if len(result) > 2 else result[1]
        if download_glb and os.path.exists(download_glb):
            os.makedirs(os.path.dirname(os.path.abspath(output_glb_path)), exist_ok=True)
            shutil.copy2(download_glb, output_glb_path)
            print(f"[+] Successfully generated with TRELLIS: {output_glb_path}")
            return True
        else:
            print(f"[-] TRELLIS returned invalid result: {result}")
            return False
    except Exception as e:
        print(f"[-] TRELLIS failed: {e}")
        return False

def generate_with_sf3d(image_path: str, output_glb_path: str, token: str) -> bool:
    print(f"[*] Trying fallback engine: {DEFAULT_FALLBACK_SPACE}...")
    try:
        client = Client(DEFAULT_FALLBACK_SPACE, token=token)
        result = client.predict(
            input_image=handle_file(image_path),
            foreground_ratio=0.85,
            remesh_option="None",
            vertex_count=-1,
            texture_size=1024,
            api_name="/run_button"
        )
        # result: (preview_background_removal, 3d_model_path)
        glb_path = result[1] if isinstance(result, (list, tuple)) else result
        if glb_path and os.path.exists(glb_path):
            os.makedirs(os.path.dirname(os.path.abspath(output_glb_path)), exist_ok=True)
            shutil.copy2(glb_path, output_glb_path)
            print(f"[+] Successfully generated with Stable Fast 3D: {output_glb_path}")
            return True
        else:
            print(f"[-] Stable Fast 3D returned invalid result: {result}")
            return False
    except Exception as e:
        print(f"[-] Stable Fast 3D failed: {e}")
        return False

def main():
    if len(sys.argv) < 3:
        print("Usage: python tools/generate_3d.py <input_image_path> <output_glb_path>")
        sys.exit(1)

    input_img = sys.argv[1]
    output_glb = sys.argv[2]

    if not os.path.exists(input_img):
        print(f"Error: input image not found: {input_img}")
        sys.exit(1)

    token = os.getenv("HF_TOKEN")
    if not token:
        print("Warning: HF_TOKEN not found in environment or .env. Requests may be rate-limited.")

    # Try TRELLIS first, then SF3D
    success = generate_with_trellis(input_img, output_glb, token)
    if not success:
        print("[!] Switching to fallback...")
        success = generate_with_sf3d(input_img, output_glb, token)

    if success:
        print(f"[SUCCESS] GLB model ready at: {output_glb}")
        sys.exit(0)
    else:
        print("[ERROR] All 3D generation engines failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
