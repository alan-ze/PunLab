import pandas as pd

from spp.preprocess import extract_columns_to_csv


def test_extract_columns_to_csv_creates_files(tmp_path):
    excel_path = tmp_path / "test.xlsx"

    # Actual data
    df = pd.DataFrame(
        {
            "Step time": [1, 2],
            "Strain (step)": [0.1, 0.2],
            "Shear rate": [5, 6],
            "Stress (step)": [10, 12],
        }
    )

    with pd.ExcelWriter(excel_path, engine="xlsxwriter") as writer:
        for sheet in ["Sheet1", "Sheet2"]:
            worksheet = writer.book.add_worksheet(sheet)
            writer.sheets[sheet] = worksheet

            # Row 0: metadata / junk
            worksheet.write_row(0, 0, ["Metadata", "", "", ""])

            # Row 1: column headers
            worksheet.write_row(1, 0, df.columns.tolist())

            # Row 2: units / junk row
            worksheet.write_row(2, 0, ["s", "-", "1/s", "Pa"])

            # Row 3+: actual data
            for i, row in df.iterrows():
                worksheet.write_row(3 + i, 0, row.tolist())

    output_dir = tmp_path / "output"
    output_dir.mkdir()

    created_files = extract_columns_to_csv(excel_path, output_dir)

    # Assertions
    assert len(created_files) == 2
    for file in created_files:
        assert file.endswith(".csv")
        assert (output_dir / file.split("/")[-1]).exists()
