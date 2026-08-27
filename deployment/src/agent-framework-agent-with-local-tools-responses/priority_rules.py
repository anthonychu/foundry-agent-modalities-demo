"""Deterministic fictional support-priority policy used by the Hosted Agent demo."""

from __future__ import annotations

from dataclasses import asdict, dataclass


@dataclass(frozen=True)
class PriorityDecision:
    priority: str
    score: int
    reason_codes: tuple[str, ...]

    def to_dict(self) -> dict[str, object]:
        result = asdict(self)
        result["reason_codes"] = list(self.reason_codes)
        return result


def calculate_priority(
    annual_contract_usd: int,
    outage_minutes: int,
    regulated_regions: int,
    renewal_days: int,
) -> PriorityDecision:
    """Apply the fictional demo rubric and return a deterministic priority decision."""

    values = {
        "annual_contract_usd": annual_contract_usd,
        "outage_minutes": outage_minutes,
        "regulated_regions": regulated_regions,
        "renewal_days": renewal_days,
    }
    if any(value < 0 for value in values.values()):
        raise ValueError(f"Priority inputs must be non-negative: {values}")

    score = 0
    reason_codes: list[str] = []

    if outage_minutes >= 60:
        score += 3
        reason_codes.append("OUTAGE_60")
    if annual_contract_usd >= 200_000:
        score += 2
        reason_codes.append("STRATEGIC_CONTRACT")
    if regulated_regions >= 1:
        score += 2
        reason_codes.append("REGULATED_IMPACT")
    if renewal_days <= 30:
        score += 1
        reason_codes.append("RENEWAL_30")

    if score >= 7:
        priority = "P0"
    elif score >= 4:
        priority = "P1"
    elif score >= 2:
        priority = "P2"
    else:
        priority = "P3"

    return PriorityDecision(priority, score, tuple(reason_codes))