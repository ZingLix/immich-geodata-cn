import json
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from translate_country_info import translate_country_info  # noqa: E402


class TranslateCountryInfoTest(unittest.TestCase):
    def test_translates_country_column_and_preserves_other_content(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            input_path = temp_path / "input.txt"
            output_path = temp_path / "output.txt"
            translations_path = temp_path / "zh.json"

            input_path.write_bytes(
                b"#ISO\tISO3\tISO-Numeric\tfips\tCountry\r\n"
                b"CN\tCHN\t156\tCH\tChina\tBeijing\r\n"
                b"AN\tANT\t530\tNT\tNetherlands Antilles\tWillemstad\r\n"
            )
            translations_path.write_text(
                json.dumps({"countries": {"CN": "\u4e2d\u56fd"}}), encoding="utf-8"
            )

            translated_count = translate_country_info(
                input_path, output_path, translations_path
            )

            self.assertEqual(translated_count, 1)
            self.assertEqual(
                output_path.read_bytes(),
                b"#ISO\tISO3\tISO-Numeric\tfips\tCountry\r\n"
                b"CN\tCHN\t156\tCH\t\xe4\xb8\xad\xe5\x9b\xbd\tBeijing\r\n"
                b"AN\tANT\t530\tNT\tNetherlands Antilles\tWillemstad\r\n",
            )


if __name__ == "__main__":
    unittest.main()
