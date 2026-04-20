# Python Application Patterns

Reference implementation patterns for embedding evaluation loops in Python applications.
Use these when building your own agent evaluation system (not CLI-specific).

---

## Pattern 1: Basic Reflection

Agent evaluates and improves its own output through self-critique.

```python
import json

def reflect_and_refine(task: str, criteria: list[str], max_iterations: int = 3) -> str:
    """Generate with self-critique reflection loop."""
    output = llm(f"Complete this task:\n{task}")

    for i in range(max_iterations):
        critique = llm(f"""
        Evaluate this output against criteria: {criteria}
        Output: {output}
        Rate each criterion PASS or FAIL with feedback. Return as JSON:
        {{"criterion_name": {{"status": "PASS"|"FAIL", "feedback": "..."}}}}
        """)

        critique_data = json.loads(critique)
        all_pass = all(c["status"] == "PASS" for c in critique_data.values())
        if all_pass:
            return output

        failed = {k: v["feedback"] for k, v in critique_data.items() if v["status"] == "FAIL"}
        output = llm(f"Improve to address these issues: {failed}\nOriginal output:\n{output}")

    return output
```

**Key insight**: Use structured JSON output for reliable parsing. Never parse free-text critiques.

---

## Pattern 2: Evaluator-Optimizer

Separate generation and evaluation into distinct components.

```python
import json

class EvaluatorOptimizer:
    def __init__(self, score_threshold: float = 0.8, max_iterations: int = 3) -> None:
        self.score_threshold = score_threshold
        self.max_iterations = max_iterations

    def generate(self, task: str) -> str:
        return llm(f"Complete this task:\n{task}")

    def evaluate(self, output: str, task: str) -> dict:
        return json.loads(llm(f"""
        Evaluate this output for the given task.
        Task: {task}
        Output: {output}
        Return JSON: {{
            "overall_score": <0.0 to 1.0>,
            "dimensions": {{
                "accuracy": <0.0 to 1.0>,
                "clarity": <0.0 to 1.0>,
                "completeness": <0.0 to 1.0>
            }},
            "improvement_notes": "<what to fix>"
        }}
        """))

    def optimize(self, output: str, feedback: dict) -> str:
        return llm(f"Improve this output based on feedback.\nFeedback: {feedback}\nOutput:\n{output}")

    def run(self, task: str) -> str:
        output = self.generate(task)
        for _ in range(self.max_iterations):
            evaluation = self.evaluate(output, task)
            if evaluation["overall_score"] >= self.score_threshold:
                break
            output = self.optimize(output, evaluation)
        return output
```

---

## Pattern 3: Code-Specific Reflection (Test-Driven)

Test-driven refinement loop for code generation. Write tests first, iterate until pass.

```python
import subprocess

class CodeReflector:
    def reflect_and_fix(self, spec: str, max_iterations: int = 3) -> str:
        """Generate code and iterate until all tests pass."""
        code = llm(f"Write Python code for this specification:\n{spec}")
        tests = llm(f"Generate pytest tests for this specification:\n{spec}\nCode:\n{code}")

        for _ in range(max_iterations):
            result = self._run_tests(code, tests)
            if result["success"]:
                return code
            code = llm(f"Fix the following test error:\n{result['error']}\nCurrent code:\n{code}")

        return code

    def _run_tests(self, code: str, tests: str) -> dict:
        import tempfile, os
        with tempfile.TemporaryDirectory() as tmp:
            code_path = os.path.join(tmp, "solution.py")
            test_path = os.path.join(tmp, "test_solution.py")
            with open(code_path, "w") as f:
                f.write(code)
            with open(test_path, "w") as f:
                f.write(tests)
            result = subprocess.run(
                ["python", "-m", "pytest", test_path, "-q"],
                capture_output=True, text=True, cwd=tmp
            )
        return {"success": result.returncode == 0, "error": result.stdout + result.stderr}
```

---

## Rubric Helper

Evaluate output against weighted dimensions and compute a composite score.

```python
import json
from typing import TypedDict

class RubricDimension(TypedDict):
    weight: float

RUBRIC: dict[str, RubricDimension] = {
    "accuracy":     {"weight": 0.4},
    "clarity":      {"weight": 0.3},
    "completeness": {"weight": 0.3},
}

def evaluate_with_rubric(output: str, rubric: dict[str, RubricDimension]) -> float:
    """Score output against rubric. Returns 0.0–1.0."""
    dimensions = list(rubric.keys())
    scores: dict[str, float] = json.loads(llm(
        f"Rate this output 1–5 for each dimension: {dimensions}\n"
        f"Output:\n{output}\n"
        f"Return JSON: {{\"dimension_name\": <1-5>}}"
    ))
    return sum(scores[d] * rubric[d]["weight"] for d in rubric) / 5.0
```

---

## Best Practices

| Practice | Rationale |
|----------|-----------|
| **Clear criteria upfront** | Vague criteria produce vague feedback |
| **Max iterations 3–5** | Diminishing returns; prevents infinite loops |
| **Convergence check** | Stop if score not improving across iterations |
| **Structured JSON output** | Enables reliable parsing without prompt sensitivity |
| **Log full trajectory** | Keep history for debugging — don't just keep final output |
| **Targeted refinement** | Only address failed dimensions; don't rewrite everything |
