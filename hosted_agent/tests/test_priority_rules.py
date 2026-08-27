"""Unit tests for the deterministic fictional priority policy."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


HOSTED_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HOSTED_ROOT))

from priority_rules import calculate_priority  # noqa: E402


class CalculatePriorityTests(unittest.TestCase):
    def test_shared_demo_case_is_p0_with_expected_reasons(self) -> None:
        decision = calculate_priority(
            annual_contract_usd=240_000,
            outage_minutes=95,
            regulated_regions=2,
            renewal_days=21,
        )

        self.assertEqual("P0", decision.priority)
        self.assertEqual(8, decision.score)
        self.assertEqual(
            (
                "OUTAGE_60",
                "STRATEGIC_CONTRACT",
                "REGULATED_IMPACT",
                "RENEWAL_30",
            ),
            decision.reason_codes,
        )

    def test_midrange_case_is_p1(self) -> None:
        decision = calculate_priority(
            annual_contract_usd=250_000,
            outage_minutes=75,
            regulated_regions=0,
            renewal_days=90,
        )

        self.assertEqual("P1", decision.priority)
        self.assertEqual(5, decision.score)

    def test_low_impact_case_is_p3(self) -> None:
        decision = calculate_priority(
            annual_contract_usd=20_000,
            outage_minutes=10,
            regulated_regions=0,
            renewal_days=120,
        )

        self.assertEqual("P3", decision.priority)
        self.assertEqual(0, decision.score)
        self.assertEqual((), decision.reason_codes)

    def test_negative_input_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            calculate_priority(
                annual_contract_usd=20_000,
                outage_minutes=-1,
                regulated_regions=0,
                renewal_days=120,
            )


if __name__ == "__main__":
    unittest.main()
