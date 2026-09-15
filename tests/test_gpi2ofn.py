"""Offline regression checks for GPI 1.2 and 2.0 conversion."""

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class GpiConversionTest(unittest.TestCase):
    def convert(self, version, rows):
        result = subprocess.run(
            ["perl", "gpi2ofn.pl", "-s", "Cele", "-n", "wb"],
            cwd=ROOT,
            input=f"!gpi-version: {version}\n"
            + "".join("\t".join(row) + "\n" for row in rows),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stderr, "")
        return result.stdout

    def test_wormbase_gpi_2(self):
        # First data row of the WS298 C. elegans GPI 2.0 release.
        output = self.convert("2.0", [[
            "WB:WBGene00000001", "aap-1",
            "phosphoinositide kinase AdAPter subunit", "CELE_Y110A7A.10",
            "PR:000000001", "NCBITaxon:6239", "", "", "",
            "UniProtKB:G5EDP9", "",
        ]])
        for axiom in [
            'Declaration(Class(WB:WBGene00000001))',
            'AnnotationAssertion(rdfs:label WB:WBGene00000001 "aap-1 Cele")',
            'AnnotationAssertion(oboInOwl:hasExactSynonym WB:WBGene00000001 "phosphoinositide kinase AdAPter subunit Cele")',
            'AnnotationAssertion(oboInOwl:hasRelatedSynonym WB:WBGene00000001 "CELE_Y110A7A.10")',
            'AnnotationAssertion(oboInOwl:hasRelatedSynonym WB:WBGene00000001 "G5EDP9")',
            'AnnotationAssertion(oboInOwl:hasDbXref WB:WBGene00000001 "UniProtKB:G5EDP9")',
            'AnnotationAssertion(biolink:category WB:WBGene00000001 biolink:Protein)',
            'SubClassOf(WB:WBGene00000001 PR:000000001)',
            'SubClassOf(WB:WBGene00000001 ObjectSomeValuesFrom(obo:RO_0002162 NCBITaxon:6239))',
        ]:
            self.assertIn(axiom, output)
        self.assertNotIn('CHEBI:33695)', output)

    def test_gpi_2_relationship_columns_and_multiple_types(self):
        output = self.convert("2.0", [[
            "WB:complex", "complex", "", "", "GO:0032991|GO:1990391",
            "NCBITaxon:6239", "WB:gene1|WB:gene2", "UniProtKB:canonical",
            "UniProtKB:member1|UniProtKB:member2",
            "UniProtKB:xref|RNAcentral:URS1", "db-subset=test",
        ]])
        self.assertIn('SubClassOf(WB:complex GO:0032991)', output)
        self.assertIn('SubClassOf(WB:complex GO:1990391)', output)
        self.assertIn('AnnotationAssertion(biolink:category WB:complex biolink:MacromolecularComplex)', output)
        self.assertIn('SubClassOf(WB:complex ObjectSomeValuesFrom(neo:has_gene_template WB:gene1))', output)
        self.assertIn('SubClassOf(WB:complex ObjectSomeValuesFrom(neo:has_gene_template WB:gene2))', output)
        self.assertIn('AnnotationAssertion(oboInOwl:hasDbXref WB:complex "UniProtKB:xref")', output)
        self.assertIn('AnnotationAssertion(oboInOwl:hasDbXref WB:complex "RNAcentral:URS1")', output)
        self.assertNotIn('UniProtKB:canonical', output)
        self.assertNotIn('UniProtKB:member', output)
        self.assertNotIn('db-subset=test', output)

    def test_gpi_2_sequence_ontology_types(self):
        for entity_type in ("SO:0000655", "SO:0001035", "SO:0000336", "SO:0001217"):
            with self.subTest(entity_type=entity_type):
                output = self.convert("2.0", [[
                    "WB:entity", "entity", "", "", entity_type,
                    "NCBITaxon:6239", "", "", "", "", "",
                ]])
                self.assertIn('Prefix(SO:=<http://purl.obolibrary.org/obo/SO_>)', output)
                self.assertIn(f'SubClassOf(WB:entity {entity_type})', output)
                self.assertNotIn('CHEBI:33695)', output)

    def test_malformed_version_header_is_rejected(self):
        # GPI_Header requires one literal space after the colon. Invalid
        # headers must not silently select the default GPI 1.2 column layout.
        row = [
            "ZFIN:ZDB-GENE-100519-4", "aldh1l1", "aldehyde dehydrogenase",
            "FDH", "SO:0001217", "NCBITaxon:7955", "",
            "ZFIN:ZDB-GENE-100519-4", "", "UniProtKB:E3NZ06", "",
        ]
        for header in (
            "!gpi-version:2.0", "!gpi-version:  2.0",
            "!gpi-version:\t2.0", "!gpi-version: 2.0 ",
        ):
            with self.subTest(header=header):
                result = subprocess.run(
                    ["perl", "gpi2ofn.pl", "-s", "Drer", "-n", "zfin"],
                    cwd=ROOT,
                    input=header + "\n" + "\t".join(row) + "\n",
                    text=True,
                    capture_output=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Invalid GPI version header on line 1", result.stderr)
                self.assertNotIn("Declaration(Class(", result.stdout)

    def test_gpi_1_2_legacy_mapping(self):
        for entity_type, parent_type, category in (
            ("protein", "CHEBI:36080", "Protein"),
            ("transcript", "CHEBI:33697", "RNAProduct"),
            ("protein_complex", "GO:0032991", "MacromolecularComplex"),
            ("gene", "CHEBI:33695", "GeneProduct"),
        ):
            with self.subTest(entity_type=entity_type):
                output = self.convert("1.2", [[
                    "WB", "entity", "entity", "Full entity name", "alias", entity_type,
                    "taxon:6239", "WB:gene1|WB:gene2", "UniProtKB:xref", "",
                ]])
                self.assertIn(f'SubClassOf(WB:entity {parent_type})', output)
                self.assertIn('AnnotationAssertion(oboInOwl:hasExactSynonym WB:entity "Full entity name Cele")', output)
                self.assertIn(f'AnnotationAssertion(biolink:category WB:entity biolink:{category})', output)
                self.assertIn('AnnotationAssertion(oboInOwl:hasDbXref WB:entity "UniProtKB:xref")', output)
                self.assertIn('SubClassOf(WB:entity ObjectSomeValuesFrom(obo:RO_0002162 NCBITaxon:6239))', output)
                self.assertIn('SubClassOf(WB:entity ObjectSomeValuesFrom(neo:has_gene_template WB:gene1))', output)
                self.assertIn('SubClassOf(WB:entity ObjectSomeValuesFrom(neo:has_gene_template WB:gene2))', output)


if __name__ == "__main__":
    unittest.main()
