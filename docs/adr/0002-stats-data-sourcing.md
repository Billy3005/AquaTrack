# 0002 — Stats screen data sourcing

- Status: Accepted
- Date: 2026-06-05

## Context

The History/Stats screen (`StatsScreenRedesign`) shipped its UI before being wired
to real data. In practice almost every widget showed fabricated values:

- The wave chart called `_convertDashboardDataToStatsData`, which dumped the whole
  period's volume into a single day (`if (i == 1)`) and left every other day at 0 —
  hardcoded to one test user's pattern ("ada").
- The Daily Goal was a hardcoded `2000`/`2500` constant, contradicting CONTEXT.md
  where **Daily Goal** is the canonical computed target (`calculated_daily_goal_ml`).
- The period toggle only called `setState`; it never refetched, so Week/Month
  changed labels but not data.
- AI Insights were produced by a Flutter-side "intelligence layer"
  (`InsightEngine` + `ContextBuilder` + `WeatherRepository`) fed by `math.Random()`
  and a fixed hourly array — i.e. noise presented as analysis.

Meanwhile the backend already exposed correct, per-user endpoints: `/stats/dashboard`,
`/stats/trends/daily`, `/stats/trends/hourly`, `/stats/liquid-types`,
`/stats/goals/progress`, `/stats/streaks`, `/stats/insights`.

A subtlety drove the original team to abandon `/stats/trends/daily`: in SQLite
`func.date(IntakeLog.logged_at)` returns a **string**, while the fill-missing-dates
loop keys the dict with Python `date` objects, so `check_date in data_dict` is always
False and the endpoint returns all zeros. Rather than re-plumb the chart through that
endpoint plus a second call for the goal, we needed a single source carrying both
per-day intake **and** the real per-day goal.

## Decision

1. **Chart source = `/stats/goals/progress`, not `/stats/trends/daily`.**
   `goals/progress` computes per-day stats in Python (no string/date bug) and already
   returns, for each day: effective ml, the user's **real** `daily_goal_ml`, a
   `goal_achieved` flag, and an aggregate achievement rate. One call feeds the chart,
   the day labels, the goal line, and the completion metric. `/stats/trends/daily` is
   intentionally left unused by the chart (its SQLite bug is not fixed here).

2. **Insights = backend `/stats/insights`.** The screen renders the backend's
   rule-based insights computed from real logs. The Flutter intelligence layer is
   **not deleted** (it has weather integration worth keeping) but is no longer wired
   into Stats; it remains parked/planned. CONTEXT.md records this wiring status so the
   glossary does not misdescribe live behaviour.

3. **One selected period drives everything.** A `statsPeriodProvider`
   (`StateProvider<StatsPeriod>`) holds the Week/Month selection; `StatsNotifier`
   watches it and refetches. The previous `setPeriod` method and per-widget
   `_selectedPeriod` state are removed.

4. **No hardcoded values.** Streak and coins come from `userStatsProvider`
   (real backend data); the goal comes from `goals/progress`; the liquid breakdown
   from `/stats/liquid-types`.

## Consequences

- The chart, metrics, completion rate, and insights now reflect the signed-in user's
  actual data. Goal completion is consistent with the **Daily Goal** definition.
- The mapping is a pure function (`buildStatsData`) and is unit-tested without IO.
- Month view renders 30 day-points with day labels hidden (per-day weekday labels
  only make sense for the 7-day Week view); individual dots are suppressed when
  N > 10 to avoid clutter.
- A known backend bug remains in `/stats/trends/daily` (SQLite string/date key
  mismatch). It is documented here; fixing it is deferred because the chart no longer
  depends on it. Revisit if a consumer needs total-vs-effective per-day series.
- The parked intelligence layer is dead weight until re-wired; its tests still run.

## When to revisit

- If Stats needs weather-aware insights, re-wire the intelligence layer with **real**
  `/stats/trends/daily` + `/stats/trends/hourly` data (which requires fixing the
  SQLite bug first) and update CONTEXT.md's wiring status.
- If a feature needs the per-day total/effective split, fix `/stats/trends/daily`.
