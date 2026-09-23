# Engineering Workflow Blueprint: Architected Iteration (Orchestrated Edition)

This document defines the operational process for building high-quality, production-ready software using AI. It moves beyond simple prompting into **Orchestrated Development**, separating Reasoning (Planning) from Production (Execution) and Validation (Audit).

---

## 🎭 The Persona Triad
To ensure quality, the AI must shift between three distinct personas. Each persona has a different "cognitive goal."

| Persona | Model Role | Cognitive Goal | Primary Output |
| :--- | :--- | :--- | :--- |
| **The Architect** | **Reasoning** | Global Vision & Contracts | Tech Specs, JSON Schemas, Atomic Structure |
| **The Executor** | **Production** | Modular Implementation | Typed Code, Components, Logic |
| **The Auditor** | **Adversarial** | Critical Verification | Defect Reports, Checklist Gaps |

---

## 🏗️ Core Structural Pillars

### 1. The Atomic File Standard
To prevent AI reasoning degradation, all code must follow a strict modular structure.
*   **The Limit:** No single file should exceed **200 lines of code**.
*   **The Hierarchy:** Atoms $\rightarrow$ Molecules $\rightarrow$ Organisms $\rightarrow$ Templates.

### 2. Specification-First Development (The "Contract")
Never implement a feature without a locked data contract.
*   **The Sequence:**
    1. **Architect Mode:** Define TypeScript interfaces and API JSON responses.
    2. **Review:** User approves the "Contract."
    3. **Executor Mode:** Build the UI/Logic based *exactly* on those interfaces.

### 3. The Hardening Loop
A feature is only "Done" after three distinct passes:
- **Pass 1 (The Vibe):** Focus on the "Happy Path" and core functionality.
- **Pass 2 (The Edge):** Implement loading skeletons, error boundaries, and input validation.
- **Pass 3 (The Polish):** Apply accessibility (ARIA), animations, and performance optimizations.

---

## 🔄 The Failure Recovery Loop (Anti-Hallucination)
When a bug persists after two attempts to fix it, the AI must break the loop to avoid "Apology-Coding."

**The Recovery Sequence:**
1. **Stop:** cease all code generation.
2. **RCA (Root Cause Analysis):** Switch to **Architect Mode**. Explain *why* the bug is happening and *why* previous fixes failed.
3. **Context Reset:** Summarize the current state, clear the "noise" of previous failed attempts, and implement a fresh solution based on the RCA.

---

## 🚀 Operational Execution Guide

Follow this exact sequence for every new feature:

### Phase 1: The Architecture (Architect Mode)
**Prompt:** *"Switch to **Architect Mode**. I want to implement [FEATURE]. Please define the data contract (Interfaces/JSON) and the Atomic File Structure. Do not write implementation code yet."*

### Phase 2: The Base Build (Executor Mode)
**Prompt:** *"Switch to **Executor Mode**. Implement the base functionality using the agreed-upon contracts. Follow the atomic structure and `PERSONA.md`. Provide the Checklist Alignment footer."*

### Phase 3: The Hardening (Executor Mode)
**Prompt:** *"Still in **Executor Mode**, now harden this feature. Implement the unhappy paths: add loading skeletons, handle API error states, and add strict input validation."*

### Phase 4: The Audit (Auditor Mode)
**Prompt:** *"Switch to **Auditor Mode**. Act as a critical security auditor. Scan this implementation against `STANDARDS.md`. Be brutal—find every missing item or risk."*

### Phase 5: Final Polish & Fixes (Executor Mode)
**Prompt:** *"Switch back to **Executor Mode**. Address every point raised by the Auditor and apply the final professional polish (animations/a11y)."*

### Phase 6: Final Verification
**Prompt:** *"Run a final audit of this feature. Confirm all items in the `STANDARDS.md` are satisfied."*

---
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
