"""Check that source URL suffixes do not control the selected parser."""

import gzip
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class GpiSourceExtensionTest(unittest.TestCase):
    def test_gpi2_gzip_source(self):
        filename = "c_elegans.PRJNA13758.WS298.gene_product_info.gpi2.gz"
        source = (
            "https://ftp.ebi.ac.uk/pub/databases/wormbase/releases/WS298/"
            "species/c_elegans/PRJNA13758/annotation/" + filename
        )
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            metadata = work / "datasets.json"
            metadata.write_text(json.dumps([{
                "dataset": "wb", "type": "gpi", "compression": "gzip",
                "species_code": "Cele", "source": source,
            }]))
            result = subprocess.run(
                ["python3", str(ROOT / "build-neo-makefile.py"), "-i", str(metadata)],
                text=True, capture_output=True, check=True,
            )
            self.assertEqual(result.stderr, "")
            self.assertIn(source, result.stdout)
            self.assertIn(f"target/neo-wb.ofn: mirror/{filename}\n", result.stdout)
            recipe = next(line.strip() for line in result.stdout.splitlines()
                          if "gzip -dc" in line)
            self.assertIn("./gpi2ofn.pl -s Cele -n wb", recipe)

            # Execute the generated conversion recipe using a local fixture.
            (work / "mirror").mkdir()
            (work / "target").mkdir()
            for name in ("gpi2ofn.pl", "prefixes.ofn.txt"):
                (work / name).symlink_to(ROOT / name)
            with gzip.open(work / "mirror" / filename, "wt") as stream:
                stream.write("!gpi-version: 2.0\n" + "\t".join([
                    "WB:WBGene00000001", "aap-1", "", "", "PR:000000001",
                    "NCBITaxon:6239", "", "", "", "UniProtKB:G5EDP9", "",
                ]) + "\n")
            conversion = subprocess.run(
                ["bash", "-o", "pipefail", "-c", recipe.replace("$@", "target/neo-wb.ofn")],
                cwd=work, text=True, capture_output=True, check=True,
            )
            self.assertEqual(conversion.stderr, "")
            output = (work / "target/neo-wb.ofn").read_text()
            self.assertIn("Declaration(Class(WB:WBGene00000001))", output)
            self.assertIn("SubClassOf(WB:WBGene00000001 PR:000000001)", output)


if __name__ == "__main__":
    unittest.main()
