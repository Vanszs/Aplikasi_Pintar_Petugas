-- MySQL dump 10.13  Distrib 8.0.42, for Linux (x86_64)
--
-- Host: localhost    Database: lapor_maling
-- ------------------------------------------------------
-- Server version	8.0.42-0ubuntu0.22.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `fcm_token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `session_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `session_start` datetime DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `role` enum('superadmin','admin1','admin2','petugas') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'admin1',
  `pending` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin`
--

LOCK TABLES `admin` WRITE;
/*!40000 ALTER TABLE `admin` DISABLE KEYS */;
INSERT INTO `admin` VALUES (1,'admin_kelurahan1','simokerto123','fPA93-bNQIOaEbb67zOdhu:APA91bGNZbknGro3HZO4Ps3qypLIL5JPm07fhm7Jn5Apj8tOm5fzW0Ry7VbznwUhZrVZShL1uZHGzU5MkIe_3emZxEzpo_JBRYo4ljUOTi2vWkE-DJsPp54','session_1752175486012_1','2025-07-11 04:24:46','Admin Simokerto','2025-07-02 14:21:23','superadmin',0),(5,'admin','admin123',NULL,NULL,NULL,'Bevantyo Satria Pinandhita','2025-07-05 04:54:07','admin1',0),(7,'bu_lurah','12345678',NULL,NULL,NULL,'Bu lurah','2025-07-07 04:47:54','superadmin',0),(10,'melisa_admin','12345678',NULL,'session_1752208250757_10','2025-07-11 13:30:51','Melisasa','2025-07-10 19:27:56','petugas',0),(13,'kapolsek_simokerto','12345678',NULL,NULL,NULL,'Didik Hermanto','2025-07-11 08:05:11','admin1',0),(14,'babinsa_simokerto','12345678',NULL,NULL,NULL,'Muthohar','2025-07-11 08:05:46','petugas',0),(15,'admin1','admin','fPA93-bNQIOaEbb67zOdhu:APA91bGNZbknGro3HZO4Ps3qypLIL5JPm07fhm7Jn5Apj8tOm5fzW0Ry7VbznwUhZrVZShL1uZHGzU5MkIe_3emZxEzpo_JBRYo4ljUOTi2vWkE-DJsPp54','session_1752255065897_15','2025-07-12 02:31:06','test','2025-07-11 14:18:52','admin1',0),(16,'admin2','admin',NULL,'session_1752254516984_16','2025-07-12 02:21:57','admin','2025-07-11 15:14:57','admin2',0);
/*!40000 ALTER TABLE `admin` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `message` text COLLATE utf8mb4_general_ci NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `user_role` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` varchar(32) COLLATE utf8mb4_general_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `pelapor` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `jenis_laporan` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `reporter_type` varchar(10) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'user',
  `status` varchar(20) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending',
  `isSirine` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=200 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reports`
--

LOCK TABLES `reports` WRITE;
/*!40000 ALTER TABLE `reports` DISABLE KEYS */;
INSERT INTO `reports` VALUES (1,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-01 12:45:07',NULL,NULL,'user','pending',0),(2,'2','Jl. Kenanga No.22, Sidoarjo','Laporan kejadian di Jl. Kenanga No.22, Sidoarjo','2025-07-01 12:45:07',NULL,NULL,'user','pending',0),(3,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 01:45:12',NULL,NULL,'user','pending',0),(4,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 01:47:44',NULL,NULL,'user','pending',0),(5,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 01:55:26',NULL,NULL,'user','pending',0),(6,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 01:55:50',NULL,NULL,'user','pending',0),(7,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 01:59:58',NULL,NULL,'user','pending',0),(8,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:04:15',NULL,NULL,'user','pending',0),(9,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:05:35',NULL,NULL,'user','pending',0),(10,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:09:46',NULL,NULL,'user','pending',0),(11,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:13:59',NULL,NULL,'user','pending',0),(12,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:14:42',NULL,NULL,'user','pending',0),(13,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:19:40',NULL,NULL,'user','pending',0),(14,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:21:09',NULL,NULL,'user','pending',0),(15,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:23:54',NULL,NULL,'user','pending',0),(16,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:26:35',NULL,NULL,'user','pending',0),(17,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:28:45',NULL,NULL,'user','pending',0),(18,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 02:39:47',NULL,NULL,'user','pending',0),(19,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:19:36',NULL,NULL,'user','pending',0),(20,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:21:28',NULL,NULL,'user','pending',0),(21,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:46:26',NULL,NULL,'user','pending',0),(22,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:46:36',NULL,NULL,'user','pending',0),(23,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:54:58',NULL,NULL,'user','pending',0),(24,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:57:40',NULL,NULL,'user','pending',0),(25,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 03:58:18',NULL,NULL,'user','pending',0),(26,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 04:00:26',NULL,NULL,'user','pending',0),(27,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 04:00:51',NULL,NULL,'user','pending',0),(28,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 04:02:54',NULL,NULL,'user','pending',0),(29,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 04:44:56',NULL,NULL,'user','pending',0),(30,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 04:53:29',NULL,NULL,'user','pending',0),(31,'2','Jl. Kenanga No.22, Sidoarjo','Laporan kejadian di Jl. Kenanga No.22, Sidoarjo','2025-07-02 05:18:17',NULL,NULL,'user','pending',0),(32,'2','Jl. Kenanga No.22, Sidoarjo','Laporan kejadian di Jl. Kenanga No.22, Sidoarjo','2025-07-02 06:01:56',NULL,NULL,'user','pending',0),(33,'2','Jl. Kenanga No.22, Sidoarjo','Laporan kejadian di Jl. Kenanga No.22, Sidoarjo','2025-07-02 06:12:03',NULL,NULL,'user','pending',0),(34,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 06:23:36',NULL,NULL,'user','pending',0),(35,'1','Jl. Melati No.10, Surabaya','Laporan kejadian di Jl. Melati No.10, Surabaya','2025-07-02 06:55:58',NULL,NULL,'user','pending',0),(37,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-04 06:36:35',NULL,NULL,'user','pending',0),(38,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-04 06:36:55',NULL,NULL,'user','pending',0),(39,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-05 08:31:57',NULL,NULL,'user','pending',0),(40,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-05 08:32:29',NULL,NULL,'user','pending',0),(45,'6','gapunya alamat',NULL,'2025-07-06 13:08:16',NULL,NULL,'user','pending',0),(46,'7','-',NULL,'2025-07-07 04:36:18',NULL,NULL,'user','pending',0),(47,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 03:04:09',NULL,NULL,'user','pending',0),(48,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 03:04:32',NULL,NULL,'user','pending',0),(49,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 03:04:48',NULL,NULL,'user','pending',0),(50,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 03:06:02',NULL,NULL,'user','pending',0),(51,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 03:14:15',NULL,NULL,'user','pending',0),(52,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 04:07:51',NULL,'kebakaran','user','pending',0),(53,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 04:08:10',NULL,'kemalingan','user','pending',0),(54,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 04:22:37',NULL,'kemalingan','user','pending',0),(55,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 04:22:58',NULL,'kemalingan','user','pending',0),(56,'1','wadawdwd RW 1',NULL,'2025-07-09 04:26:40',NULL,'kemalingan','user','pending',0),(57,'1','wdwqddwqdw RW 1',NULL,'2025-07-09 04:34:49',NULL,'kemalingan','user','pending',0),(58,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 04:53:30',NULL,'kemalingan','user','pending',0),(59,'1','awdwadawd RW 1',NULL,'2025-07-09 04:53:41',NULL,'tawuran','user','pending',0),(60,'1','jalan jalan RW 3',NULL,'2025-07-09 09:12:39',NULL,'kemalingan','user','pending',0),(61,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 10:08:45',NULL,'kebakaran','user','pending',0),(62,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 10:08:59',NULL,'kemalingan','user','pending',0),(63,'1','wqdqwddfds RW 3',NULL,'2025-07-09 10:09:14',NULL,'kemalingan','user','pending',0),(64,'1','wadawda RW 3',NULL,'2025-07-09 10:16:59',NULL,'kemalingan','user','pending',0),(65,'1','wdsadaw RW 3',NULL,'2025-07-09 10:26:37',NULL,'tawuran','user','pending',0),(66,'1','efef',NULL,'2025-07-09 14:02:51',NULL,'kemalingan','user','pending',0),(67,'1','ff',NULL,'2025-07-09 14:15:14',NULL,'kemalingan','user','pending',0),(68,'1','wdwd',NULL,'2025-07-09 14:21:34',NULL,'kemalingan','user','pending',0),(69,'1','fefe',NULL,'2025-07-09 15:10:04',NULL,'kemalingan','user','pending',0),(70,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 15:16:10',NULL,'tawuran','user','pending',0),(71,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 15:16:38',NULL,'jaguh','user','pending',0),(72,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-09 15:39:07',NULL,'jatuh','user','pending',0),(73,'1','esfef',NULL,'2025-07-09 15:44:22',NULL,'kemalingan','user','pending',0),(74,'1','efe',NULL,'2025-07-09 16:32:17',NULL,'kemalingan','admin','pending',0),(75,'1','fsefsef',NULL,'2025-07-09 16:32:50',NULL,'kemalingan','admin','pending',0),(76,'1','fgddgdf',NULL,'2025-07-09 16:35:54',NULL,'kemalingan','admin','pending',0),(77,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 17:11:59',NULL,'ngantuk','user','pending',0),(78,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 18:19:39',NULL,'kemalingan','user','pending',0),(79,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 18:20:04',NULL,'kebakaran','user','pending',0),(80,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-09 18:22:05',NULL,'kemalingan','user','pending',0),(81,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 01:46:42',NULL,'kemalingan','user','pending',0),(82,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 02:08:05',NULL,'kemalingan','user','pending',0),(83,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 02:08:20',NULL,'kemalingan','user','pending',0),(84,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 02:09:24',NULL,'kemalingan','user','pending',0),(85,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 02:10:14',NULL,'kemalingan','user','pending',0),(86,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 02:47:05',NULL,'kemalingan','user','pending',0),(87,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 04:24:39',NULL,'kemalingan','user','pending',0),(88,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 04:25:05',NULL,'kemalingan','user','pending',0),(89,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 04:59:47',NULL,'kemalingan','user','pending',0),(90,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:00:26',NULL,'kemalingan','user','pending',0),(91,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:00:44',NULL,'kemalingan','user','pending',0),(92,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:01:05',NULL,'kemalingan','user','pending',0),(93,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:01:18',NULL,'tawuran','user','pending',0),(94,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:01:42',NULL,'kebakaran','user','pending',0),(95,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:04:00',NULL,'kemalingan','user','pending',0),(96,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:13:01',NULL,'kemalingan','user','pending',0),(97,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:13:41',NULL,'kemalingan','user','pending',0),(98,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 05:13:53',NULL,'kemalingan','user','pending',0),(99,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:19:54',NULL,'kemalingan','user','pending',0),(100,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:58:12',NULL,'kemalingan','user','pending',0),(101,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:59:10',NULL,'kemalingan','user','pending',0),(102,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:59:23',NULL,'kemalingan','user','pending',0),(103,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:59:37',NULL,'kemalingan','user','pending',0),(104,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 12:59:49',NULL,'kemalingan','user','pending',0),(105,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:00:03',NULL,'kemalingan','user','pending',0),(106,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:00:27',NULL,'tawuran','user','pending',0),(107,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:00:42',NULL,'hmmm','user','pending',0),(108,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:06:16',NULL,'kemalingan','user','pending',0),(109,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:06:39',NULL,'tawuran','user','completed',0),(110,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 19:56:36',NULL,'kemalingan','user','pending',0),(111,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 19:56:51',NULL,'kemalingan','user','pending',0),(112,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 19:57:20',NULL,'kemalingan','user','pending',0),(113,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:14:27',NULL,'kemalingan','user','pending',0),(114,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:20:03',NULL,'kemalingan','user','pending',0),(115,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:20:54',NULL,'kebakaran','user','pending',0),(116,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:21:27',NULL,'kemalingan','user','pending',0),(117,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 13:21:54',NULL,'kemalingan','user','pending',0),(118,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:22:59',NULL,'kemalingan','user','pending',0),(119,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:23:09',NULL,'tawuran','user','pending',0),(120,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:25:40',NULL,'kemalingan','user','pending',0),(121,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:26:12',NULL,'kemalingan','user','pending',0),(122,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:26:34',NULL,'kemalingan','user','pending',0),(123,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-10 20:29:29',NULL,'kemalingan','user','pending',0),(124,'9','surabaya',NULL,'2025-07-10 20:34:25',NULL,'kemalingan','user','pending',0),(125,'9','surabaya',NULL,'2025-07-10 22:03:40',NULL,'tawuran','user','pending',0),(126,'9','surabaya',NULL,'2025-07-10 22:04:02',NULL,'kebakaran','user','pending',0),(127,'9','surabaya',NULL,'2025-07-10 22:04:13',NULL,'kemalingan','user','pending',0),(128,'9','surabaya',NULL,'2025-07-10 22:04:53',NULL,'kemalingan','user','pending',0),(129,'9','surabaya',NULL,'2025-07-10 22:05:04',NULL,'kemalingan','user','pending',0),(130,'9','surabaya',NULL,'2025-07-10 22:05:25',NULL,'kemalingan','user','pending',0),(131,'9','surabaya',NULL,'2025-07-10 23:09:03',NULL,'kemalingan','user','pending',0),(132,'9','surabaya',NULL,'2025-07-10 23:09:25',NULL,'kemalingan','user','pending',0),(133,'9','surabaya',NULL,'2025-07-10 23:22:25',NULL,'kemalingan','user','pending',0),(134,'9','surabaya',NULL,'2025-07-10 23:22:42',NULL,'kemalingan','user','pending',0),(135,'9','surabaya',NULL,'2025-07-10 23:25:18',NULL,'kemalingan','user','pending',0),(136,'9','surabaya',NULL,'2025-07-10 23:26:01',NULL,'kemalingan','user','pending',0),(137,'9','surabaya',NULL,'2025-07-10 23:27:04',NULL,'kemalingan','user','pending',0),(138,'9','surabaya',NULL,'2025-07-10 23:30:04',NULL,'kemalingan','user','pending',0),(139,'9','surabaya',NULL,'2025-07-10 23:47:29',NULL,'kemalingan','user','pending',0),(140,'9','surabaya',NULL,'2025-07-10 23:48:03',NULL,'kemalingan','user','pending',0),(141,'9','surabaya',NULL,'2025-07-10 23:48:16',NULL,'kemalingan','user','pending',0),(142,'9','surabaya',NULL,'2025-07-10 23:51:21',NULL,'kemalingan','user','pending',0),(143,'9','surabaya',NULL,'2025-07-10 23:56:18',NULL,'kemalingan','user','pending',0),(144,'9','surabaya',NULL,'2025-07-11 00:10:42',NULL,'kemalingan','user','pending',0),(145,'9','surabaya',NULL,'2025-07-11 00:12:10',NULL,'kemalingan','user','pending',0),(146,'9','surabaya',NULL,'2025-07-11 00:12:30',NULL,'kemalingan','user','pending',0),(147,'9','surabaya',NULL,'2025-07-11 00:19:56',NULL,'kemalingan','user','pending',0),(148,'9','surabaya',NULL,'2025-07-11 00:37:14',NULL,'kemalingan','user','pending',0),(149,'9','surabaya',NULL,'2025-07-11 00:37:42',NULL,'kemalingan','user','pending',0),(150,'2','rggdr',NULL,'2025-07-11 00:55:14',NULL,'kemalingan','admin','pending',0),(151,'9','surabaya',NULL,'2025-07-11 00:57:32',NULL,'kemalingan','user','pending',0),(152,'9','surabaya',NULL,'2025-07-11 00:57:51',NULL,'kemalingan','user','pending',0),(153,'9','surabaya',NULL,'2025-07-11 00:58:15',NULL,'kemalingan','user','pending',0),(154,'9','surabaya',NULL,'2025-07-11 00:59:50',NULL,'kemalingan','user','pending',0),(155,'2','efefe',NULL,'2025-07-11 01:08:25',NULL,'kemalingan','admin','pending',0),(156,'9','surabaya',NULL,'2025-07-11 01:09:53',NULL,'kemalingan','user','pending',0),(157,'9','surabaya',NULL,'2025-07-11 01:11:39',NULL,'kemalingan','user','pending',0),(158,'9','surabaya',NULL,'2025-07-11 01:22:41',NULL,'kemalingan','user','pending',0),(159,'9','surabaya',NULL,'2025-07-11 01:53:56',NULL,'kemalingan','user','pending',0),(160,'9','surabaya',NULL,'2025-07-11 01:56:05',NULL,'kemalingan','user','pending',0),(161,'9','surabaya',NULL,'2025-07-11 01:56:50',NULL,'kemalingan','user','pending',0),(162,'9','surabaya',NULL,'2025-07-11 02:07:02',NULL,'kemalingan','user','pending',0),(163,'9','surabaya',NULL,'2025-07-11 02:07:26',NULL,'tawuran','user','pending',0),(164,'9','surabaya',NULL,'2025-07-11 02:07:59',NULL,'kemalingan','user','pending',0),(165,'9','surabaya',NULL,'2025-07-11 02:08:36',NULL,'wkwje','user','pending',0),(166,'9','surabaya',NULL,'2025-07-11 02:08:53',NULL,'kemalingan','user','pending',0),(167,'9','surabaya',NULL,'2025-07-11 02:09:37',NULL,'kemalingan','user','pending',0),(168,'9','surabaya',NULL,'2025-07-11 02:09:55',NULL,'kemalingan','user','pending',0),(169,'9','surabaya',NULL,'2025-07-11 02:10:10',NULL,'tawuran','user','pending',0),(170,'9','surabaya',NULL,'2025-07-11 02:10:34',NULL,'kemalingan','user','pending',0),(171,'9','surabaya',NULL,'2025-07-11 02:14:01',NULL,'kemalingan','user','pending',0),(172,'9','surabaya',NULL,'2025-07-11 02:20:14',NULL,'kemalingan','user','pending',0),(173,'9','surabaya',NULL,'2025-07-11 02:21:26',NULL,'kemalingan','user','pending',0),(174,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:22:14',NULL,'kemalingan','user','pending',0),(175,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:22:46',NULL,'kemalingan','user','pending',0),(176,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:23:02',NULL,'kemalingan','user','pending',0),(177,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:25:14',NULL,'kemalingan','user','pending',0),(178,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:25:32',NULL,'tawuran','user','pending',0),(179,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:25:53',NULL,'kemalingan','user','pending',0),(180,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:26:33',NULL,'kemalingan','user','pending',0),(181,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:28:43',NULL,'kemalingan','user','pending',0),(182,'9','surabaya',NULL,'2025-07-11 02:29:22',NULL,'kemalingan','user','pending',0),(183,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 02:30:01',NULL,'tawuran','user','pending',0),(184,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 10:39:59',NULL,'kemalingan','user','pending',0),(185,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 11:23:55',NULL,'kemalingan','user','pending',0),(186,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 11:30:30',NULL,'kemalingan','user','pending',0),(187,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 11:31:08',NULL,'kemalingan','user','pending',0),(188,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 11:34:02',NULL,'WOI MELLLL, MASUK KAN','user','pending',0),(189,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 14:19:25',NULL,'kemalingan','user','pending',0),(190,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 15:03:21',NULL,'kemalingan','user','pending',0),(191,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 16:47:51',NULL,'kemalingan','user','pending',0),(193,'Admin/Petugas','dfgdgf',NULL,'2025-07-11 23:26:23',NULL,'kemalingan','admin','pending',1),(194,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-11 23:42:16',NULL,'kemalingan','user','pending',0),(195,'Admin/Petugas','hh',NULL,'2025-07-12 00:18:02',NULL,'kemalingan','admin','pending',0),(196,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 15:53:58',NULL,'kemalingan','user','pending',0),(197,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 15:54:33',NULL,'kemalingan','user','pending',0),(198,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 15:54:38',NULL,'kemalingan','user','pending',0),(199,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 15:55:21',NULL,'kemalingan','user','pending',0);
/*!40000 ALTER TABLE `reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'user1','pass1','Siti Aminah','Jl. Melati No.10, Surabaya','2025-07-01 12:45:07',NULL),(2,'user2','pass2','Budi Santoso','Jl. Kenanga No.22, Sidoarjo','2025-07-01 12:45:07',NULL),(3,'warga3','123456','Rina Wija','Jl. Anggrek No.5, Gresik','2025-07-01 12:45:07',NULL),(6,'melisa','1234567890','Meylisa Elvioraa','gapunya alamat','2025-07-06 07:02:56',NULL),(7,'bu_lurah','12345678','Bu lurah','-','2025-07-07 04:35:18',NULL),(8,'warga4','pass4','Vanszs','rw 3 rt 1','2025-07-09 15:57:08',NULL),(9,'warga5','pass5','vannn satria','surabaya','2025-07-10 13:33:47','085381568989'),(11,'yuliaimut','avriskalucu','yuliaaaaaaaaaa','gatau plis','2025-07-11 04:12:31','-'),(12,'irfinnstay','fanelek23','irfan romadhon :v','warlok','2025-07-11 04:14:44','-');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-12 12:32:32
