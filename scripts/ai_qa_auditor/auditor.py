"""AI QA Auditor - Gherkin-first CI/CD coverage gate.

Runs a two-stage LLM audit for a project:

1. Prompt 1 extracts business functionality and formats it strictly as
   Gherkin (Feature / Scenario / Given / When / Then).
2. Prompt 2 checks whether the existing test code covers each scenario.

Exit codes (the CI contract):
    0  -> audit passed; deployment may proceed.
    1  -> audit failed / malformed model output / provider error; block deploy.

Run locally:
    python scripts/ai_qa_auditor/auditor.py --project backend --threshold 80
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import collect
import prompts
from providers import LLMClient, ProviderError

EXIT_PASS = 0
EXIT_FAIL = 1


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AI QA Auditor (Gherkin gate)")
    parser.add_argument(
        "--project",
        required=True,
        choices=sorted(collect.PROJECTS.keys()),
        help="Project to audit.",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=80.0,
        help="Minimum scenario coverage percent required to pass (default: 80).",
    )
    parser.add_argument(
        "--repo-root",
        default=None,
        help="Repository root. Defaults to auto-detection walking up from CWD.",
    )
    parser.add_argument(
        "--output-dir",
        default="artifacts/ai-qa",
        help="Directory for requirements.feature and verdict.json.",
    )
    parser.add_argument(
        "--budget",
        type=int,
        default=120_000,
        help="Max characters per source/test blob (default: 120000).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Collect files and print stats without calling any LLM.",
    )
    return parser.parse_args(argv)


def detect_repo_root(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    env_root = os.environ.get("GITHUB_WORKSPACE")
    candidate = Path(env_root).resolve() if env_root else Path.cwd().resolve()
    for path in (candidate, *candidate.parents):
        if (path / ".github").exists() and (path / "backend").exists():
            return path
    return candidate


def _write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    repo_root = detect_repo_root(args.repo_root)
    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir

    print(f"[ai-qa] repository root : {repo_root}")
    print(f"[ai-qa] project         : {args.project}")
    print(f"[ai-qa] threshold       : {args.threshold}%")

    collected = collect.collect_project(args.project, repo_root, budget=args.budget)
    print(
        f"[ai-qa] collected {len(collected.source_files)} source files "
        f"({len(collected.source_blob)} chars) and "
        f"{len(collected.test_files)} test files "
        f"({len(collected.test_blob)} chars)."
    )

    if not collected.source_blob.strip():
        print("[ai-qa] ERROR: no source files found; cannot extract requirements.")
        return EXIT_FAIL

    if args.dry_run:
        print("[ai-qa] dry-run complete: no LLM call was made.")
        return EXIT_PASS

    try:
        client = LLMClient()
        print(f"[ai-qa] provider        : {client.provider} ({client.model})")

        # ----- Prompt 1: extract strict Gherkin requirements -----------------
        print("[ai-qa] Prompt 1: extracting Gherkin requirements...")
        gherkin_raw = client.chat(
            prompts.SYSTEM_PROMPT_1,
            prompts.build_extraction_prompt(args.project, collected.source_blob),
        )
        gherkin_ok, gherkin_errors, gherkin = prompts.validate_gherkin(gherkin_raw)
        _write(output_dir / "requirements.feature", gherkin or gherkin_raw)

        if not gherkin_ok:
            print("[ai-qa] FAIL: Prompt 1 output is not valid strict Gherkin:")
            for error in gherkin_errors:
                print(f"         - {error}")
            _write(
                output_dir / "verdict.json",
                json.dumps(
                    {
                        "status": "FAIL",
                        "stage": "gherkin_validation",
                        "errors": gherkin_errors,
                    },
                    indent=2,
                ),
            )
            return EXIT_FAIL

        scenario_count = gherkin.count("Scenario:")
        print(f"[ai-qa] extracted {scenario_count} Gherkin scenario(s).")

        # ----- Prompt 2: evaluate test coverage -----------------------------
        print("[ai-qa] Prompt 2: evaluating test coverage against Gherkin...")
        verdict_raw = client.chat(
            prompts.SYSTEM_PROMPT_2,
            prompts.build_validation_prompt(args.project, gherkin, collected.test_blob),
        )
        verdict = prompts.parse_verdict(verdict_raw)

    except (ProviderError, ValueError) as exc:
        print(f"[ai-qa] FAIL: {exc}")
        _write(
            output_dir / "verdict.json",
            json.dumps(
                {"status": "FAIL", "stage": "llm_or_parse", "error": str(exc)},
                indent=2,
            ),
        )
        return EXIT_FAIL
    except Exception as exc:  # pragma: no cover - defensive guard
        print(f"[ai-qa] FAIL: unexpected error: {exc}")
        _write(
            output_dir / "verdict.json",
            json.dumps(
                {"status": "FAIL", "stage": "unexpected", "error": str(exc)}, indent=2
            ),
        )
        return EXIT_FAIL

    # ----- Decide -----------------------------------------------------------
    percent = verdict["coverage_percent"]
    threshold_ok = percent >= args.threshold
    passed = verdict["verdict"] == "PASS" and threshold_ok

    verdict.update(
        {
            "status": "PASS" if passed else "FAIL",
            "project": args.project,
            "threshold": args.threshold,
            "threshold_ok": threshold_ok,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )
    _write(output_dir / "verdict.json", json.dumps(verdict, indent=2))
    _write(output_dir / "requirements.feature", gherkin)

    print(
        f"[ai-qa] coverage: {percent}% "
        f"({verdict['covered']}/{verdict['total']} scenarios), "
        f"threshold {args.threshold}%, model verdict {verdict['verdict']}."
    )
    if verdict["uncovered"]:
        print("[ai-qa] uncovered scenarios:")
        for name in verdict["uncovered"]:
            print(f"         - {name}")

    if passed:
        print("[ai-qa] PASS: deployment allowed (exit 0).")
        return EXIT_PASS

    print("[ai-qa] FAIL: deployment blocked (exit 1).")
    return EXIT_FAIL


def main(argv: list[str] | None = None) -> int:
    return run(parse_args(argv))


if __name__ == "__main__":
    sys.exit(main())
