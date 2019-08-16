-- MySQL dump 10.13  Distrib 5.7.27, for Linux (x86_64)
--
-- Host: localhost    Database: novonordisk
-- ------------------------------------------------------
-- Server version	5.7.27-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `complex_component`
--

DROP TABLE IF EXISTS `complex_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `complex_component` (
  `complex_portal_accession` varchar(15) NOT NULL,
  `uniprot_acc` varchar(10) NOT NULL,
  KEY `fk_complex_component_protein1_idx` (`uniprot_acc`),
  KEY `fk_complex_component_complex_portal1_idx` (`complex_portal_accession`),
  CONSTRAINT `fk_complex_component_complex_portal1` FOREIGN KEY (`complex_portal_accession`) REFERENCES `complex_portal` (`complex_portal_accession`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_complex_component_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `complex_portal`
--

DROP TABLE IF EXISTS `complex_portal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `complex_portal` (
  `complex_portal_accession` varchar(15) NOT NULL,
  `description` text NOT NULL,
  `number_proteins` int(11) NOT NULL,
  PRIMARY KEY (`complex_portal_accession`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ensembl_transcript`
--

DROP TABLE IF EXISTS `ensembl_transcript`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ensembl_transcript` (
  `uniprot_acc` varchar(10) NOT NULL,
  `uniprot_isoform` varchar(45) DEFAULT NULL,
  `ensembl_transcript_acc` varchar(45) DEFAULT NULL,
  KEY `fk_ensembl_transcript_protein_idx` (`uniprot_acc`),
  CONSTRAINT `fk_ensembl_transcript_protein` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gene_ontology`
--

DROP TABLE IF EXISTS `gene_ontology`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gene_ontology` (
  `uniprot_acc` varchar(10) NOT NULL,
  `go_id` varchar(45) NOT NULL,
  `go_class` enum('CC','BP','MF') NOT NULL,
  `go_name` text NOT NULL,
  KEY `fk_gene_ontology_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_gene_ontology_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `interpro`
--

DROP TABLE IF EXISTS `interpro`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `interpro` (
  `interpro_acc` varchar(9) NOT NULL,
  `ipr_type` enum('Family','Domain','Repeat','conserved site','Homologous Superfamily','active site','binding site','PTM site') NOT NULL,
  `short_name` text NOT NULL,
  `num_matches` int(11) NOT NULL DEFAULT '0',
  `child_interpro_acc` varchar(9) DEFAULT NULL,
  `checked` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`interpro_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `interpro_match`
--

DROP TABLE IF EXISTS `interpro_match`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `interpro_match` (
  `interpro_acc` varchar(9) NOT NULL,
  `uniprot_acc` varchar(10) NOT NULL,
  `start` int(11) NOT NULL,
  `end` int(11) NOT NULL,
  KEY `fk_interpro_match_interpro1_idx` (`interpro_acc`),
  KEY `fk_interpro_match_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_interpro_match_interpro1` FOREIGN KEY (`interpro_acc`) REFERENCES `interpro` (`interpro_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_interpro_match_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kegg`
--

DROP TABLE IF EXISTS `kegg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kegg` (
  `kegg_pathway_id` varchar(20) NOT NULL,
  `description` text NOT NULL,
  `number_steps` int(11) NOT NULL,
  `kegg_disease` text,
  PRIMARY KEY (`kegg_pathway_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kegg_step`
--

DROP TABLE IF EXISTS `kegg_step`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kegg_step` (
  `kegg_pathway_id` varchar(20) NOT NULL,
  `uniprot_acc` varchar(10) NOT NULL,
  `kegg_protein` varchar(45) DEFAULT NULL,
  `kegg_gene` varchar(45) DEFAULT NULL,
  `kegg_protein_desc` text,
  KEY `fk_kegg_step_kegg1_idx` (`kegg_pathway_id`),
  KEY `fk_kegg_step_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_kegg_step_kegg1` FOREIGN KEY (`kegg_pathway_id`) REFERENCES `kegg` (`kegg_pathway_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_kegg_step_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ortholog`
--

DROP TABLE IF EXISTS `ortholog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ortholog` (
  `uniprot_acc` varchar(10) NOT NULL,
  `ortholog_uniprot_acc` varchar(10) NOT NULL,
  `species` int(11) NOT NULL,
  UNIQUE KEY `otholog_accs` (`uniprot_acc`,`ortholog_uniprot_acc`),
  KEY `fk_ortholog_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_ortholog_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pdb`
--

DROP TABLE IF EXISTS `pdb`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pdb` (
  `uniprot_acc` varchar(10) NOT NULL,
  `pdb_id` varchar(4) NOT NULL,
  `chain` varchar(4) NOT NULL,
  KEY `fk_pdb_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_pdb_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `protein`
--

DROP TABLE IF EXISTS `protein`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `protein` (
  `uniprot_acc` varchar(10) NOT NULL,
  `uniprot_id` varchar(45) NOT NULL,
  `reviewed` int(11) NOT NULL DEFAULT '0',
  `gene_name` text NOT NULL,
  `description` text NOT NULL,
  `species` text NOT NULL,
  `ensembl_gene` text,
  `complex_portal_xref` text,
  `reactome_xref` text,
  `kegg_xref` text,
  `secreted` int(11) NOT NULL DEFAULT '0',
  `proteome` text,
  PRIMARY KEY (`uniprot_acc`),
  UNIQUE KEY `uniprot_id_UNIQUE` (`uniprot_id`),
  UNIQUE KEY `uniprot_acc_UNIQUE` (`uniprot_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reactome`
--

DROP TABLE IF EXISTS `reactome`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reactome` (
  `pathway_id` varchar(20) NOT NULL,
  `description` text CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `number_steps` int(11) DEFAULT NULL,
  `species` text,
  PRIMARY KEY (`pathway_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reactome_step`
--

DROP TABLE IF EXISTS `reactome_step`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reactome_step` (
  `pathway_id` varchar(20) NOT NULL,
  `uniprot_acc` varchar(10) NOT NULL,
  `reaction_id` varchar(20) DEFAULT NULL,
  `reaction_description` text,
  UNIQUE KEY `unique_id_acc` (`pathway_id`,`uniprot_acc`),
  KEY `fk_table1_reactome1_idx` (`pathway_id`),
  KEY `fk_table1_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_table1_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_table1_reactome1` FOREIGN KEY (`pathway_id`) REFERENCES `reactome` (`pathway_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `target`
--

DROP TABLE IF EXISTS `target`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `target` (
  `uniprot_acc` varchar(10) NOT NULL,
  `source` text NOT NULL,
  `disease` text,
  `efo_id` text,
  `target_type` text,
  `proteome` varchar(45) DEFAULT NULL,
  KEY `fk_target_protein1_idx` (`uniprot_acc`),
  CONSTRAINT `fk_target_protein1` FOREIGN KEY (`uniprot_acc`) REFERENCES `protein` (`uniprot_acc`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `versions`
--

DROP TABLE IF EXISTS `versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `versions` (
  `resource` text,
  `version` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-07-30  9:15:11
