"""LLM provider adapters for the AI QA Auditor.

Only the Python standard library is used so the CI gate has no install
friction. Supported providers (selected via ``LLM_PROVIDER``):

* ``github``  - GitHub Models (OpenAI-compatible), auth via ``GITHUB_TOKEN``
* ``openai``  - OpenAI chat completions
* ``gemini``  - Google Gemini ``generateContent``
* ``ollama``  - Local Ollama ``/api/chat`` (no API key required)

The client normalises every provider to a single ``chat(system, user) -> str``
call. Any transport/parsing failure raises :class:`ProviderError`, which the
auditor turns into a non-zero exit so deployments are blocked on uncertainty.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from typing import Any


class ProviderError(RuntimeError):
    """Raised when the configured LLM provider cannot return a completion."""


DEFAULT_GITHUB_MODEL = "openai/gpt-4o-mini"
DEFAULT_OPENAI_MODEL = "gpt-4o-mini"
DEFAULT_GEMINI_MODEL = "gemini-1.5-flash"
DEFAULT_OLLAMA_MODEL = "llama3.1"
DEFAULT_OLLAMA_BASE_URL = "http://localhost:11434"

GITHUB_MODELS_URL = "https://models.github.ai/inference/chat/completions"

_DEFAULT_MODELS = {
    "github": DEFAULT_GITHUB_MODEL,
    "openai": DEFAULT_OPENAI_MODEL,
    "gemini": DEFAULT_GEMINI_MODEL,
    "ollama": DEFAULT_OLLAMA_MODEL,
}

_SUPPORTED_PROVIDERS = ("github", "openai", "gemini", "ollama")


class LLMClient:
    """Provider-agnostic chat client configured entirely from the environment."""

    def __init__(
        self,
        provider: str | None = None,
        api_key: str | None = None,
        model: str | None = None,
        base_url: str | None = None,
        timeout: int = 120,
    ) -> None:
        self.provider = (provider or os.getenv("LLM_PROVIDER") or "github").strip().lower()
        self.api_key = (
            api_key or os.getenv("LLM_API_KEY") or os.getenv("GITHUB_TOKEN") or ""
        ).strip()
        self.model = (model or os.getenv("LLM_MODEL") or "").strip()
        self.base_url = (base_url or os.getenv("LLM_BASE_URL") or "").strip().rstrip("/")
        self.timeout = timeout

        if not self.model:
            self.model = _DEFAULT_MODELS.get(self.provider, DEFAULT_GITHUB_MODEL)

        if self.provider not in _SUPPORTED_PROVIDERS:
            raise ProviderError(
                f"Unsupported LLM_PROVIDER '{self.provider}'. "
                f"Expected one of: {', '.join(_SUPPORTED_PROVIDERS)}."
            )

        if self.provider != "ollama" and not self.api_key:
            raise ProviderError(
                "No LLM API key found. Set LLM_API_KEY (or GITHUB_TOKEN for the "
                "'github' provider)."
            )

    # -- public API ---------------------------------------------------------
    def chat(self, system_prompt: str, user_prompt: str) -> str:
        """Return the assistant message text for the given prompts."""
        try:
            if self.provider == "github":
                return self._openai_compatible(
                    GITHUB_MODELS_URL, system_prompt, user_prompt
                )
            if self.provider == "openai":
                base = self.base_url or "https://api.openai.com/v1"
                return self._openai_compatible(
                    f"{base}/chat/completions", system_prompt, user_prompt
                )
            if self.provider == "gemini":
                return self._gemini(system_prompt, user_prompt)
            if self.provider == "ollama":
                return self._ollama(system_prompt, user_prompt)
        except urllib.error.HTTPError as exc:  # pragma: no cover - network path
            detail = exc.read().decode("utf-8", errors="replace")
            raise ProviderError(
                f"{self.provider} request failed with HTTP {exc.code}: {detail[:500]}"
            ) from exc
        except urllib.error.URLError as exc:  # pragma: no cover - network path
            raise ProviderError(f"{self.provider} network error: {exc.reason}") from exc

        raise ProviderError(f"Unhandled provider '{self.provider}'.")

    # -- helpers ------------------------------------------------------------
    def _post_json(
        self, url: str, payload: dict[str, Any], headers: dict[str, str]
    ) -> dict[str, Any]:
        data = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(url, data=data, headers=headers, method="POST")
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            body = response.read().decode("utf-8")
        try:
            return json.loads(body)
        except json.JSONDecodeError as exc:
            raise ProviderError(
                f"Provider returned non-JSON response: {body[:500]}"
            ) from exc

    def _openai_compatible(
        self, url: str, system_prompt: str, user_prompt: str
    ) -> str:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }
        payload = {
            "model": self.model,
            "temperature": 0,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
        }
        data = self._post_json(url, payload, headers)
        try:
            return data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise ProviderError(
                f"Unexpected completion payload: {json.dumps(data)[:500]}"
            ) from exc

    def _gemini(self, system_prompt: str, user_prompt: str) -> str:
        base = self.base_url or "https://generativelanguage.googleapis.com/v1beta"
        url = f"{base}/models/{self.model}:generateContent?key={self.api_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {"temperature": 0},
        }
        data = self._post_json(url, payload, headers)
        try:
            parts = data["candidates"][0]["content"]["parts"]
            return "".join(part.get("text", "") for part in parts)
        except (KeyError, IndexError, TypeError) as exc:
            raise ProviderError(
                f"Unexpected Gemini payload: {json.dumps(data)[:500]}"
            ) from exc

    def _ollama(self, system_prompt: str, user_prompt: str) -> str:
        base = self.base_url or DEFAULT_OLLAMA_BASE_URL
        url = f"{base}/api/chat"
        headers = {"Content-Type": "application/json"}
        payload = {
            "model": self.model,
            "stream": False,
            "options": {"temperature": 0},
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
        }
        data = self._post_json(url, payload, headers)
        try:
            return data["message"]["content"]
        except (KeyError, TypeError) as exc:
            raise ProviderError(
                f"Unexpected Ollama payload: {json.dumps(data)[:500]}"
            ) from exc
