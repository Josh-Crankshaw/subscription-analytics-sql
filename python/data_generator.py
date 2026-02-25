"""
Synthetic subscription dataset generator (UTC timestamps) for a 2025-only dataset.

Generates 3 CSVs:
  - customers.csv
  - subscriptions.csv
  - payments.csv

Model features (matches your specs):
  - 1000 customers across 2025 with a Q3 (Jul–Sep) acquisition spike
  - Churn improves month-to-month (later cohorts churn less)
  - Higher churn in first 1–2 months (onboarding effect)
  - Channel-based churn differences (referral best, paid worst)
  - Plan-based churn differences (pro sticks more)
  - Yearly plans: small churn in first month, near-zero after
  - All timestamps are timezone-aware UTC (ISO-8601 with +00:00)

Run:
  python generate_dataset.py

Optional:
  python generate_dataset.py --outdir data --seed 42
"""

from __future__ import annotations

import argparse
import math
import os
import random
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd


UTC = timezone.utc


# ----------------------------
# Config
# ----------------------------

@dataclass(frozen=True)
class Config:
    n_customers: int = 1000
    year: int = 2025
    seed: int = 42
    outdir: str = "."

    # Q3 marketing spike weights by month (must sum to 1.0 after normalization)
    # Jan..Dec
    signup_month_weights: Tuple[float, ...] = (
        0.05, 0.05, 0.06, 0.06, 0.07, 0.07,  # Jan-Jun
        0.12, 0.15, 0.13,                    # Jul-Sep spike
        0.09, 0.08, 0.07                     # Oct-Dec
    )

    # Countries distribution
    countries: Tuple[str, ...] = ("NZ", "AU", "US", "UK", "CA")
    country_weights: Tuple[float, ...] = (0.40, 0.20, 0.20, 0.10, 0.10)

    # Acquisition channels distribution (you can tweak)
    channels: Tuple[str, ...] = ("Referral", "Organic", "Google Ads", "Facebook Ads")
    channel_weights: Tuple[float, ...] = (0.18, 0.42, 0.25, 0.15)

    # Plans and billing cycles
    plan_names: Tuple[str, ...] = ("basic", "pro")
    plan_weights: Tuple[float, ...] = (0.75, 0.25)

    billing_cycles: Tuple[str, ...] = ("monthly", "yearly")
    billing_weights: Tuple[float, ...] = (0.80, 0.20)

    # Pricing
    monthly_price_by_plan: Dict[str, float] = None  # set in __post_init__ style below

    # Payment outcomes
    fail_rate: float = 0.04  # 4% failed
    refund_rate: float = 0.00  # keep 0 unless you want refunds too

    # Base churn targets (monthly cycle) improve through the year by cohort
    # January cohort has higher churn than December cohort.
    jan_base_monthly_churn: float = 0.045  # 4.5% baseline
    dec_base_monthly_churn: float = 0.030  # 3.0% baseline

    # Early lifecycle churn bump multipliers for monthly subscribers
    month1_multiplier: float = 2.0
    month2_multiplier: float = 1.3

    # Channel churn multipliers (lower is better retention)
    channel_churn_multiplier: Dict[str, float] = None

    # Plan churn multipliers
    plan_churn_multiplier: Dict[str, float] = None

    # Yearly churn behaviour
    yearly_month1_churn: float = 0.015  # 1.5% in first month
    yearly_post_month1_churn: float = 0.002  # 0.2% per month after

    # Billing time-of-day (UTC)
    billing_hour_utc: int = 2  # 02:00 UTC


def build_config(args: argparse.Namespace) -> Config:
    cfg = Config(
        n_customers=args.n_customers,
        year=args.year,
        seed=args.seed,
        outdir=args.outdir,
    )

    # attach dict defaults
    object.__setattr__(cfg, "monthly_price_by_plan", {"basic": 20.00, "pro": 50.00})
    object.__setattr__(cfg, "channel_churn_multiplier", {
        "Referral": 0.60,
        "Organic": 0.80,
        "Google Ads": 1.10,
        "Facebook Ads": 1.20,
    })
    object.__setattr__(cfg, "plan_churn_multiplier", {
        "basic": 1.10,
        "pro": 0.85,
    })
    return cfg


# ----------------------------
# Helpers
# ----------------------------

def normalize(weights: List[float]) -> List[float]:
    s = sum(weights)
    if s <= 0:
        raise ValueError("Weights must sum to > 0")
    return [w / s for w in weights]


def is_leap(year: int) -> bool:
    return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)


def days_in_month(year: int, month: int) -> int:
    if month == 2:
        return 29 if is_leap(year) else 28
    if month in (1, 3, 5, 7, 8, 10, 12):
        return 31
    return 30


def clamp_day_to_month(year: int, month: int, day: int) -> int:
    return max(1, min(day, days_in_month(year, month)))


def random_timestamp_in_month_utc(rng: random.Random, year: int, month: int) -> datetime:
    dmax = days_in_month(year, month)
    day = rng.randint(1, dmax)
    hour = rng.randint(0, 23)
    minute = rng.randint(0, 59)
    second = rng.randint(0, 59)
    return datetime(year, month, day, hour, minute, second, tzinfo=UTC)


def month_index(dt: datetime) -> int:
    """Jan of the same year => 0, Feb => 1, ..."""
    return dt.month - 1


def add_months_utc(dt: datetime, months: int) -> datetime:
    """
    Add months keeping time and tz. If day exceeds month length, clamp.
    """
    y = dt.year + (dt.month - 1 + months) // 12
    m = (dt.month - 1 + months) % 12 + 1
    d = clamp_day_to_month(y, m, dt.day)
    return datetime(y, m, d, dt.hour, dt.minute, dt.second, tzinfo=dt.tzinfo)


def trunc_to_month_utc(dt: datetime) -> datetime:
    return datetime(dt.year, dt.month, 1, 0, 0, 0, tzinfo=UTC)


def cohort_base_monthly_churn(cfg: Config, signup_dt: datetime) -> float:
    """
    Linearly interpolate base churn between Jan and Dec by signup month.
    """
    m = month_index(signup_dt)  # 0..11
    # Linear interpolation: Jan -> jan_base, Dec -> dec_base
    if m <= 0:
        return cfg.jan_base_monthly_churn
    if m >= 11:
        return cfg.dec_base_monthly_churn
    t = m / 11.0
    return cfg.jan_base_monthly_churn * (1 - t) + cfg.dec_base_monthly_churn * t


def payment_status(rng: random.Random, cfg: Config) -> str:
    x = rng.random()
    if x < cfg.fail_rate:
        return "failed"
    # If you later add refunds, do it here.
    return "successful"


def compute_yearly_amount(cfg: Config, plan_name: str) -> float:
    # Simple: 12 * monthly price with a modest discount could be realistic; keep it simple for now.
    monthly = float(cfg.monthly_price_by_plan[plan_name])
    return round(12 * monthly * 0.90, 2)  # 10% discount


# ----------------------------
# Generation logic
# ----------------------------

def generate_customers(cfg: Config, rng: random.Random) -> pd.DataFrame:
    month_weights = normalize(list(cfg.signup_month_weights))
    months = list(range(1, 13))
    chosen_months = rng.choices(months, weights=month_weights, k=cfg.n_customers)

    countries = rng.choices(list(cfg.countries), weights=normalize(list(cfg.country_weights)), k=cfg.n_customers)
    channels = rng.choices(list(cfg.channels), weights=normalize(list(cfg.channel_weights)), k=cfg.n_customers)

    created_ats = [random_timestamp_in_month_utc(rng, cfg.year, m) for m in chosen_months]

    df = pd.DataFrame({
        "customer_id": np.arange(1, cfg.n_customers + 1, dtype=int),
        "created_at": created_ats,
        "country": countries,
        "acquisition_channel": channels,
    })
    return df.sort_values("created_at").reset_index(drop=True)


def simulate_subscription_end(
    cfg: Config,
    rng: random.Random,
    start_at: datetime,
    plan_name: str,
    billing_cycle: str,
    acquisition_channel: str,
) -> Tuple[Optional[datetime], str]:
    """
    Returns (end_at, status). end_at is None if active through 2025-12-31.
    Churn simulation happens month-by-month in UTC.
    """
    # Company operates over 2025; stop simulation at end of year
    end_of_year = datetime(cfg.year, 12, 31, 23, 59, 59, tzinfo=UTC)

    if billing_cycle == "yearly":
        # Month 1: small churn; after that near zero
        # We model churn checks at 1-month boundaries after start.
        # Month 1 check
        check1 = add_months_utc(start_at, 1)
        if check1 <= end_of_year and rng.random() < cfg.yearly_month1_churn:
            # churn happens in month 1: choose a random day/time between start and check1
            delta = check1 - start_at
            churn_at = start_at + timedelta(seconds=rng.randint(1, max(1, int(delta.total_seconds()))))
            churn_at = churn_at.astimezone(UTC)
            return churn_at, "cancelled"

        # Subsequent months: very low churn
        month = 2
        while True:
            check = add_months_utc(start_at, month)
            if check > end_of_year:
                break
            if rng.random() < cfg.yearly_post_month1_churn:
                # churn within this month window (previous check .. check)
                prev = add_months_utc(start_at, month - 1)
                delta = check - prev
                churn_at = prev + timedelta(seconds=rng.randint(1, max(1, int(delta.total_seconds()))))
                churn_at = churn_at.astimezone(UTC)
                return churn_at, "cancelled"
            month += 1

        return None, "active"

    # Monthly: churn probability varies by cohort, plan, channel, lifecycle month
    base = cohort_base_monthly_churn(cfg, start_at)
    channel_mult = cfg.channel_churn_multiplier[acquisition_channel]
    plan_mult = cfg.plan_churn_multiplier[plan_name]

    # Simulate churn checks at month boundaries after start, month-by-month
    # "Lifecycle month 1" = first month after signup
    lifecycle = 1
    while True:
        next_boundary = add_months_utc(start_at, lifecycle)
        if next_boundary > end_of_year:
            break

        lifecycle_mult = 1.0
        if lifecycle == 1:
            lifecycle_mult = cfg.month1_multiplier
        elif lifecycle == 2:
            lifecycle_mult = cfg.month2_multiplier

        p = base * channel_mult * plan_mult * lifecycle_mult
        # guardrail so it doesn't exceed silly values
        p = min(max(p, 0.0), 0.40)

        if rng.random() < p:
            # churn occurs within this month window (prev_boundary .. next_boundary)
            prev_boundary = add_months_utc(start_at, lifecycle - 1)
            delta = next_boundary - prev_boundary
            churn_at = prev_boundary + timedelta(seconds=rng.randint(1, max(1, int(delta.total_seconds()))))
            churn_at = churn_at.astimezone(UTC)
            return churn_at, "cancelled"

        lifecycle += 1

    return None, "active"


def generate_subscriptions(cfg: Config, rng: random.Random, customers: pd.DataFrame) -> pd.DataFrame:
    plans = rng.choices(list(cfg.plan_names), weights=normalize(list(cfg.plan_weights)), k=len(customers))
    cycles = rng.choices(list(cfg.billing_cycles), weights=normalize(list(cfg.billing_weights)), k=len(customers))

    rows = []
    for i, row in customers.iterrows():
        customer_id = int(row["customer_id"])
        created_at: datetime = row["created_at"]
        channel = str(row["acquisition_channel"])

        plan = plans[i]
        cycle = cycles[i]

        start_at = created_at  # convention: subscription starts at signup moment (UTC)
        end_at, status = simulate_subscription_end(cfg, rng, start_at, plan, cycle, channel)

        monthly_price = float(cfg.monthly_price_by_plan[plan])

        rows.append({
            "subscription_id": i + 1,
            "customer_id": customer_id,
            "plan_name": plan,
            "billing_cycle": cycle,
            "start_at": start_at,
            "end_at": end_at,
            "status": status,
            "monthly_price": round(monthly_price, 2),
        })

    df = pd.DataFrame(rows)
    return df


def generate_payments(cfg: Config, rng: random.Random, subs: pd.DataFrame) -> pd.DataFrame:
    """
    Generates payments up to end_of_year or churn end_at.
    Monthly: payment at consistent day-of-month at cfg.billing_hour_utc.
    Yearly: single payment near start.
    """
    end_of_year = datetime(cfg.year, 12, 31, 23, 59, 59, tzinfo=UTC)

    payments = []
    payment_id = 1

    for _, s in subs.iterrows():
        sub_id = int(s["subscription_id"])
        plan = str(s["plan_name"])
        cycle = str(s["billing_cycle"])
        start_at: datetime = s["start_at"]
        end_at: Optional[datetime] = s["end_at"] if pd.notnull(s["end_at"]) else None

        active_until = min(end_of_year, end_at) if end_at is not None else end_of_year

        if cycle == "yearly":
            amount = compute_yearly_amount(cfg, plan)
            # payment time: start date at billing_hour_utc, minute fixed
            pay_dt = datetime(
                start_at.year, start_at.month, start_at.day,
                cfg.billing_hour_utc, 0, 0, tzinfo=UTC
            )
            if pay_dt < start_at:
                # ensure payment isn't before start_at; bump a bit
                pay_dt = start_at + timedelta(minutes=5)

            if pay_dt <= active_until:
                payments.append({
                    "payment_id": payment_id,
                    "subscription_id": sub_id,
                    "payment_at": pay_dt,
                    "amount": float(amount),
                    "payment_status": payment_status(rng, cfg),
                })
                payment_id += 1
            continue

        # monthly cycle payments
        # Choose billing day = start_at day-of-month
        billing_day = start_at.day
        # First payment at start month (on start day at billing_hour)
        current = datetime(start_at.year, start_at.month, clamp_day_to_month(start_at.year, start_at.month, billing_day),
                           cfg.billing_hour_utc, 0, 0, tzinfo=UTC)
        if current < start_at:
            # if signup after billing time that day, pay next day (still in month)
            current = start_at + timedelta(hours=1)
            current = current.astimezone(UTC)

        # Generate until active_until
        while current <= active_until:
            payments.append({
                "payment_id": payment_id,
                "subscription_id": sub_id,
                "payment_at": current,
                "amount": float(cfg.monthly_price_by_plan[plan]),
                "payment_status": payment_status(rng, cfg),
            })
            payment_id += 1

            # Move to next month's billing timestamp
            next_month = add_months_utc(current, 1)
            next_month = datetime(
                next_month.year, next_month.month, clamp_day_to_month(next_month.year, next_month.month, billing_day),
                cfg.billing_hour_utc, 0, 0, tzinfo=UTC
            )
            current = next_month

    return pd.DataFrame(payments)


# ----------------------------
# Output / Validation
# ----------------------------

def ensure_outdir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def to_iso8601_z(dt: Optional[datetime]) -> Optional[str]:
    if dt is None or (isinstance(dt, float) and math.isnan(dt)):
        return None
    if dt.tzinfo is None:
        raise ValueError("Naive datetime encountered; expected UTC tz-aware.")
    # Keep +00:00 (Postgres TIMESTAMPTZ imports this well). If you want "Z", you can convert.
    return dt.isoformat()


def basic_validations(customers: pd.DataFrame, subs: pd.DataFrame, pays: pd.DataFrame, cfg: Config) -> None:
    assert len(customers) == cfg.n_customers
    assert subs["customer_id"].nunique() == cfg.n_customers
    assert subs["subscription_id"].is_unique
    assert pays["payment_id"].is_unique

    # All UTC aware
    for col in ["created_at"]:
        assert all(isinstance(x, datetime) and x.tzinfo is not None for x in customers[col])

    for col in ["start_at"]:
        assert all(isinstance(x, datetime) and x.tzinfo is not None for x in subs[col])

    for col in ["payment_at"]:
        assert all(isinstance(x, datetime) and x.tzinfo is not None for x in pays[col])

    # Payments should not exceed end_at if cancelled (allow a tiny ordering slack not needed; we enforce <=)
    merged = pays.merge(subs[["subscription_id", "end_at"]], on="subscription_id", how="left")
    bad = merged[(merged["end_at"].notna()) & (merged["payment_at"] > merged["end_at"])]
    assert bad.empty, f"Found payments after churn end_at: {len(bad)}"


def write_csvs(customers: pd.DataFrame, subs: pd.DataFrame, pays: pd.DataFrame, outdir: str) -> None:
    # Convert datetimes to ISO strings for clean CSV import
    customers_out = customers.copy()
    customers_out["created_at"] = customers_out["created_at"].apply(to_iso8601_z)

    subs_out = subs.copy()
    subs_out["start_at"] = subs_out["start_at"].apply(to_iso8601_z)
    subs_out["end_at"] = subs_out["end_at"].apply(lambda x: to_iso8601_z(x) if pd.notnull(x) else None)

    pays_out = pays.copy()
    pays_out["payment_at"] = pays_out["payment_at"].apply(to_iso8601_z)

    customers_out.to_csv(os.path.join(outdir, "customers.csv"), index=False)
    subs_out.to_csv(os.path.join(outdir, "subscriptions.csv"), index=False)
    pays_out.to_csv(os.path.join(outdir, "payments.csv"), index=False)


# ----------------------------
# Main
# ----------------------------

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n_customers", type=int, default=1000)
    parser.add_argument("--year", type=int, default=2025)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--outdir", type=str, default=".")
    args = parser.parse_args()

    cfg = build_config(args)
    ensure_outdir(cfg.outdir)

    rng = random.Random(cfg.seed)
    np.random.seed(cfg.seed)

    customers = generate_customers(cfg, rng)
    subs = generate_subscriptions(cfg, rng, customers)
    pays = generate_payments(cfg, rng, subs)

    basic_validations(customers, subs, pays, cfg)
    write_csvs(customers, subs, pays, cfg.outdir)

    # Minimal summary prints (handy for sanity)
    print("Generated:")
    print(f"  customers:      {len(customers)}")
    print(f"  subscriptions:  {len(subs)}")
    print(f"  payments:       {len(pays)}")
    print()
    print("Quick sanity:")
    print("  active subscriptions:", int((subs["status"] == "active").sum()))
    print("  cancelled subscriptions:", int((subs["status"] == "cancelled").sum()))
    print("  payment_status counts:")
    print(pays["payment_status"].value_counts().to_string())
    print()
    print(f"CSV files written to: {os.path.abspath(cfg.outdir)}")


if __name__ == "__main__":
    main()