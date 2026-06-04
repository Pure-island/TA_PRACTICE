# Project Agent Instructions

## Role

This is a Unity technical art practice project. The human is responsible for watching lessons, operating the Unity Editor, importing course assets, arranging scenes, and deciding learning pace.

The agent is responsible only for writing and maintaining project code when asked.

## Scope

- Write C#, shader, ShaderLab/HLSL, editor utility, and related code requested by the human.
- Do not create learning summaries, long study notes, route maps, design documents, or plans unless the human explicitly asks for them.
- Do not operate the Unity Editor through assumptions. If a task requires Editor-only steps, write the code and clearly state the exact Editor action the human must perform.
- Do not modify Unity-generated settings, render pipeline assets, scenes, prefabs, or imported assets unless the human explicitly asks.
- Preserve unrelated user changes in the worktree.

## Learning Code Style

- Code is for learning, so comments are required for important concepts, especially vector math, matrices, quaternions, coordinate spaces, shader passes, and render pipeline behavior.
- Write learning-code comments in Chinese unless the human explicitly asks for another language.
- Comments should explain why the code exists and what graphics/math concept it demonstrates.
- Avoid noisy line-by-line comments for obvious assignments or Unity lifecycle methods.
- Prefer small, focused scripts with clear Inspector fields so the human can tweak values in Unity.
- Use descriptive names that match course concepts, such as `DotProductVisualizer`, `MatrixTrsDemo`, or `QuaternionLookDemo`.
- When adding a chapter's learning code, also add a short Markdown explanation file in that chapter folder describing what each script demonstrates and how the human can attach it in Unity.

## Unity Project Conventions

- Keep learning code under `Assets/TA_Practice/` unless the human requests another location.
- Organize chapter code by course chapter and include the chapter title in the folder name when practical, for example `Assets/TA_Practice/Chapter03_ShaderLab编程入门/`.
- One course chapter should map to one main practice scene when practical.
- Runtime demo scripts should inherit from `MonoBehaviour` and expose teaching parameters with `[SerializeField]` where useful.
- Use `Debug.DrawRay`, `Gizmos`, and clear Console output for math visualization when appropriate.
- Keep code compatible with the current Unity version and URP setup.

## Shader Conventions

- Prefer URP-compatible shader code for this project.
- If course material uses Built-in Render Pipeline examples, adapt them to URP instead of copying them directly.
- Add comments for coordinate-space conversions and matrix multiplication order.
- Keep shader examples minimal and focused on the concept being taught.

## Image Generation For Learning Assets

- Use `image-gen` only when the human explicitly asks for generated images or when a requested shader/material demo needs simple placeholder learning textures.
- Generated textures for a chapter should live inside that chapter folder, usually under `Assets/TA_Practice/ChapterXX_章节标题/Textures/`.
- Prefer generating tileable texture maps for shader lessons, such as albedo, noise, mask, ramp, matcap, or simple normal-reference textures.
- After generating textures, update that chapter's Markdown explanation with the texture file paths, intended shader properties, and Unity import notes.
- For tileable material textures, tell the human to set `Wrap Mode` to `Repeat` in the Unity Editor.
- If generated images are used as transparent sprites or cutouts, prefer the image-gen chroma-key workflow and verify the final PNG has a clean alpha channel before using it as an asset.
- Do not treat generated images as proof that a shader is visually correct. Visual correctness still requires the human to check the material in the Unity Editor.
- Keep image prompts focused on learning assets, not production art direction, unless the human explicitly asks for production-quality art.

## Verification

- After editing code, run lightweight verification when available, such as checking file paths and obvious compile issues.
- If Unity compilation or scene setup must happen in the Editor, state that the human should open Unity and check the Console.
- Do not claim a Unity scene or shader is visually correct unless it has been verified in the Editor or by an explicit available render/test path.
