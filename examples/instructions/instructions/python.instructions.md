---
applyTo:
  - "backend/**/*.py"
  - "scripts/**/*.py"
---

# Python conventions

Applies to all Python files under `backend/` and `scripts/`.

## Style

- Python **3.12**; use modern syntax (`match`, PEP 695 generics where helpful).
- Type hints are **mandatory** on public functions and class attributes.
- Run **`ruff check --fix && ruff format`** before claiming done.
- Prefer `pathlib.Path` over `os.path`.
- Imports sorted with `ruff` (isort-compatible).

## Testing

- pytest. Test files named `test_*.py` under `backend/tests/` (mirroring the source
  tree).
- Async tests use `pytest-asyncio` with `asyncio_mode = "auto"` (configured in
  `pyproject.toml`).
- For each new public function, add at least one happy-path test and one error-path
  test.

## Web (FastAPI)

- Routers live under `backend/app/routers/`. One file per resource.
- Request / response bodies are **Pydantic v2 models** in `backend/app/schemas/`.
- Don't import `asyncpg` directly in routers — use `backend/app/db.py`.
- All endpoints have explicit response models (`response_model=...`). No bare `dict`
  responses in production code.

## Don't

- Don't use `print(...)` for logging. Use the project's `structlog` logger.
- Don't import from `backend.tests.*` outside the tests directory.
- Don't use `dict()` / `.copy()` on Pydantic models — use `.model_dump()`.
