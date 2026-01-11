import re
from pathlib import Path
from typing import Dict

import pandas as pd

TIME_COL = "Step time"
AMPLITUDE_SHEET = "Amplitude sweep - 1"
AMP_COLS_TO_EXTRACT = ["Oscillation strain", "Angular frequency"]

SHEET_NAMES = [
    "Sine Strain - 2",
    "Sine Strain - 3",
    "Sine Strain - 4",
    "Sine Strain - 5",
    "Sine Strain - 6",
    "Sine Strain - 7",  # Liquifies
    # "Sine Strain - 8",
    # "Sine Strain - 9",
    # "Sine Strain - 10",  # TJC2_23A2.xls: Worksheet named 'Sine Strain - 10' not found
]

TREATMENT_MAP = {"A": "NegCon", "B": "pSTAT", "C": "pSCRAM"}

COLS_TO_KEEP = [
    "Step time",
    "Stress",
    "Strain",
    "Shear rate",
    "Angular frequency",
    "Oscillation strain",
]


def standardize_time(df: pd.DataFrame) -> pd.DataFrame:
    """Normalizes the time column so it starts at 0."""
    if TIME_COL not in df.columns or df.empty:
        return df

    # Subtract initial time from all rows
    t0 = df[TIME_COL].iloc[0]
    df[TIME_COL] = df[TIME_COL] - t0
    return df


def extract_metadata(subfolder: str, filename: str) -> dict:
    """Extracts Species/Subject and Treatment from folder and filenames."""
    # 1. Subject extraction (Using subfolder name)
    subject = subfolder

    # 2. Treatment extraction via regex
    treatment_match = re.search(r"_\d+([ABC])(\d+)\.", filename)
    if not treatment_match:
        treatment = "Unknown"
    else:
        treatment_code = treatment_match.group(1)
        treatment = TREATMENT_MAP.get(treatment_code, "Unknown")

    return {
        "Subject": subject,
        "Treatment": treatment,
        "Experiment": Path(filename).stem,  # Removes extension
    }


def get_amplitude_params(sheet_dfs: Dict[str, pd.DataFrame]) -> Dict[str, Dict]:
    """
    Reads the Amplitude sheet to find the frequency/strain for other sheets.
    Returns a dict like: {'Sine Strain - 2': {'Oscillation strain': 1.0, ...}}
    """
    param_map = {}

    if AMPLITUDE_SHEET not in sheet_dfs:
        return param_map

    amp_df = sheet_dfs[AMPLITUDE_SHEET]
    if amp_df is None or amp_df.empty:
        return param_map

    # Iterate through expected sheets and map them to rows in the Amplitude sheet
    for idx, target_sheet_name in enumerate(SHEET_NAMES):
        if idx < len(amp_df):
            try:
                vals = {
                    "Oscillation strain": amp_df.iloc[idx].get("Oscillation strain"),
                    "Angular frequency": amp_df.iloc[idx].get("Angular frequency"),
                }
                param_map[target_sheet_name] = vals
            except Exception:
                continue
    return param_map


def process_single_file(file_path: Path, output_folder: Path):
    """
    Reads one file, processes it, and saves it to the output folder.
    """
    subfolder = file_path.parent.name
    filename = file_path.name
    target_sheets = set(SHEET_NAMES + [AMPLITUDE_SHEET])

    try:
        with pd.ExcelFile(file_path) as xls:
            available_sheets = set(xls.sheet_names)
            sheets_to_load = list(target_sheets.intersection(available_sheets))

            if not sheets_to_load:
                return

            sheet_dfs = pd.read_excel(
                xls,
                header=1,
                skiprows=[2],
                sheet_name=sheets_to_load,
            )

        meta = extract_metadata(subfolder, filename)
        new_filename = f"{meta['Subject']}_{meta['Treatment']}_{meta['Experiment']}.xlsx"
        new_filename = re.sub(r'[<>:"/\\|?*]', "", new_filename)
        output_path = output_folder / new_filename

        file_param_map = get_amplitude_params(sheet_dfs)

        # --- NEW: order sheets by oscillation strain (low -> high) ---
        sheet_rank = {name: i for i, name in enumerate(SHEET_NAMES)}

        def strain_sort_key(sheet_name: str):
            strain = file_param_map.get(sheet_name, {}).get("Oscillation strain")
            # Missing/NaN strains go last; tie-break by original SHEET_NAMES order
            if strain is None or pd.isna(strain):
                return (float("inf"), sheet_rank.get(sheet_name, 9999))
            return (float(strain), sheet_rank.get(sheet_name, 9999))

        sheets_to_write = [
            s for s in SHEET_NAMES
            if s in sheet_dfs and sheet_dfs[s] is not None and not sheet_dfs[s].empty
        ]
        sheets_to_write.sort(key=strain_sort_key)
        # -------------------------------------------------------------

        sheets_written = 0

        with pd.ExcelWriter(output_path, engine="xlsxwriter") as writer:
            # --- CHANGED: iterate in sorted order, not dict order ---
            for sheet_name in sheets_to_write:
                df = sheet_dfs[sheet_name]

                params = file_param_map.get(sheet_name, {})

                raw_osc = params.get("Oscillation strain")
                raw_freq = params.get("Angular frequency")

                osc_strain = (
                    float(raw_osc) * 100
                    if raw_osc is not None and not pd.isna(raw_osc)
                    else None
                )
                ang_freq = (
                    float(raw_freq)
                    if raw_freq is not None and not pd.isna(raw_freq)
                    else None
                )

                df["Oscillation strain"] = osc_strain
                df["Angular frequency"] = ang_freq

                df = standardize_time(df)

                cols_to_write = [c for c in COLS_TO_KEEP if c in df.columns]
                final_df = df[cols_to_write]

                if ang_freq is not None and osc_strain is not None:
                    new_sheet_name = f"{round(ang_freq, 2)}rad - {round(osc_strain, 2)}%"
                else:
                    new_sheet_name = sheet_name

                if len(new_sheet_name) > 31:
                    new_sheet_name = new_sheet_name[:31]

                final_df.to_excel(writer, sheet_name=new_sheet_name, index=False)
                sheets_written += 1

        if sheets_written > 0:
            print(f"Saved: {new_filename}")
        else:
            if output_path.exists():
                output_path.unlink()

    except Exception as e:
        print(f"Error processing {filename}: {e}")


def process_all_files(input_dir: str, output_dir: str):
    """
    Main entry point: finds files and delegates to process_single_file.
    """
    input_folder = Path(input_dir)
    output_folder = Path(output_dir)

    if not input_folder.exists():
        print(f"Error: Input folder not found: {input_folder}")
        return

    # Ensure output directory exists
    output_folder.mkdir(parents=True, exist_ok=True)

    # Find all Excel files recursively
    excel_files = list(input_folder.rglob("*.xls*"))

    if not excel_files:
        print("No Excel files found.")
        return

    print(f"Found {len(excel_files)} files in {input_folder}. Processing...")

    for file_path in excel_files:
        process_single_file(file_path, output_folder)

    print("Done.")


# --- Execution ---
if __name__ == "__main__":
    # Adjust paths here
    process_all_files(
        input_dir=r"G:\My Drive\PunLab\MFNN\data\raw",
        output_dir=r"G:\My Drive\PunLab\MFNN\data\processed",
    )
