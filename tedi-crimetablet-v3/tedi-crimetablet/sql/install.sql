-- ===== CRIME TABLET DATABASE SETUP =====
-- Run this SQL in your database to set up the required tables

CREATE TABLE IF NOT EXISTS `crime_tablet_players` (
    `identifier` VARCHAR(60) NOT NULL,
    `boost_level` INT DEFAULT 0,
    `boost_xp` INT DEFAULT 0,
    `boosts_completed` INT DEFAULT 0,
    `total_earnings` INT DEFAULT 0,
    `heist_level` INT DEFAULT 0,
    `crypto` INT DEFAULT 0,
    `scratching_points` INT DEFAULT 0,
    `house_robberies` INT DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_tablet_accounts` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `account_name` VARCHAR(50) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_account` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_tablet_transactions` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `amount` INT NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_tablet_listings` (
    `id` INT AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `price` INT NOT NULL,
    `quantity` INT DEFAULT 1,
    `description` VARCHAR(200) DEFAULT '',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `crime_tablet_chat` (
    `id` INT AUTO_INCREMENT,
    `channel` VARCHAR(20) NOT NULL,
    `sender_id` VARCHAR(60) NOT NULL,
    `anonymous_name` VARCHAR(30) NOT NULL,
    `message` VARCHAR(200) NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_channel` (`channel`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
