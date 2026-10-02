# Luna avatar assets

Place the generated, approved portrait renders in this directory using these
exact filenames so Flutter's bundled asset paths match the routines switcher:

- `male.png`
- `female.png`

Generate prompts with `python scripts/luna_avatar_prompts.py both`, then use the
OpenCode Luna image-generation capability to produce each 2:3 photorealistic
render. Keep the subject full-body and centered. Images are not included yet:
the current execution environment does not expose an image-generation action.
Until the renders are added, the app keeps the blueprint visible and displays
an informative placeholder when the photorealistic option is selected.
