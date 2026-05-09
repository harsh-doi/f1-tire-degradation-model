import fastf1
import pandas as pd
import os

# ══════════════════════════════════════════════════════════════════════
#  CONFIGURATION — only change these four lines
# ══════════════════════════════════════════════════════════════════════
YEAR    = 2026
RACE    = 'Miami'
SESSION = 'R'           # 'R' = Race, 'Q' = Qualifying, 'FP1/FP2/FP3'
DRIVER  = 'VER'         # 3-letter driver code
# ══════════════════════════════════════════════════════════════════════

# ── Setup ─────────────────────────────────────────────────────────────
output_dir = f'data/{YEAR}_{RACE}_{DRIVER}'
os.makedirs(output_dir, exist_ok=True)
os.makedirs('f1_cache',  exist_ok=True)
fastf1.Cache.enable_cache('f1_cache')

# ── Load session ──────────────────────────────────────────────────────
print(f"Loading {YEAR} {RACE} GP — {DRIVER}...")
print("First run may take 2–3 minutes (downloading from F1 servers)\n")

session = fastf1.get_session(YEAR, RACE, SESSION)
session.load(telemetry=True, weather=True, messages=False)

# ── Get driver laps ───────────────────────────────────────────────────
all_laps = session.laps.pick_driver(DRIVER)

stints      = sorted(all_laps['Stint'].dropna().unique().astype(int))
n_stints    = len(stints)

print(f"Driver     : {DRIVER}")
print(f"Total laps : {len(all_laps)}")
print(f"Stints     : {n_stints}")
print()

# ── Loop over every stint ─────────────────────────────────────────────
for stint_num in stints:

    stint_laps = all_laps[all_laps['Stint'] == stint_num].copy()
    compound   = stint_laps['Compound'].iloc[0]
    n_laps     = len(stint_laps)

    print(f"── Stint {stint_num} : {n_laps} laps on {compound} ──")

    # ── Lap table ────────────────────────────────────────────────────
    lap_table = stint_laps[[
        'LapNumber', 'LapTime', 'TyreLife',
        'Compound',  'Stint',   'TrackStatus'
    ]].copy()

    lap_table['LapTime_s'] = lap_table['LapTime'].dt.total_seconds()

    # Drop laps with no valid time (outlap, red flag etc.)
    lap_table = lap_table.dropna(subset=['LapTime_s'])

    fname_lap = f'{output_dir}/stint_{stint_num}_{compound}_laps.csv'
    lap_table.to_csv(fname_lap, index=False)
    print(f"  Saved {fname_lap} — {len(lap_table)} valid laps")
    print(f"  Lap times: {lap_table['LapTime_s'].min():.2f}s "
          f"— {lap_table['LapTime_s'].max():.2f}s")

    # ── Speed trace (fastest valid lap of this stint) ────────────────
    try:
        fastest_lap = stint_laps.pick_fastest()
        telemetry   = fastest_lap.get_telemetry()

        # Keep only the columns we need for MATLAB
        cols_wanted = ['Time','Speed','Throttle','Brake','nGear','RPM','DRS']
        cols_available = [c for c in cols_wanted if c in telemetry.columns]
        speed_trace = telemetry[cols_available].copy()

        # Convert timedelta to milliseconds (MATLAB-friendly float)
        speed_trace['Time'] = speed_trace['Time'].dt.total_seconds() * 1000

        fname_trace = f'{output_dir}/stint_{stint_num}_{compound}_trace.csv'
        speed_trace.to_csv(fname_trace, index=False)

        print(f"  Saved {fname_trace} — {len(speed_trace)} telemetry points")
        print(f"  Lap duration : {speed_trace['Time'].iloc[-1]/1000:.1f}s")
        print(f"  Top speed    : {speed_trace['Speed'].max():.1f} km/h")

    except Exception as e:
        print(f"  WARNING: Could not extract telemetry for stint {stint_num} — {e}")

    print()

# ── Weather (one file for the whole race) ─────────────────────────────
weather = session.weather_data.copy()

cols_weather = ['Time','AirTemp','TrackTemp','Humidity','WindSpeed','Rainfall']
cols_available = [c for c in cols_weather if c in weather.columns]
weather_out = weather[cols_available].copy()
weather_out['Time'] = weather_out['Time'].dt.total_seconds()

fname_weather = f'{output_dir}/weather.csv'
weather_out.to_csv(fname_weather, index=False)

print(f"Saved {fname_weather}")
print(f"  Air temp   : {weather_out['AirTemp'].median():.1f} C")
print(f"  Track temp : {weather_out['TrackTemp'].median():.1f} C")
print(f"  Rainfall   : {'Yes' if weather_out['Rainfall'].any() else 'No'}")

# ── Master index file (tells MATLAB what stints exist) ────────────────
index_rows = []
for stint_num in stints:
    stint_laps = all_laps[all_laps['Stint'] == stint_num].copy()
    compound   = stint_laps['Compound'].iloc[0]
    n_laps     = len(stint_laps.dropna(subset=['LapTime']))
    index_rows.append({
        'Stint'    : stint_num,
        'Compound' : compound,
        'NumLaps'  : n_laps,
        'LapFile'  : f'stint_{stint_num}_{compound}_laps.csv',
        'TraceFile': f'stint_{stint_num}_{compound}_trace.csv',
    })

index_df = pd.DataFrame(index_rows)
fname_index = f'{output_dir}/index.csv'
index_df.to_csv(fname_index, index=False)

print(f"\nSaved {fname_index}")
print(index_df.to_string(index=False))

# ── Final summary ─────────────────────────────────────────────────────
print("\n" + "="*55)
print("EXTRACTION COMPLETE")
print("="*55)
print(f"All files saved to: {output_dir}/")
print(f"  {n_stints} stint lap file(s)")
print(f"  {n_stints} stint telemetry trace(s)")
print(f"  1 weather file")
print(f"  1 index file  ← MATLAB reads this first")
