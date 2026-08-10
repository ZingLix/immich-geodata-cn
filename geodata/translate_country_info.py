import argparse
import json
from pathlib import Path


DEFAULT_TRANSLATIONS = (
    Path(__file__).resolve().parent.parent
    / "i18n-iso-countries"
    / "langs"
    / "zh.json"
)


def translate_country_info(input_path, output_path, translations_path):
    with Path(translations_path).open(encoding="utf-8") as translations_file:
        translations = json.load(translations_file)["countries"]

    translated_count = 0
    with Path(input_path).open(encoding="utf-8", newline="") as input_file, Path(
        output_path
    ).open("w", encoding="utf-8", newline="") as output_file:
        for line_number, line in enumerate(input_file, start=1):
            if line.startswith("#") or not line.strip():
                output_file.write(line)
                continue

            if line.endswith("\r\n"):
                newline = "\r\n"
            elif line.endswith("\n"):
                newline = "\n"
            else:
                newline = ""
            fields = line.removesuffix(newline).split("\t")
            if len(fields) < 5:
                raise ValueError(
                    f"Invalid countryInfo.txt row at line {line_number}: expected at least 5 columns"
                )

            translated_name = translations.get(fields[0])
            if translated_name:
                fields[4] = translated_name
                translated_count += 1

            output_file.write("\t".join(fields) + newline)

    return translated_count


def main():
    parser = argparse.ArgumentParser(
        description="Translate country names in GeoNames countryInfo.txt."
    )
    parser.add_argument("--input", required=True, help="Input countryInfo.txt path")
    parser.add_argument("--output", required=True, help="Output countryInfo.txt path")
    parser.add_argument(
        "--translations",
        default=DEFAULT_TRANSLATIONS,
        help="i18n-iso-countries locale JSON used as the country-name mapping",
    )
    args = parser.parse_args()

    translated_count = translate_country_info(
        args.input, args.output, args.translations
    )
    print(f"Translated {translated_count} country names into {args.output}")


if __name__ == "__main__":
    main()
