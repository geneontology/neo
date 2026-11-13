"""Offline regression checks for GAF conversion."""

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


def gaf_row(db, object_id, isoform=""):
    # First data row of the Arabidopsis GOEx GAF, reduced to the columns used.
    return [
        db, object_id, "NAC001", "enables", "GO:0000976", "PMID:30356219",
        "IPI", "AGI_LocusCode:AT2G38290", "F",
        "NAC domain-containing protein 1", "At1g01010|NAC001", "protein",
        "taxon:3702", "20201218", "TAIR", "", isoform,
    ]


class GafConversionTest(unittest.TestCase):
    def convert(self, rows):
        result = subprocess.run(
            ["perl", "gaf2ofn.pl", "-s", "Atal", "-n", "tair"],
            cwd=ROOT,
            input="!gaf-version: 2.2\n"
            + "".join("\t".join(row) + "\n" for row in rows),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        return result.stdout

    def body(self, output):
        # Everything after the fixed prefix/ontology header.
        return output[output.index("Declaration(Class("):]

    def test_agi_locuscode_db_column(self):
        output = self.convert([gaf_row("AGI_LocusCode", "AT1G01010")])
        for axiom in [
            'Declaration(Class(AGI_LocusCode:AT1G01010))',
            'AnnotationAssertion(rdfs:label AGI_LocusCode:AT1G01010 "NAC001 Atal")',
            'AnnotationAssertion(oboInOwl:id AGI_LocusCode:AT1G01010 "AGI_LocusCode:AT1G01010")',
            'SubClassOf(AGI_LocusCode:AT1G01010 CHEBI:33695)',
            'SubClassOf(AGI_LocusCode:AT1G01010 ObjectSomeValuesFrom(obo:RO_0002162 NCBITaxon:3702))',
        ]:
            self.assertIn(axiom, output)

    def test_tair_db_column_gives_same_output_as_agi_locuscode(self):
        # GOEx-pipeline#20: "TAIR" in the DB column must not change the IDs.
        good = self.convert([gaf_row("AGI_LocusCode", "AT1G01010",
                                     "AGI_LocusCode:AT1G01010")])
        bad = self.convert([gaf_row("TAIR", "AT1G01010", "TAIR:AT1G01010")])
        self.assertEqual(self.body(bad), self.body(good))
        self.assertNotIn("TAIR:", self.body(bad))

    def test_tair_locus_ids_keep_their_own_prefix(self):
        output = self.convert([gaf_row("TAIR", "locus:2200935")])
        self.assertIn('Declaration(Class(TAIR_locus:2200935))', output)
        self.assertNotIn('AGI_LocusCode', self.body(output))

    def test_every_class_prefix_is_declared(self):
        output = self.convert([
            gaf_row("TAIR", "AT1G01010"),
            gaf_row("AGI_LocusCode", "AT1G01020"),
            gaf_row("TAIR", "locus:2200935"),
        ])
        declared = {line.split("(")[1].split("=")[0]
                    for line in output.splitlines() if line.startswith("Prefix(")}
        used = {line[len("Declaration(Class("):].split(":")[0] + ":"
                for line in output.splitlines()
                if line.startswith("Declaration(Class(")}
        self.assertEqual(used - declared, set())


if __name__ == "__main__":
    unittest.main()
