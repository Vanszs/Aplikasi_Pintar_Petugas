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
  `address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
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
INSERT INTO `admin` VALUES (1,'admin_kelurahan1','simokerto123','fPA93-bNQIOaEbb67zOdhu:APA91bGNZbknGro3HZO4Ps3qypLIL5JPm07fhm7Jn5Apj8tOm5fzW0Ry7VbznwUhZrVZShL1uZHGzU5MkIe_3emZxEzpo_JBRYo4ljUOTi2vWkE-DJsPp54','session_1752175486012_1','2025-07-11 04:24:46','Admin Simokerto','2025-07-02 14:21:23','superadmin',0),(5,'admin','admin123',NULL,NULL,NULL,'Bevantyo Satria Pinandhita','2025-07-05 04:54:07','admin1',0),(7,'bu_lurah','12345678',NULL,NULL,NULL,'Bu lurah','2025-07-07 04:47:54','superadmin',0),(10,'melisa_admin','12345678',NULL,'session_1752208250757_10','2025-07-11 13:30:51','Melisasa','2025-07-10 19:27:56','petugas',0),(13,'kapolsek_simokerto','12345678',NULL,NULL,NULL,'Didik Hermanto','2025-07-11 08:05:11','admin1',0),(14,'babinsa_simokerto','12345678',NULL,NULL,NULL,'Muthohar','2025-07-11 08:05:46','petugas',0),(15,'admin1','admin','eM0zyusxRGawGGQlQsPgta:APA91bELaEhvLGG88ySolVea2H3heYTGV_OscDzgBdejEZ06DI2MI2wLVrhgzP-nLY0vePIQTFtqF0opzdhkOHQJYh3FiN1UOmyLAzFqkVj0IPP3KRuVUZo','session_1752579511818_15','2025-07-15 13:38:32','test','2025-07-11 14:18:52','admin1',0),(16,'admin2','admin',NULL,'session_1752254516984_16','2025-07-12 02:21:57','admin','2025-07-11 15:14:57','admin2',0);
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
  `phone` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=251 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reports`
--

LOCK TABLES `reports` WRITE;
/*!40000 ALTER TABLE `reports` DISABLE KEYS */;
INSERT INTO `reports` VALUES (206,'15','maksidid',NULL,'2025-07-12 18:50:50',NULL,'kemalingan','admin','pending',0,'8454343'),(207,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 11:55:58',NULL,'kemalingan','user','pending',0,'-'),(208,'15','fgre',NULL,'2025-07-12 11:59:00',NULL,'kemalingan','admin','pending',1,'576567'),(209,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 12:29:06',NULL,'kebakaran','user','pending',0,'-'),(210,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 12:38:08',NULL,'kemalingan','user','pending',1,'-'),(211,'1','dgdgrdgrg RW 1',NULL,'2025-07-12 12:38:32',NULL,'kemalingan','user','pending',1,'-'),(212,'1','Disnaa RW 1',NULL,'2025-07-12 12:57:36',NULL,'kemalingan','user','pending',1,'-'),(213,'1','hajsis RW 3',NULL,'2025-07-12 13:00:59',NULL,'kebakaran','user','pending',0,'-'),(214,'1','hshshs RW 3',NULL,'2025-07-12 13:01:11',NULL,'kemalingan','user','pending',1,'-'),(215,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-12 13:01:21',NULL,'kemalingan','user','pending',0,'-'),(216,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 07:48:37',NULL,'tawuran','user','pending',0,'-'),(217,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 07:49:59',NULL,'kemalingan','user','pending',0,'-'),(218,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 07:50:09',NULL,'kemalingan','user','pending',1,'-'),(219,'1','bsjsjs RW 3',NULL,'2025-07-13 07:50:23',NULL,'kemalingan','user','completed',1,'-'),(220,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 08:43:31',NULL,'kemalingan','user','pending',0,'-'),(221,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 09:32:27',NULL,'kemalingan','user','pending',0,'-'),(222,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 10:05:26',NULL,'kemalingan','user','pending',0,'-'),(223,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-13 10:15:13',NULL,'kemalingan','user','pending',0,'-'),(224,'1','jwaijwz RW 3',NULL,'2025-07-13 10:37:39',NULL,'kemalingan','user','pending',0,'-'),(225,'1','jjajs RW 3',NULL,'2025-07-13 10:37:54',NULL,'kemalingan','user','pending',1,'-'),(226,'1','bsns RW 3',NULL,'2025-07-13 10:39:02',NULL,'kemalingan','user','pending',0,'-'),(227,'1','jsisks RW 3',NULL,'2025-07-13 10:39:56',NULL,'kemalingan','user','pending',1,'-'),(228,'1','jsjsjs RW 3',NULL,'2025-07-13 10:41:16',NULL,'kebakaran','user','pending',1,'-'),(229,'1','ushjs RW 3',NULL,'2025-07-13 10:59:05',NULL,'kebakaran','user','pending',1,'-'),(230,'1','bshs RW 3',NULL,'2025-07-13 10:59:30',NULL,'kemalingan','user','pending',1,'-'),(231,'1','ugguv RW 13',NULL,'2025-07-13 12:51:39',NULL,'kemalingan','user','pending',1,'-'),(232,'1','jdjxjd RW 3',NULL,'2025-07-13 12:53:05',NULL,'kemalingan','user','pending',1,'-'),(233,'1','kenjeran 1 RW 3',NULL,'2025-07-14 04:32:29',NULL,'ditemukan orang meninggal','user','pending',1,'-'),(234,'1','iUOAAOSDI RW 3',NULL,'2025-07-14 04:33:39',NULL,'kebakaran','user','pending',1,'-'),(235,'1','bshs RW 3',NULL,'2025-07-14 04:46:26',NULL,'kemalingan','user','pending',1,'-'),(236,'1','bbsbs RW 3',NULL,'2025-07-14 04:47:14',NULL,'tawuran','user','pending',1,'-'),(237,'1','hshshs RW 3',NULL,'2025-07-14 04:48:02',NULL,'kebakaran','user','pending',1,'-'),(238,'1','jdjd RW 3',NULL,'2025-07-14 04:48:43',NULL,'kebakaran','user','pending',1,'-'),(239,'1','Simokerto RW 3',NULL,'2025-07-14 04:57:45',NULL,'kebakaran','user','pending',1,'-'),(240,'1','ADIYDu RW 3',NULL,'2025-07-14 04:59:36',NULL,'kemalingan','user','pending',1,'-'),(241,'1','simokerto RW 3',NULL,'2025-07-14 05:11:36',NULL,'kemalingan','user','pending',1,'-'),(242,'12','warlok',NULL,'2025-07-14 09:27:21',NULL,'lainnya','user','pending',0,'-'),(243,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-14 09:28:51',NULL,'lainnya','user','pending',0,'-'),(244,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-14 09:58:11',NULL,'kemalingan','user','pending',0,'-'),(245,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-14 09:59:41',NULL,'kemalingan','user','pending',0,'-'),(246,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-15 04:20:34',NULL,'kemalingan','user','pending',0,'-'),(247,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-15 04:20:43',NULL,'kemalingan','user','pending',0,'-'),(248,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-15 04:20:54',NULL,'kemalingan','user','pending',0,'-'),(249,'2','Jl. Kenanga No.22, Sidoarjo',NULL,'2025-07-15 04:24:45',NULL,'kemalingan','user','pending',0,'-'),(250,'1','Jl. Melati No.10, Surabaya',NULL,'2025-07-15 11:10:24',NULL,'kemalingan','user','completed',0,'-');
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
  `fcm_token` text COLLATE utf8mb4_general_ci,
  `session_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `session_start` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'user1','pass1','Siti Aminahhhhh','Jl. Melati No.10, Surabaya','2025-07-01 12:45:07','085381568989',NULL,NULL,NULL),(2,'user2','pass2','Budi Santoso','Jl. Kenanga No.22, Sidoarjo','2025-07-01 12:45:07',NULL,NULL,NULL,NULL),(3,'warga3','123456','Rina Wija','Jl. Anggrek No.5, Gresik','2025-07-01 12:45:07',NULL,NULL,NULL,NULL),(6,'melisa','1234567890','Meylisa Elvioraa','gapunya alamat','2025-07-06 07:02:56',NULL,NULL,NULL,NULL),(7,'bu_lurah','12345678','Bu lurah','-','2025-07-07 04:35:18',NULL,NULL,NULL,NULL),(8,'warga4','pass4','Vanszs','rw 3 rt 1','2025-07-09 15:57:08',NULL,NULL,NULL,NULL),(9,'warga5','pass5','vannn satria','surabaya','2025-07-10 13:33:47','085381568989',NULL,NULL,NULL),(11,'yuliaimut','avriskalucu','yuliaaaaaaaaaa','gatau plis','2025-07-11 04:12:31','-',NULL,NULL,NULL),(12,'irfinnstay','fanelek23','irfan romadhon :v','warlok','2025-07-11 04:14:44','-',NULL,NULL,NULL);
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

-- Dump completed on 2025-07-15 14:03:44
