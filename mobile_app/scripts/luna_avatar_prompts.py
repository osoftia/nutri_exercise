#!/usr/bin/env python3
"""Print production prompts for Luna's male and female gym-blueprint avatars.

Luna generation is performed by the OpenCode image-generation capability. This
script keeps the prompts repeatable; pass the generated image output path to
Luna and save its result as `assets/images/luna_avatars/<variant>.png`.
"""

import argparse


BASE_PROMPT = """Create a premium cinematic 3D athletic human body render for a
fitness app's technical body-projection screen. Show one adult {variant} athlete
standing in a relaxed, neutral, symmetrical anatomical A-pose, full body from
head to feet, centered, facing directly toward camera. The physique is realistic
and attainable, anatomically accurate, with clearly defined but natural muscle
groups and realistic skin texture. Use dramatic rim lighting in electric cyan
and restrained violet against a very dark navy/black technical blueprint
background. Add fine cyan drafting grid lines, subtle measurement ticks and
faint engineering annotations only in the background; keep the subject clean,
unobstructed, non-sexualized, and free of clothing logos or text. Premium
photorealistic 3D production, cinematic volumetric lighting, crisp detail,
balanced contrast, polished 8K aesthetic, portrait composition, 2:3 aspect ratio.
The subject must remain entirely within frame with clear space around the
silhouette. Deliver a single still image, not a collage."""

NEGATIVE_PROMPT = """Avoid: cropped head or feet, extra limbs or fingers, malformed
hands, asymmetry, inaccurate anatomy, exaggerated bodybuilder proportions,
sexualized posing, nudity, transparent anatomy, labels over the person, text,
watermarks, logos, multiple people, busy background, low resolution, blur,
plastic skin, illustration, cartoon, flat vector art."""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "variant",
        choices=("male", "female", "both"),
        nargs="?",
        default="both",
        help="which anatomical presentation prompt(s) to print (default: both)",
    )
    args = parser.parse_args()

    variants = ("male", "female") if args.variant == "both" else (args.variant,)
    for variant in variants:
        print(f"=== {variant.upper()} AVATAR ===")
        print(BASE_PROMPT.format(variant=variant))
        print("\nNEGATIVE PROMPT")
        print(NEGATIVE_PROMPT)
        print("\nOUTPUT: assets/images/luna_avatars/" f"{variant}.png\n")


if __name__ == "__main__":
    main()
