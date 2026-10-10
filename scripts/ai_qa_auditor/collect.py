"""Source and test collection for the AI QA Auditor.

Walks a project, separates *business source* from *existing tests*, andreturns
concatenated, size-bounded blobs suitable for LLM prompts. No business logic
is interpreted here; files are only read and truncated.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

# Directories that never contain auditable business or test code.
EXCLUDED_DIR_NAMES = {
    ".git",
    ".github",
    ".dart_tool",
    ".angular",
    "node_modules",
    "bin",
    "obj",
    "build",
    "dist",
    "coverage",
    ".vscode",
    ".fvm",
    "android",
    "ios",
    "windows",
    "linux",
    "macos",
    "web",
}


@dataclass(frozen=True)
class ProjectConfig:
    """Describes where a project keeps its source code and tests."""

    name: str
    source_globs: tuple[str, ...]
    test_globs: tuple[str, ...]
    source_root: str = "."
    test_markers: tuple[str, ...] = field(
        default=("test", "tests", "spec", "specs", "_test.", ".test.", ".spec.")
    )


PROJECTS: dict[str, ProjectConfig] = {
    "backend": ProjectConfig(
        name="backend",
        source_globs=(
            "NutriExercise.Core/**/*.cs",
            "NutriExercise.Api/**/*.cs",
            "NutriExercise.Infrastructure/**/*.cs",
        ),
        test_globs=(
            "NutriExercise.Tests/**/*.cs",
            "NutriExercise.Specs/**/*.cs",
            "NutriExercise.Specs/**/*.feature",
        ),
        source_root="backend",
    ),
    "web-portal": ProjectConfig(
        name="web-portal",
        source_globs=(
            "src/**/*.ts",
            "src/**/*.html",
        ),
        test_globs=(
            "src/**/*.spec.ts",
            "test/**/*.ts",
        ),
        source_root="web-portal",
    ),
    "mobile_app": ProjectConfig(
        name="mobile_app",
        source_globs=(
            "lib/**/*.dart",
        ),
        test_globs=(
            "test/**/*.dart",
            "integration_test/**/*.dart",
            "test/**/*.feature",
        ),
        source_root="mobile_app",
    ),
}


def _is_test_path(path: Path, project: ProjectConfig) -> bool:
    lowered = path.as_posix().lower()
    return any(marker in lowered for marker in project.test_markers)


def _is_excluded(path: Path, root: Path) -> bool:
    try:
        relative_parts = path.relative_to(root).parts
    except ValueError:
        return True
    return any(part in EXCLUDED_DIR_NAMES for part in relative_parts)


def _iter_files(root: Path, config: ProjectConfig) -> Iterable[Path]:
    base = (root / config.source_root).resolve()
    if not base.exists():
        return []
    seen: set[Path] = set()
    files: list[Path] = []
    for glob in (*config.source_globs, *config.test_globs):
        for path in base.glob(glob):
            if not path.is_file():
                continue
            if _is_excluded(path, base):
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            files.append(resolved)
    return sorted(files)


def _read(path: Path, remaining: int) -> str:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    if len(text) > remaining:
        text = text[:remaining] + "\n... [truncated]\n"
    return text


@dataclass
class CollectedProject:
    """The size-bounded source and test blobs for a single project."""

    name: str
    source_blob: str
    test_blob: str
    source_files: list[str]
    test_files: list[str]


def collect_project(
    project_name: str,
    repo_root: Path,
    budget: int = 120_000,
) -> CollectedProject:
    """Collect source and test code for ``project_name``.

    ``budget`` is the maximum number of characters allocated to each of the
    source and test blobs, keeping prompts within model context limits.
    """
    if project_name not in PROJECTS:
        raise KeyError(
            f"Unknown project '{project_name}'. Known: {', '.join(PROJECTS)}"
        )
    config = PROJECTS[project_name]

    source_chunks: list[str] = []
    test_chunks: list[str] = []
    source_files: list[str] = []
    test_files: list[str] = []

    source_remaining = budget
    test_remaining = budget

    for path in _iter_files(repo_root, config):
        relative = path.relative_to(repo_root).as_posix()
        is_test = _is_test_path(path, config)
        target_remaining = test_remaining if is_test else source_remaining
        if target_remaining <= 0:
            continue
        chunk = _read(path, target_remaining)
        if not chunk:
            continue
        header = f"\n===== FILE: {relative} =====\n"
        if is_test:
            test_chunks.append(header + chunk)
            test_files.append(relative)
            test_remaining -= len(chunk) + len(header)
        else:
            source_chunks.append(header + chunk)
            source_files.append(relative)
            source_remaining -= len(chunk) + len(header)

    return CollectedProject(
        name=project_name,
        source_blob="".join(source_chunks),
        test_blob="".join(test_chunks),
        source_files=source_files,
        test_files=test_files,
    )
