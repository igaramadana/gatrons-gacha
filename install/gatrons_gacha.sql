-- Gatrons Gacha V2 - Character-based persistence
-- Gatrons Coin dan pending gacha dimiliki oleh citizenid / character.

CREATE TABLE IF NOT EXISTS `gatrons_gacha_pending` (
    `id` VARCHAR(64) NOT NULL,
    `citizenid` VARCHAR(64) NOT NULL,
    `box_name` VARCHAR(64) NOT NULL,
    `reward_json` LONGTEXT NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'rolling',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `claim_started_at` TIMESTAMP NULL DEFAULT NULL,
    `claimed_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_gatrons_gacha_citizen` (`citizenid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gatrons_coin` (
    `citizenid` VARCHAR(64) NOT NULL,
    `balance` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
