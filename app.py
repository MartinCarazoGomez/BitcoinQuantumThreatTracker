import numpy as np
import pandas as pd
import plotly.graph_objects as go
import streamlit as st


# --- Custom CSS for polished UI ---
CUSTOM_CSS = """
<style>
    /* Import font */
    @import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');
    
    /* Base */
    html, body, [class*="css"] { font-family: 'DM Sans', sans-serif !important; }
    
    /* Main container */
    .main .block-container { 
        padding-top: 2rem; 
        padding-bottom: 3rem; 
        max-width: 1420px;
    }
    
    /* Hero title */
    h1 { 
        font-weight: 700 !important; 
        letter-spacing: -0.03em;
        font-size: 2.25rem !important;
        background: linear-gradient(135deg, #f59e0b 0%, #fbbf24 40%, #fde68a 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        margin-bottom: 0.25rem !important;
    }
    
    /* Subheaders - lighter for flow */
    h2, h3 { 
        font-weight: 600 !important; 
        color: #e2e8f0 !important;
        padding-bottom: 0.4rem;
        padding-left: 0.6rem;
        border-left: 3px solid rgba(245, 158, 11, 0.6);
        margin-left: -0.6rem;
        margin-top: 1.75rem !important;
        margin-bottom: 0.75rem !important;
    }
    
    /* Hero intro card */
    .hero-card {
        background: linear-gradient(135deg, rgba(30, 41, 59, 0.6) 0%, rgba(15, 23, 42, 0.8) 100%);
        padding: 1.5rem 1.75rem;
        border-radius: 16px;
        border: 1px solid rgba(245, 158, 11, 0.2);
        margin-bottom: 1.5rem;
        box-shadow: 0 4px 24px -4px rgba(0, 0, 0, 0.3);
        color: #cbd5e1;
        line-height: 1.65;
        font-size: 0.95rem;
    }
    
    /* Metric cards - ensure text fits */
    [data-testid="stMetric"] {
        background: linear-gradient(145deg, rgba(17, 24, 39, 0.95) 0%, rgba(15, 23, 42, 0.98) 100%);
        padding: 1.1rem 1.3rem;
        border-radius: 14px;
        border: 1px solid rgba(148, 163, 184, 0.08);
        box-shadow: 0 4px 12px -2px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255,255,255,0.03);
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        overflow: visible;
        word-wrap: break-word;
        overflow-wrap: break-word;
    }
    [data-testid="stMetric"]:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.35);
    }
    [data-testid="stMetric"] label { font-weight: 600 !important; color: #94a3b8 !important; font-size: 0.8rem !important; text-transform: uppercase; letter-spacing: 0.02em; word-wrap: break-word; white-space: normal !important; }
    [data-testid="stMetricValue"] { font-weight: 700 !important; color: #f59e0b !important; font-size: 1.1rem !important; word-wrap: break-word; overflow-wrap: break-word; white-space: normal !important; }
    
    /* Hide sidebar - all nav via home cards */
    [data-testid="stSidebar"] { display: none !important; }
    
    /* Buttons */
    .stButton > button {
        border-radius: 10px;
        font-weight: 600;
        transition: all 0.2s ease;
        background: linear-gradient(135deg, rgba(245, 158, 11, 0.15) 0%, rgba(251, 191, 36, 0.08) 100%) !important;
        border: 1px solid rgba(245, 158, 11, 0.35) !important;
    }
    .stButton > button:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 16px rgba(245, 158, 11, 0.2);
    }
    
    /* Selectbox */
    [data-testid="stSelectbox"] > div { border-radius: 10px !important; }
    
    /* Expanders */
    .streamlit-expanderHeader { font-weight: 600 !important; }
    [data-testid="stExpander"] {
        background: rgba(17, 24, 39, 0.5);
        border: 1px solid rgba(148, 163, 184, 0.08);
        border-radius: 12px;
        overflow: hidden;
    }
    
    /* Alerts - ensure long text wraps */
    [data-testid="stAlert"], [data-testid="stSuccess"], [data-testid="stWarning"], [data-testid="stError"] {
        border-radius: 12px; border: 1px solid rgba(148, 163, 184, 0.1);
        word-wrap: break-word; overflow-wrap: break-word; white-space: normal !important;
    }
    
    /* Dataframe */
    .stDataFrame { border-radius: 12px; overflow: hidden; border: 1px solid rgba(148, 163, 184, 0.08); }
    
    /* Chart containers */
    .stPyplot { border-radius: 14px; overflow: hidden; box-shadow: 0 4px 20px -4px rgba(0, 0, 0, 0.4); }
    
    /* Divider - subtle */
    hr { border: none; height: 1px; background: linear-gradient(90deg, transparent, rgba(148, 163, 184, 0.15), transparent); margin: 1.25rem 0 !important; }
    
    /* Flow: compact sections */
    .flow-section { margin-bottom: 0.5rem; }
    
    /* General text wrapping */
    .main p, .main [data-testid="stMarkdown"], .hero-card { word-wrap: break-word; overflow-wrap: break-word; max-width: 100%; }
    
    /* Sidebar labels - allow wrap */
    [data-testid="stSidebar"] label { white-space: normal !important; }
    
    /* Dataframe - readable columns */
    .stDataFrame td, .stDataFrame th { white-space: normal !important; word-wrap: break-word; padding: 0.5rem !important; }
    
    /* Nav cards on home */
    .nav-card {
        background: linear-gradient(145deg, rgba(30, 41, 59, 0.7) 0%, rgba(15, 23, 42, 0.9) 100%);
        padding: 2rem;
        border-radius: 20px;
        border: 1px solid rgba(245, 158, 11, 0.25);
        cursor: pointer;
        transition: all 0.3s ease;
        text-decoration: none;
        display: block;
        color: inherit;
        box-shadow: 0 4px 20px -4px rgba(0,0,0,0.3);
    }
    .nav-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 12px 32px -8px rgba(245, 158, 11, 0.2);
        border-color: rgba(245, 158, 11, 0.5);
    }
    .nav-card h3 { margin: 0 0 0.5rem 0 !important; color: #f59e0b !important; border: none !important; padding: 0 !important; font-size: 1.4rem !important; }
    .nav-card p { margin: 0 !important; color: #94a3b8 !important; font-size: 0.9rem !important; line-height: 1.5 !important; }
    
    /* Back button bar */
    .back-bar { padding: 0.75rem 0; margin-bottom: 1.5rem; border-bottom: 1px solid rgba(148,163,184,0.15); }
    
    /* ========== Landing page (professional) ========== */
    .landing-wrap { max-width: 1100px; margin: 0 auto; }
    .landing-hero {
        text-align: center;
        padding: 3rem 2rem 2.5rem;
        margin-bottom: 2rem;
        border-radius: 24px;
        background: 
            radial-gradient(ellipse 80% 60% at 50% -20%, rgba(245, 158, 11, 0.18), transparent),
            radial-gradient(ellipse 60% 40% at 100% 50%, rgba(56, 189, 248, 0.08), transparent),
            linear-gradient(180deg, rgba(17, 24, 39, 0.95) 0%, rgba(10, 15, 26, 0.98) 100%);
        border: 1px solid rgba(245, 158, 11, 0.12);
        box-shadow: 0 24px 48px -24px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255,255,255,0.04);
    }
    .landing-badge {
        display: inline-block;
        font-size: 0.72rem;
        font-weight: 600;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: #f59e0b;
        background: rgba(245, 158, 11, 0.12);
        border: 1px solid rgba(245, 158, 11, 0.25);
        padding: 0.35rem 0.85rem;
        border-radius: 999px;
        margin-bottom: 1.25rem;
    }
    .landing-title {
        font-size: clamp(2rem, 4.5vw, 2.85rem);
        font-weight: 800;
        letter-spacing: -0.04em;
        line-height: 1.1;
        margin: 0 0 1rem 0;
        background: linear-gradient(135deg, #fef3c7 0%, #f59e0b 35%, #fbbf24 70%, #fde68a 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }
    .landing-subtitle {
        font-size: 1.08rem;
        color: #94a3b8;
        max-width: 560px;
        margin: 0 auto 1.5rem;
        line-height: 1.65;
        font-weight: 400;
    }
    .landing-meta {
        display: flex;
        justify-content: center;
        gap: 1.5rem;
        flex-wrap: wrap;
        font-size: 0.8rem;
        color: #64748b;
    }
    .landing-meta span { color: #64748b; }
    .landing-meta strong { color: #cbd5e1; font-weight: 600; }
    .landing-stats {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
        margin-bottom: 2.5rem;
        max-width: 900px;
        margin-left: auto;
        margin-right: auto;
    }
    @media (max-width: 768px) { .landing-stats { grid-template-columns: 1fr; } }
    .landing-stat {
        background: rgba(17, 24, 39, 0.6);
        border: 1px solid rgba(148, 163, 184, 0.1);
        border-radius: 14px;
        padding: 1.1rem 1.25rem;
        text-align: center;
    }
    .landing-stat-num { font-size: 1.5rem; font-weight: 700; color: #f59e0b; margin-bottom: 0.25rem; }
    .landing-stat-label { font-size: 0.78rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; }
    .landing-section-title {
        font-size: 0.75rem;
        font-weight: 600;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #64748b;
        margin-bottom: 1rem;
        text-align: center;
    }
    .landing-tile {
        background: linear-gradient(165deg, rgba(30, 41, 59, 0.55) 0%, rgba(15, 23, 42, 0.85) 100%);
        border: 1px solid rgba(148, 163, 184, 0.1);
        border-radius: 16px;
        padding: 1.35rem 1.4rem 1rem;
        margin-bottom: 0.5rem;
        min-height: 112px;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    .landing-tile:hover { border-color: rgba(245, 158, 11, 0.25); box-shadow: 0 8px 24px -12px rgba(0,0,0,0.4); }
    .landing-tile-head { font-size: 1.05rem; font-weight: 700; color: #f1f5f9; margin-bottom: 0.45rem; display: flex; align-items: center; gap: 0.5rem; }
    .landing-tile-head .emoji { font-size: 1.35rem; line-height: 1; }
    .landing-tile-text { font-size: 0.88rem; color: #94a3b8; line-height: 1.5; margin: 0; }
    .landing-cta-row { margin-top: 0.35rem; margin-bottom: 1.1rem; }
    .landing-footer {
        margin-top: 2rem;
        padding: 1.5rem 1.75rem;
        border-radius: 16px;
        background: rgba(30, 41, 59, 0.35);
        border: 1px solid rgba(148, 163, 184, 0.08);
        border-left: 4px solid #f59e0b;
    }
    .landing-footer h4 { margin: 0 0 0.5rem 0; font-size: 0.95rem; color: #e2e8f0; }
    .landing-footer p { margin: 0; font-size: 0.9rem; color: #94a3b8; line-height: 1.6; }
    /* Home primary CTA buttons */
    div[data-testid="column"] .landing-cta-row + div button { min-height: 2.75rem; }
    
    /* Hero action band — clear first step */
    .landing-cta-band {
        max-width: 640px;
        margin: 0 auto 0.25rem;
        padding: 0 0.5rem;
    }
    .landing-cta-band-inner {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
        align-items: stretch;
    }
    @media (max-width: 560px) {
        .landing-cta-band-inner { grid-template-columns: 1fr; }
    }
    .landing-cta-pill {
        text-align: left;
        padding: 1rem 1.15rem 1.1rem;
        border-radius: 16px;
        border: 1px solid rgba(148, 163, 184, 0.12);
        background: rgba(15, 23, 42, 0.55);
        transition: border-color 0.2s ease, background 0.2s ease;
    }
    .landing-cta-pill:hover { border-color: rgba(245, 158, 11, 0.22); background: rgba(15, 23, 42, 0.72); }
    .landing-cta-pill-primary {
        border-color: rgba(245, 158, 11, 0.28);
        background: linear-gradient(165deg, rgba(245, 158, 11, 0.08) 0%, rgba(15, 23, 42, 0.75) 100%);
        box-shadow: 0 0 0 1px rgba(245, 158, 11, 0.06);
    }
    .landing-cta-kicker {
        font-size: 0.68rem;
        font-weight: 700;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: #94a3b8;
        margin-bottom: 0.35rem;
    }
    .landing-cta-pill-primary .landing-cta-kicker { color: #fbbf24; }
    .landing-cta-title {
        font-size: 0.98rem;
        font-weight: 700;
        color: #f1f5f9;
        margin: 0 0 0.35rem 0;
        line-height: 1.25;
    }
    .landing-cta-desc {
        font-size: 0.82rem;
        color: #94a3b8;
        margin: 0;
        line-height: 1.45;
    }
    /* Reference tiles — slightly quieter than analysis picks */
    .landing-tile-ref {
        min-height: 100px;
        padding: 1.15rem 1.25rem 0.95rem;
    }
    .landing-tile-ref .landing-tile-head { font-size: 0.98rem; }
    .landing-workflow {
        margin-top: 1.75rem;
        padding: 1.25rem 1.5rem;
        border-radius: 16px;
        background: rgba(30, 41, 59, 0.4);
        border: 1px dashed rgba(148, 163, 184, 0.2);
        max-width: 900px;
        margin-left: auto;
        margin-right: auto;
    }
    .landing-workflow h4 {
        margin: 0 0 0.75rem 0;
        font-size: 0.72rem;
        font-weight: 700;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        color: #64748b;
    }
    .landing-workflow ol {
        margin: 0;
        padding-left: 1.25rem;
        color: #94a3b8;
        font-size: 0.88rem;
        line-height: 1.65;
    }
    .landing-workflow li { margin-bottom: 0.35rem; }
    .landing-workflow li:last-child { margin-bottom: 0; }
</style>
"""

PAGES = ["home", "simulator", "quick_check", "news", "glossary", "timeline"]
YEARS = np.arange(2026, 2056)
SCENARIOS = ("Optimistic", "Moderate", "Pessimistic")
STRATEGIES = ("SPHINCS+", "Lamport", "Hybrid")


def logistic_curve(x, midpoint, steepness):
    """Standard logistic curve normalized in [0, 1]."""
    return 1.0 / (1.0 + np.exp(-steepness * (x - midpoint)))


def scenario_defaults(name):
    """Preset assumptions for each scenario."""
    presets = {
        "Optimistic": {
            "quantum_steepness": 0.30,
            "break_year": 2044,
            "migration_start": 2030,
            "migration_speed": 0.55,
            "vulnerable_share": 0.55,
            "crisis_threshold": 0.35,
        },
        "Moderate": {
            "quantum_steepness": 0.38,
            "break_year": 2040,
            "migration_start": 2033,
            "migration_speed": 0.42,
            "vulnerable_share": 0.70,
            "crisis_threshold": 0.40,
        },
        "Pessimistic": {
            "quantum_steepness": 0.48,
            "break_year": 2037,
            "migration_start": 2036,
            "migration_speed": 0.30,
            "vulnerable_share": 0.85,
            "crisis_threshold": 0.45,
        },
    }
    return presets[name]


def strategy_effects(strategy):
    """
    Simple strategy modifiers:
    - speed_multiplier: adoption velocity impact
    - friction_years: delay from operational complexity
    """
    effects = {
        "SPHINCS+": {"speed_multiplier": 0.90, "friction_years": 1.0},
        "Lamport": {"speed_multiplier": 0.78, "friction_years": 2.0},
        "Hybrid": {"speed_multiplier": 1.10, "friction_years": 0.0},
    }
    return effects[strategy]


def build_curves(
    years,
    quantum_steepness,
    break_year,
    migration_start,
    migration_speed,
    vulnerable_share,
    strategy,
):
    """Compute quantum capability, migration progress, and risk curves."""
    strategy_cfg = strategy_effects(strategy)

    quantum = logistic_curve(years, midpoint=break_year, steepness=quantum_steepness)
    migration_midpoint = migration_start + strategy_cfg["friction_years"]
    migration_adj_speed = migration_speed * strategy_cfg["speed_multiplier"]
    migration = logistic_curve(
        years,
        midpoint=migration_midpoint,
        steepness=migration_adj_speed,
    )

    risk = compute_risk(quantum, migration, vulnerable_share)
    return quantum, migration, risk


def compute_risk(quantum, migration, vulnerable_share):
    """
    Baseline mismatch risk:
    risk(t) = quantum_capability(t) * (1 - migration_progress(t))
    Then scaled by the vulnerable funds share.
    """
    raw = quantum * (1.0 - migration)
    return np.clip(raw * vulnerable_share, 0.0, 1.0)


def first_year_reaching_threshold(years, series, threshold):
    """Return first year where series >= threshold, else None."""
    idx = np.where(series >= threshold)[0]
    if len(idx) == 0:
        return None
    return int(years[idx[0]])


def detect_critical_deadline(years, risk, quantum, migration, crisis_threshold):
    """
    Explainable deadline:
    1) First year risk breaches crisis threshold
    2) Fallback: first year where quantum exceeds migration by >0.20 while quantum >0.60
    """
    threshold_year = first_year_reaching_threshold(years, risk, crisis_threshold)
    if threshold_year is not None:
        return threshold_year, "Risk crosses crisis threshold"

    dangerous_margin_idx = np.where((quantum - migration > 0.20) & (quantum > 0.60))[0]
    if len(dangerous_margin_idx) > 0:
        return int(years[dangerous_margin_idx[0]]), "Quantum lead over migration becomes dangerous"

    return None, "No critical deadline detected in horizon"


def generate_verdict(peak_risk, critical_year, migration_50, quantum_50):
    """
    Decision-support verdict from risk magnitude and timing mismatch.
    """
    if peak_risk < 0.25 and critical_year is None:
        return "Safe for now"

    if critical_year is None and migration_50 is not None and quantum_50 is not None and migration_50 <= quantum_50:
        return "Manageable transition"

    if critical_year is not None and peak_risk < 0.45:
        return "High coordination risk"

    if quantum_50 is not None and migration_50 is not None and migration_50 > quantum_50 + 2:
        return "Crisis if delayed"

    return "Manageable transition"


def make_recommendation(scenario, verdict, critical_year, migration_50, quantum_50):
    """Short presentation-friendly recommendation."""
    if critical_year is not None:
        latest_start = max(2026, critical_year - 4)
        return (
            f"Under {scenario.lower()} assumptions, migration should begin by "
            f"{latest_start} to reduce crisis risk before {critical_year}."
        )

    if migration_50 is not None and quantum_50 is not None:
        if migration_50 <= quantum_50:
            return (
                f"Under {scenario.lower()} assumptions, current migration pace appears "
                "manageable if coordination remains strong."
            )
        return (
            f"Under {scenario.lower()} assumptions, migration timing should be pulled "
            f"forward to at least match quantum progress by {quantum_50}."
        )

    return f"Under {scenario.lower()} assumptions, continue monitoring and update assumptions annually."


def get_buffer_label(migration_50, quantum_50):
    """Return a compact buffer label for metric display."""
    if migration_50 is None or quantum_50 is None:
        return "N/A"
    diff = quantum_50 - migration_50
    if diff > 0:
        return f"Mig +{diff}yr"
    if diff < 0:
        return f"Quantum +{-diff}yr"
    return "Tied"


def run_scenario_comparison(years, strategy):
    """Run all three preset scenarios and return key metrics for comparison."""
    results = []
    for name in SCENARIOS:
        p = scenario_defaults(name)
        q, m, r = build_curves(
            years=years,
            quantum_steepness=p["quantum_steepness"],
            break_year=p["break_year"],
            migration_start=p["migration_start"],
            migration_speed=p["migration_speed"],
            vulnerable_share=p["vulnerable_share"],
            strategy=strategy,
        )
        crit, _ = detect_critical_deadline(years, r, q, m, p["crisis_threshold"])
        results.append({
            "scenario": name,
            "peak_risk": float(np.max(r)),
            "critical_year": crit,
            "migration_50": first_year_reaching_threshold(years, m, 0.5),
            "quantum_50": first_year_reaching_threshold(years, q, 0.5),
            "verdict": generate_verdict(
                float(np.max(r)), crit,
                first_year_reaching_threshold(years, m, 0.5),
                first_year_reaching_threshold(years, q, 0.5),
            ),
        })
    return results


def run_sensitivity_analysis(base_params, years, parameter_name, strategy):
    """
    Sweep one parameter and compute peak risk response.
    Returns x_values and peak_risks.
    """
    ranges = {
        "migration_start": np.arange(2028, 2041),
        "migration_speed": np.round(np.linspace(0.20, 0.80, 16), 2),
        "break_year": np.arange(2034, 2048),
        "vulnerable_share": np.round(np.linspace(0.40, 0.95, 12), 2),
    }

    x_vals = ranges[parameter_name]
    peak_vals = []

    for value in x_vals:
        params = dict(base_params)
        params[parameter_name] = float(value) if parameter_name in ("migration_speed", "vulnerable_share") else int(value)
        q, m, r = build_curves(
            years=years,
            quantum_steepness=params["quantum_steepness"],
            break_year=params["break_year"],
            migration_start=params["migration_start"],
            migration_speed=params["migration_speed"],
            vulnerable_share=params["vulnerable_share"],
            strategy=strategy,
        )
        _ = q, m  # explicit unused variables for readability
        peak_vals.append(float(np.max(r)))

    return x_vals, np.array(peak_vals)


def init_state():
    if "page" not in st.session_state:
        st.session_state["page"] = "home"
    if "scenario" not in st.session_state:
        st.session_state["scenario"] = "Moderate"
    if "params" not in st.session_state:
        st.session_state["params"] = scenario_defaults(st.session_state["scenario"]).copy()
    if "strategy" not in st.session_state:
        st.session_state["strategy"] = "Hybrid"


def apply_scenario_to_state(scenario):
    st.session_state["scenario"] = scenario
    st.session_state["params"] = scenario_defaults(scenario).copy()


def render_home():
    """Home / landing — clear hierarchy: pick a path, then reference tools."""
    st.markdown(
        """
        <div class="landing-wrap">
        <div class="landing-hero">
            <div class="landing-badge">Decision intelligence · Scenario modeling</div>
            <h1 class="landing-title">Bitcoin Quantum Threat Toolkit</h1>
            <p class="landing-subtitle">
                See how quantum progress and post-quantum migration can drift out of sync—then stress-test
                assumptions with charts, comparisons, and exports. Models illustrate scenarios, not predictions.
            </p>
            <div class="landing-meta">
                <span><strong>Interactive</strong> charts &amp; sensitivity</span>
                <span>·</span>
                <span><strong>Explainable</strong> deadlines &amp; verdicts</span>
                <span>·</span>
                <span><strong>Presentation-ready</strong> exports</span>
            </div>
        </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown('<div class="landing-section-title" style="margin-top:0.5rem;">Start here — pick one path</div>', unsafe_allow_html=True)
    hero_l, hero_r = st.columns(2)
    with hero_l:
        st.markdown(
            """
            <div class="landing-cta-pill landing-cta-pill-primary">
                <div class="landing-cta-kicker">Fast · Low friction</div>
                <p class="landing-cta-title">Quick Risk Check</p>
                <p class="landing-cta-desc">Four multiple-choice questions → an instant risk band. Best for a first read or a stakeholder snapshot.</p>
            </div>
            """,
            unsafe_allow_html=True,
        )
        if st.button("Start Quick Check", use_container_width=True, type="primary", key="nav_quick"):
            st.session_state["page"] = "quick_check"
            st.rerun()
    with hero_r:
        st.markdown(
            """
            <div class="landing-cta-pill">
                <div class="landing-cta-kicker">Deep dive</div>
                <p class="landing-cta-title">Risk Simulator</p>
                <p class="landing-cta-desc">Sliders, three scenario presets, Plotly charts, compare runs, sensitivity sweeps, and CSV export.</p>
            </div>
            """,
            unsafe_allow_html=True,
        )
        if st.button("Open Risk Simulator", use_container_width=True, key="nav_sim"):
            st.session_state["page"] = "simulator"
            st.rerun()

    st.markdown(
        """
        <div class="landing-wrap">
        <div class="landing-stats">
            <div class="landing-stat"><div class="landing-stat-num">3</div><div class="landing-stat-label">Scenario presets</div></div>
            <div class="landing-stat"><div class="landing-stat-num">30yr</div><div class="landing-stat-label">Horizon (2026–2055)</div></div>
            <div class="landing-stat"><div class="landing-stat-num">5</div><div class="landing-stat-label">Tools in this app</div></div>
        </div>
        <div class="landing-section-title">Reference &amp; context</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    def _tile(emoji, title, desc, ref=False):
        cls = "landing-tile landing-tile-ref" if ref else "landing-tile"
        return (
            f'<div class="{cls}"><div class="landing-tile-head">'
            f'<span class="emoji">{emoji}</span><span>{title}</span></div>'
            f'<p class="landing-tile-text">{desc}</p></div>'
        )

    n1, n2, n3 = st.columns(3)
    with n1:
        st.markdown(
            _tile(
                "📰",
                "News & updates",
                "Headlines and context on quantum hardware, NIST PQC, and Bitcoin migration discussions.",
                ref=True,
            ),
            unsafe_allow_html=True,
        )
        if st.button("Browse news", use_container_width=True, key="nav_news"):
            st.session_state["page"] = "news"
            st.rerun()
    with n2:
        st.markdown(
            _tile(
                "📖",
                "Glossary",
                "ECDSA, hash-based and lattice schemes, soft fork concepts—plus pointers to standards.",
                ref=True,
            ),
            unsafe_allow_html=True,
        )
        if st.button("Open glossary", use_container_width=True, key="nav_gloss"):
            st.session_state["page"] = "glossary"
            st.rerun()
    with n3:
        st.markdown(
            _tile(
                "📅",
                "Timeline",
                "Milestones in quantum computing and Bitcoin post-quantum exploration—past through projected.",
                ref=True,
            ),
            unsafe_allow_html=True,
        )
        if st.button("View timeline", use_container_width=True, key="nav_timeline"):
            st.session_state["page"] = "timeline"
            st.rerun()

    st.markdown(
        """
        <div class="landing-wrap">
        <div class="landing-workflow">
            <h4>Suggested workflow</h4>
            <ol>
                <li><strong style="color:#cbd5e1;">Orient</strong> — Quick Check or read News / Timeline for context.</li>
                <li><strong style="color:#cbd5e1;">Model</strong> — Risk Simulator on <strong style="color:#cbd5e1;">Moderate</strong> preset, then tune sliders.</li>
                <li><strong style="color:#cbd5e1;">Validate</strong> — Compare scenarios and Sensitivity tab; note any critical year.</li>
                <li><strong style="color:#cbd5e1;">Share</strong> — Export CSV for slides or documentation.</li>
            </ol>
        </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        """
        <div class="landing-wrap">
        <div class="landing-footer">
            <h4>Why this matters</h4>
            <p>
                Quantum computers could eventually threaten elliptic-curve signatures used widely today—including in Bitcoin.
                Post-quantum migration is a coordination and timing problem: this toolkit helps teams visualize mismatch risk,
                communicate trade-offs, and document assumptions for stakeholders—without claiming deterministic prediction.
            </p>
        </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_back_button():
    """Back to home — shown on all non-home pages."""
    if st.button("← Back to Home", key="back_home", use_container_width=False):
        st.session_state["page"] = "home"
        st.rerun()
    st.markdown("<br>", unsafe_allow_html=True)


def render_quick_check():
    """Simplified 4-question risk assessment."""
    render_back_button()
    st.title("Quick Risk Check")
    st.markdown("Answer four questions for an instant risk snapshot. No sliders required.")

    q1 = st.radio(
        "When do you expect quantum computers to reach 50% capability (break ECDSA)?",
        ["2040 or later (optimistic)", "2035–2040 (moderate)", "Before 2035 (pessimistic)"],
        key="qc1",
    )
    q2 = st.radio(
        "When do you expect Bitcoin migration to post-quantum to reach 50%?",
        ["By 2032 (early)", "2032–2040 (moderate)", "After 2040 or unclear (late)"],
        key="qc2",
    )
    q3 = st.radio(
        "What share of Bitcoin value do you consider at risk?",
        ["Under 60%", "60–80%", "Over 80%"],
        key="qc3",
    )
    q4 = st.radio(
        "How confident is ecosystem coordination on migration?",
        ["Strong — clear roadmap", "Moderate — some uncertainty", "Weak — fragmented"],
        key="qc4",
    )

    if st.button("Get assessment", type="primary", key="qc_submit"):
        score = 0
        if "2040 or later" in q1: score += 0
        elif "2035" in q1: score += 1
        else: score += 2
        if "By 2032" in q2: score += 0
        elif "2032–2040" in q2: score += 1
        else: score += 2
        if "Under 60" in q3: score += 0
        elif "60–80" in q3: score += 1
        else: score += 2
        if "Strong" in q4: score += 0
        elif "Moderate" in q4: score += 1
        else: score += 2

        if score <= 2:
            st.success("**Low risk** — Your assumptions suggest the race is manageable. Migration likely ahead of threat.")
            st.info("Consider using the full Simulator to stress-test different scenarios.")
        elif score <= 5:
            st.warning("**Moderate risk** — Some tension between quantum timelines and migration. Coordination is key.")
            st.info("Use the Simulator to see how pulling migration forward changes outcomes.")
        else:
            st.error("**High risk** — Quantum could outpace migration under your assumptions. Urgency is warranted.")
            st.info("Run the full Simulator with pessimistic presets to explore mitigation options.")

    if st.button("← Back to Home", key="qc_back"):
        st.session_state["page"] = "home"
        st.rerun()


def _strip_html(text):
    """Remove HTML tags and decode entities."""
    import re
    import html
    if not text:
        return ""
    text = re.sub(r"<[^>]+>", " ", str(text))
    return html.unescape(text).strip()


# Image URLs for News section (Wikimedia Commons, public domain / CC)
NEWS_IMAGES = {
    "quantum": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/IBM_Quantum_System_One.jpg/640px-IBM_Quantum_System_One.jpg",
    "nist": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/NIST_Campus_Main_Gate.jpg/640px-NIST_Campus_Main_Gate.jpg",
    "bitcoin": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/512px-Bitcoin.svg.png",
}


def render_news():
    """News & updates — real information with images and charts."""
    render_back_button()
    st.title("News & Updates")
    st.markdown("Current state of quantum computing, post-quantum cryptography, and Bitcoin migration.")

    # Overview with images and charts
    st.subheader("Overview")

    # 1. Quantum computing — image + text
    col_img, col_txt = st.columns([1, 2])
    with col_img:
        try:
            st.image(NEWS_IMAGES["quantum"], caption="IBM Quantum System One", use_container_width=True)
        except Exception:
            pass
    with col_txt:
        st.markdown(
            "**Quantum computing** — Progress is accelerating. Google's 2019 Sycamore demonstration showed "
            "quantum supremacy (53 qubits). IBM, IonQ, and others are scaling qubit counts into the hundreds. "
            "Current estimates suggest large-scale fault-tolerant machines capable of breaking ECDSA and RSA "
            "could arrive in the 2030s–2040s, though timelines are uncertain."
        )

    st.markdown("<br>", unsafe_allow_html=True)

    # 2. NIST PQC — image + text
    col_img2, col_txt2 = st.columns([1, 2])
    with col_img2:
        try:
            st.image(NEWS_IMAGES["nist"], caption="NIST campus", use_container_width=True)
        except Exception:
            pass
    with col_txt2:
        st.markdown(
            "**NIST post-quantum cryptography** — In **July 2022**, NIST selected algorithms for standardization "
            "(including CRYSTALS-Kyber and CRYSTALS-Dilithium, later ML-KEM / ML-DSA, and SPHINCS+-related SLH-DSA). "
            "In **August 2024**, NIST published **FIPS 203, 204, and 205** (ML-KEM, ML-DSA, SLH-DSA). "
            "Adoption in TLS and other systems is ongoing."
        )

    st.markdown("<br>", unsafe_allow_html=True)

    # 3. Bitcoin — image + text
    col_img3, col_txt3 = st.columns([1, 2])
    with col_img3:
        try:
            st.image(NEWS_IMAGES["bitcoin"], caption="Bitcoin", use_container_width=True)
        except Exception:
            pass
    with col_txt3:
        st.markdown(
            "**Bitcoin** — There is no network-wide post-quantum migration yet. Developers and researchers discuss "
            "post-quantum signatures and soft-fork trade-offs in public forums (e.g. Bitcoin dev mailing list, "
            "Bitcoin Optech newsletter). Hybrid schemes (ECDSA plus a post-quantum component) are often discussed; "
            "coordination would be required across the ecosystem."
        )

    # Chart: Quantum computing milestones (qubit progress)
    st.subheader("Quantum computing progress")
    fig_qc = go.Figure(layout=go.Layout(
        paper_bgcolor="#0a0f1a", plot_bgcolor="#0a0f1a", font=dict(color="#94a3b8"),
        title=dict(text="Key quantum computing milestones (log scale)", font=dict(color="#f1f5f9", size=14)),
        xaxis=dict(title="Year", gridcolor="rgba(71,85,105,0.3)"),
        yaxis=dict(title="Qubits (log scale)", type="log", gridcolor="rgba(71,85,105,0.3)"),
        height=320, margin=dict(t=40, b=40, l=50, r=20),
    ))
    fig_qc.add_trace(go.Scatter(x=[2019], y=[53], mode="markers+text", marker=dict(size=14, color="#38bdf8"), text="Sycamore", textposition="top center", name="Google"))
    fig_qc.add_trace(go.Scatter(x=[2021], y=[127], mode="markers+text", marker=dict(size=14, color="#4ade80"), text="Eagle", textposition="top center", name="IBM"))
    fig_qc.add_trace(go.Scatter(x=[2022], y=[433], mode="markers+text", marker=dict(size=14, color="#22d3ee"), text="Osprey", textposition="top center", name="IBM"))
    fig_qc.add_trace(go.Scatter(x=[2023], y=[1121], mode="markers+text", marker=dict(size=14, color="#a78bfa"), text="Condor", textposition="top center", name="IBM"))
    st.plotly_chart(fig_qc, use_container_width=True)
    st.caption(
        "Documented IBM/Google hardware announcements (physical qubit counts, not logical qubit counts). "
        "Breaking ECDSA in practice may require large-scale fault-tolerant machines—timing remains uncertain."
    )

    # Chart: The race — quantum vs migration
    st.subheader("The race: quantum threat vs migration")
    fig_race = go.Figure(layout=go.Layout(
        paper_bgcolor="#0a0f1a", plot_bgcolor="#0a0f1a", font=dict(color="#94a3b8"),
        title=dict(text="Conceptual timeline: when quantum may outpace Bitcoin migration", font=dict(color="#f1f5f9", size=14)),
        xaxis=dict(title="Year", range=[2020, 2050], gridcolor="rgba(71,85,105,0.3)"),
        yaxis=dict(title="Capability / Progress", range=[0, 1], gridcolor="rgba(71,85,105,0.3)"),
        height=320, margin=dict(t=40, b=40, l=50, r=20), legend=dict(orientation="h"),
    ))
    years = list(range(2020, 2051))
    quantum_curve = 1.0 / (1.0 + np.exp(-0.25 * (np.array(years) - 2038)))
    migration_early = 1.0 / (1.0 + np.exp(-0.35 * (np.array(years) - 2032)))
    migration_late = 1.0 / (1.0 + np.exp(-0.25 * (np.array(years) - 2040)))
    fig_race.add_trace(go.Scatter(x=years, y=quantum_curve, name="Quantum capability (est.)", line=dict(color="#38bdf8", width=2.5)))
    fig_race.add_trace(go.Scatter(x=years, y=migration_early, name="Migration (early)", line=dict(color="#4ade80", width=2, dash="dash")))
    fig_race.add_trace(go.Scatter(x=years, y=migration_late, name="Migration (late)", line=dict(color="#f87171", width=2, dash="dot")))
    st.plotly_chart(fig_race, use_container_width=True)
    st.caption("Early migration stays ahead of quantum; late migration risks a dangerous overlap.")

    st.divider()
    st.subheader("Recent Headlines & Summaries")
    try:
        import feedparser
        feeds = [
            ("https://cointelegraph.com/rss", "Crypto & Blockchain"),
            ("https://bitcoinmagazine.com/.feed", "Bitcoin"),
        ]
        for url, name in feeds:
            st.markdown(f"**{name}**")
            try:
                d = feedparser.parse(url, request_headers={"User-Agent": "Mozilla/5.0"})
                for e in d.entries[:4]:
                    title = e.get("title", "")
                    desc = e.get("summary", e.get("description", ""))
                    pub = e.get("published", "")[:10] if e.get("published") else ""
                    summary = _strip_html(desc)
                    if len(summary) > 400:
                        summary = summary[:397] + "..."
                    st.markdown(f"**{title}** {f'({pub})' if pub else ''}")
                    if summary:
                        st.markdown(f"> {summary}")
                    st.markdown("")
            except Exception as ex:
                st.caption(f"Unable to load feed: {ex}")
            st.markdown("")
    except ImportError:
        st.info("Install feedparser: `pip install feedparser` for live headlines and summaries.")

    if st.button("← Back to Home", key="news_back"):
        st.session_state["page"] = "home"
        st.rerun()


def render_glossary():
    """Glossary and resources."""
    render_back_button()
    st.title("Glossary & Resources")
    terms = [
        ("ECDSA", "Elliptic Curve Digital Signature Algorithm. Used by Bitcoin today. Vulnerable to sufficiently powerful quantum computers."),
        ("Post-quantum cryptography", "Cryptography designed to resist attacks from both classical and quantum computers."),
        ("SPHINCS+", "Stateless hash-based signature scheme. Conservative post-quantum option; larger signatures."),
        ("Lamport signatures", "One-time hash-based signatures. Simple but require new keys per signing."),
        ("Hybrid schemes", "Combine classical and post-quantum algorithms. Gradual migration path."),
        ("Quantum break year", "Year when quantum computers are estimated to reach ~50% capability to break current crypto."),
        ("Migration 50%", "Year when ~50% of Bitcoin value/users are estimated to have migrated to post-quantum."),
    ]
    for term, desc in terms:
        with st.expander(f"**{term}**"):
            st.markdown(desc)
    st.subheader("Resources")
    st.markdown("- [NIST PQC Project](https://csrc.nist.gov/projects/post-quantum-cryptography) — Post-quantum standardization")
    st.markdown("- [Bitcoin BIPs](https://github.com/bitcoin/bips) — Improvement proposals")
    st.markdown("- [Bitcoin Optech](https://bitcoinops.org/) — Protocol and scaling")
    if st.button("← Back to Home", key="gloss_back"):
        st.session_state["page"] = "home"
        st.rerun()


def render_timeline():
    """Visual timeline: documented public milestones plus app-specific model row."""
    render_back_button()
    st.title("Timeline")
    st.markdown(
        "Historical rows follow **documented** announcements and standards dates. "
        "The last row is **only** for this simulator—not a real-world prediction."
    )

    # Verified milestones (sources: Nature 2019; IBM/NIST press; Bitcoin consensus)
    events = [
        (2019, "Google quantum supremacy (Sycamore)", "quantum", "~53-qubit processor; Nature, 23 Oct 2019"),
        (2021, "IBM Eagle processor", "quantum", "127-qubit chip publicly announced"),
        (2021, "Bitcoin Taproot activation", "bitcoin", "Soft fork at block 709,632 (Nov 2021)"),
        (2022, "NIST PQC algorithm selection", "crypto", "Kyber, Dilithium, SPHINCS+ chosen for standardization (July 2022)"),
        (2022, "IBM Osprey processor", "quantum", "433-qubit processor announced (Nov 2022)"),
        (2023, "IBM Condor / System Two", "quantum", "1121-qubit processor announced (Dec 2023)"),
        (2024, "NIST FIPS post-quantum standards", "crypto", "FIPS 203 (ML-KEM), 204 (ML-DSA), 205 (SLH-DSA); Aug 2024"),
        (2026, "This simulator’s horizon start", "model", "App default window begins—not a forecast"),
    ]
    df = pd.DataFrame(events, columns=["Year", "Event", "Type", "Detail"])
    colors = {"quantum": "#38bdf8", "crypto": "#a78bfa", "bitcoin": "#4ade80", "model": "#f59e0b"}
    fig = go.Figure()
    for i, row in df.iterrows():
        y_off = (i % 3 - 1) * 0.15
        fig.add_trace(go.Scatter(
            x=[row["Year"]], y=[y_off],
            mode="markers+text",
            marker=dict(size=14, color=colors.get(row["Type"], "#94a3b8"), symbol="diamond", line=dict(width=2, color="white")),
            text=f"{int(row['Year'])}: {row['Event']}",
            textposition="top center",
            name=row["Type"],
            hovertemplate=f"<b>{row['Event']}</b><br>{row['Detail']}<extra></extra>",
        ))
    fig.update_layout(
        title="Quantum & Bitcoin PQC Timeline",
        xaxis=dict(title="Year", range=[2017, 2045], dtick=2),
        yaxis=dict(showticklabels=False, zeroline=False, range=[-0.4, 0.4]),
        paper_bgcolor="#0a0f1a", plot_bgcolor="#0a0f1a", font=dict(color="#94a3b8"),
        height=280, showlegend=False, margin=dict(t=40, b=40),
    )
    st.plotly_chart(fig, use_container_width=True)
    st.dataframe(df, hide_index=True, use_container_width=True, column_config={"Year": st.column_config.NumberColumn(format="%d")})
    st.caption(
        "Type: **quantum** = hardware announcements; **crypto** = NIST standardization; **bitcoin** = consensus change; "
        "**model** = in-app parameter only."
    )
    if st.button("← Back to Home", key="timeline_back"):
        st.session_state["page"] = "home"
        st.rerun()


def render_simulator():
    """Full risk simulator with charts and parameters."""
    render_back_button()
    st.title("Risk Simulator")
    st.markdown(
        '<div class="hero-card">'
        "Explore the timing race between quantum capability and Bitcoin migration. "
        "Adjust parameters below, scrub the chart by year, and compare scenarios in the tabs."
        "</div>",
        unsafe_allow_html=True,
    )

    # Parameters: moved from sidebar to expander
    with st.expander("⚙️ **Parameters** — Scenario presets and sliders", expanded=True):
        scenario_cols = st.columns(3)
        btn_labels = ("Opt", "Mod", "Pess")
        for i, sc in enumerate(SCENARIOS):
            with scenario_cols[i]:
                if st.button(btn_labels[i], key=f"scenario_{sc}", use_container_width=True, type="primary" if st.session_state["scenario"] == sc else "secondary"):
                    apply_scenario_to_state(sc)
                    st.rerun()
        st.caption("Optimistic · Moderate · Pessimistic")
        params = st.session_state["params"]
        c1, c2, c3 = st.columns(3)
        with c1:
            params["quantum_steepness"] = st.slider("Quantum steepness", 0.15, 0.80, float(params["quantum_steepness"]), 0.01, help="Acceleration of quantum capability growth")
            params["break_year"] = st.slider("Quantum break year (50%)", 2032, 2050, int(params["break_year"]), 1, help="Year quantum reaches 50% capability")
            params["migration_start"] = st.slider("Migration start year", 2026, 2050, int(params["migration_start"]), 1, help="Year migration reaches 50% midpoint")
        with c2:
            params["migration_speed"] = st.slider("Migration speed", 0.15, 0.90, float(params["migration_speed"]), 0.01)
            params["vulnerable_share"] = st.slider("Vulnerable share", 0.20, 1.00, float(params["vulnerable_share"]), 0.01, help="Share of funds at risk")
            params["crisis_threshold"] = st.slider("Crisis threshold", 0.10, 0.80, float(params["crisis_threshold"]), 0.01, help="Risk level that triggers critical deadline")
        with c3:
            strat_idx = list(STRATEGIES).index(st.session_state["strategy"]) if st.session_state["strategy"] in STRATEGIES else 2
            st.session_state["strategy"] = st.selectbox("Post-quantum strategy", STRATEGIES, index=strat_idx)
            strategy_notes = {"SPHINCS+": "Strong security, larger signatures.", "Lamport": "Simple, key management friction.", "Hybrid": "Current + PQ, smoother migration."}
            st.caption(strategy_notes.get(st.session_state["strategy"], ""))

    params = st.session_state["params"]
    strategy = st.session_state["strategy"]

    quantum, migration, risk = build_curves(
        years=YEARS,
        quantum_steepness=params["quantum_steepness"],
        break_year=params["break_year"],
        migration_start=params["migration_start"],
        migration_speed=params["migration_speed"],
        vulnerable_share=params["vulnerable_share"],
        strategy=strategy,
    )

    peak_risk = float(np.max(risk))
    critical_year, critical_reason = detect_critical_deadline(
        years=YEARS,
        risk=risk,
        quantum=quantum,
        migration=migration,
        crisis_threshold=params["crisis_threshold"],
    )
    migration_50 = first_year_reaching_threshold(YEARS, migration, 0.5)
    quantum_50 = first_year_reaching_threshold(YEARS, quantum, 0.5)
    verdict = generate_verdict(peak_risk, critical_year, migration_50, quantum_50)

    buffer_label = get_buffer_label(migration_50, quantum_50)
    recommendation = make_recommendation(
        scenario=st.session_state["scenario"],
        verdict=verdict,
        critical_year=critical_year,
        migration_50=migration_50,
        quantum_50=quantum_50,
    )

    # Flow: Metrics → Key insight → Chart
    m1, m2, m3, m4, m5, m6 = st.columns(6)
    m1.metric("Peak risk", f"{peak_risk:.2f}")
    m2.metric("Critical yr", str(critical_year) if critical_year else "—")
    m3.metric("Mig 50%", str(migration_50) if migration_50 else "—")
    m4.metric("Quantum 50%", str(quantum_50) if quantum_50 else "—")
    m5.metric("Buffer", buffer_label)
    m6.metric("Verdict", verdict)

    st.success(f"**{verdict}** — {recommendation}")

    # Chart controls: compact, one row
    scrub_year = st.slider("Scrub year to explore", int(YEARS[0]), int(YEARS[-1]), int(YEARS[len(YEARS)//2]), 1, key="scrub_year")
    opts = st.columns(5)
    with opts[0]: show_quantum = st.checkbox("Quantum", value=True, key="show_q")
    with opts[1]: show_migration = st.checkbox("Migration", value=True, key="show_m")
    with opts[2]: show_risk = st.checkbox("Risk", value=True, key="show_r")
    with opts[3]: show_danger = st.checkbox("Danger zone", value=True, key="show_danger")
    with opts[4]: show_critical = st.checkbox("Critical line", value=True, key="show_crit")
    idx_scrub = int(np.clip(np.searchsorted(YEARS, scrub_year), 0, len(YEARS) - 1))
    q_val, m_val, r_val = float(quantum[idx_scrub]), float(migration[idx_scrub]), float(risk[idx_scrub])

    # Main chart: Plotly interactive
    fig = go.Figure(layout=go.Layout(
        paper_bgcolor="#0a0f1a",
        plot_bgcolor="#0a0f1a",
        font=dict(color="#94a3b8", size=11),
        title=dict(text="Race Between Quantum Capability and Bitcoin Migration", font=dict(size=16, color="#f1f5f9")),
        xaxis=dict(title="Year", gridcolor="rgba(71, 85, 105, 0.3)", zeroline=False),
        yaxis=dict(title="Normalized value (0-1)", range=[0, 1], gridcolor="rgba(71, 85, 105, 0.3)", zeroline=False),
        hovermode="x unified",
        margin=dict(t=50, b=50, l=60, r=20),
        legend=dict(bgcolor="#111827", bordercolor="#334155", font=dict(color="#e2e8f0")),
    ))
    if show_quantum:
        fig.add_trace(go.Scatter(x=YEARS, y=quantum, name="Quantum capability", line=dict(color="#38bdf8", width=2.5), fill="tozeroy", fillcolor="rgba(56, 189, 248, 0.15)"))
    if show_migration:
        fig.add_trace(go.Scatter(x=YEARS, y=migration, name="Migration progress", line=dict(color="#4ade80", width=2.5), fill="tozeroy", fillcolor="rgba(74, 222, 128, 0.15)"))
    if show_risk:
        fig.add_trace(go.Scatter(x=YEARS, y=risk, name="Risk curve", line=dict(color="#f87171", width=3), fill="tozeroy", fillcolor="rgba(248, 113, 113, 0.2)"))
    if show_danger:
        fig.add_trace(go.Scatter(
            x=np.concatenate([YEARS, YEARS[::-1]]),
            y=np.concatenate([np.full_like(YEARS, params["crisis_threshold"]), np.ones_like(YEARS)]),
            fill="toself", fillcolor="rgba(248, 113, 113, 0.12)", line=dict(width=0), name="Danger zone",
        ))
        fig.add_hline(y=params["crisis_threshold"], line_dash="dash", line_color="#f87171", opacity=0.6, annotation_text="Crisis threshold")
    if show_critical and critical_year is not None:
        fig.add_vline(x=critical_year, line_dash="dot", line_color="#fcd34d", opacity=0.9, annotation_text=f"Critical: {critical_year}")
    # Scrubber marker: vertical line + points at selected year
    fig.add_vline(x=scrub_year, line_dash="dot", line_color="rgba(148, 163, 184, 0.5)", line_width=1)
    fig.add_trace(go.Scatter(x=[scrub_year], y=[q_val], mode="markers", marker=dict(symbol="diamond", size=12, color="#38bdf8", line=dict(width=2, color="white")), name=f"{scrub_year}", showlegend=False))
    fig.add_trace(go.Scatter(x=[scrub_year], y=[m_val], mode="markers", marker=dict(symbol="diamond", size=12, color="#4ade80", line=dict(width=2, color="white")), showlegend=False))
    fig.add_trace(go.Scatter(x=[scrub_year], y=[r_val], mode="markers", marker=dict(symbol="diamond", size=12, color="#f87171", line=dict(width=2, color="white")), showlegend=False))
    fig.update_xaxes(range=[YEARS[0], YEARS[-1]])
    st.plotly_chart(fig, use_container_width=True, config=dict(displayModeBar=True, displaylogo=False, modeBarButtonsToRemove=["lasso2d", "select2d"]))

    st.divider()

    # Deeper exploration: tabs for flow
    tab_overview, tab_compare, tab_sensitivity, tab_summary = st.tabs(["Chart Guide", "Compare", "Sensitivity", "Summary"])

    with tab_overview:
        st.markdown("**Quantum capability** — How close quantum computers are to breaking Bitcoin's ECDSA signatures (0 = no threat, 1 = full capability).")
        st.markdown("**Migration progress** — Share of the ecosystem that has moved to post-quantum cryptography.")
        st.markdown("**Risk curve** — Mismatch risk: high when quantum is ahead of migration.")
        st.markdown("**Crisis threshold** — Your risk limit; crossing it triggers a critical deadline.")
        st.info(f"Logic: {critical_reason}.")

    with tab_compare:
        comparison = run_scenario_comparison(YEARS, strategy)
        df = pd.DataFrame([
            {"Scenario": r["scenario"], "Peak risk": f"{r['peak_risk']:.2f}", "Critical year": r["critical_year"] or "—",
            "Migration 50%": r["migration_50"] or "—", "Quantum 50%": r["quantum_50"] or "—",
            "Buffer": get_buffer_label(r["migration_50"], r["quantum_50"]), "Verdict": r["verdict"]}
            for r in comparison
        ])
        st.dataframe(df, use_container_width=True, hide_index=True)
        st.caption("Preset defaults for each scenario with your current migration strategy.")

    with tab_sensitivity:
        sens_param = st.selectbox(
            "Parameter to sweep",
            ("migration_start", "migration_speed", "break_year", "vulnerable_share"),
            format_func=lambda x: x.replace("_", " ").title(),
        )
        x_vals, peak_vals = run_sensitivity_analysis(
            base_params=params,
            years=YEARS,
            parameter_name=sens_param,
            strategy=strategy,
        )
        fig2 = go.Figure(layout=go.Layout(
            paper_bgcolor="#0a0f1a",
            plot_bgcolor="#0a0f1a",
            font=dict(color="#94a3b8", size=11),
            title=dict(text=f"Peak Risk Sensitivity to {sens_param.replace('_', ' ').title()}", font=dict(size=16, color="#f1f5f9")),
            xaxis=dict(title=sens_param.replace("_", " ").title(), gridcolor="rgba(71, 85, 105, 0.3)", zeroline=False),
            yaxis=dict(title="Peak risk", range=[0, 1], gridcolor="rgba(71, 85, 105, 0.3)", zeroline=False),
            hovermode="x unified",
            margin=dict(t=50, b=50, l=60, r=20),
        ))
        fig2.add_trace(go.Scatter(
            x=x_vals, y=peak_vals, mode="lines+markers",
            line=dict(color="#a78bfa", width=2.5),
            marker=dict(size=10, color="#c4b5fd", line=dict(width=1, color="#7c3aed")),
            fill="tozeroy", fillcolor="rgba(167, 139, 250, 0.2)",
            hovertemplate="%{x}<br>Peak risk: %{y:.2f}<extra></extra>",
        ))
        st.plotly_chart(fig2, use_container_width=True, config=dict(displayModeBar=True, displaylogo=False))
        st.caption("Steep slopes = highly sensitive; flat regions = more robust to changes.")

    with tab_summary:
        st.markdown(f"**Recommendation:** {recommendation}")
        st.markdown(
            "**Assumptions** — Scenario model, not prediction. Conclusions depend on break-year timing, "
            "migration speed, and vulnerable share."
        )
        export_df = pd.DataFrame({
            "Year": YEARS, "Quantum capability": quantum, "Migration progress": migration, "Risk": risk,
        })
        st.download_button(
            label="Download curve data (CSV)",
            data=export_df.to_csv(index=False).encode("utf-8"),
            file_name=f"quantum_migration_curves_{st.session_state['scenario'].lower()}.csv",
            mime="text/csv",
        )
    if st.button("← Back to Home", key="sim_back"):
        st.session_state["page"] = "home"
        st.rerun()


def main():
    st.set_page_config(page_title="Bitcoin vs Quantum Threat Toolkit", layout="wide", initial_sidebar_state="collapsed")
    st.markdown(CUSTOM_CSS, unsafe_allow_html=True)
    init_state()

    # Main content — no sidebar, nav via home cards
    if st.session_state["page"] == "home":
        render_home()
    elif st.session_state["page"] == "simulator":
        render_simulator()
    elif st.session_state["page"] == "quick_check":
        render_quick_check()
    elif st.session_state["page"] == "news":
        render_news()
    elif st.session_state["page"] == "glossary":
        render_glossary()
    elif st.session_state["page"] == "timeline":
        render_timeline()


if __name__ == "__main__":
    main()
