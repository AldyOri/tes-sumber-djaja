CREATE TABLE `items` (
	`id` int AUTO_INCREMENT NOT NULL,
	`sku` varchar(50) NOT NULL,
	`name` varchar(150) NOT NULL,
	`unit` varchar(20) NOT NULL,
	`created_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	`updated_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	CONSTRAINT `items_id` PRIMARY KEY(`id`),
	CONSTRAINT `items_sku_unique` UNIQUE(`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--> statement-breakpoint
CREATE TABLE `stock_transfer_items` (
	`id` int AUTO_INCREMENT NOT NULL,
	`transfer_id` int NOT NULL,
	`item_id` int NOT NULL,
	`quantity` int NOT NULL,
	CONSTRAINT `stock_transfer_items_id` PRIMARY KEY(`id`),
	CONSTRAINT `stock_transfer_items_transfer_item_unique` UNIQUE(`transfer_id`,`item_id`),
	CONSTRAINT `stock_transfer_items_quantity_check` CHECK(`stock_transfer_items`.`quantity` between 1 and 2147483647)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--> statement-breakpoint
CREATE TABLE `stock_transfers` (
	`id` int AUTO_INCREMENT NOT NULL,
	`reference` varchar(64) NOT NULL,
	`source_warehouse_id` int NOT NULL,
	`destination_warehouse_id` int NOT NULL,
	`notes` varchar(500),
	`created_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	CONSTRAINT `stock_transfers_id` PRIMARY KEY(`id`),
	CONSTRAINT `stock_transfers_reference_unique` UNIQUE(`reference`),
	CONSTRAINT `stock_transfers_different_warehouses_check` CHECK(`stock_transfers`.`source_warehouse_id` <> `stock_transfers`.`destination_warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--> statement-breakpoint
CREATE TABLE `warehouse_stocks` (
	`warehouse_id` int NOT NULL,
	`item_id` int NOT NULL,
	`quantity` int NOT NULL DEFAULT 0,
	`updated_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	CONSTRAINT `warehouse_stocks_warehouse_id_item_id_pk` PRIMARY KEY(`warehouse_id`,`item_id`),
	CONSTRAINT `warehouse_stocks_quantity_check` CHECK(`warehouse_stocks`.`quantity` between 0 and 2147483647)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--> statement-breakpoint
CREATE TABLE `warehouses` (
	`id` int AUTO_INCREMENT NOT NULL,
	`code` varchar(50) NOT NULL,
	`name` varchar(150) NOT NULL,
	`address` varchar(255),
	`created_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	`updated_at` datetime(3) NOT NULL DEFAULT (UTC_TIMESTAMP(3)),
	CONSTRAINT `warehouses_id` PRIMARY KEY(`id`),
	CONSTRAINT `warehouses_code_unique` UNIQUE(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--> statement-breakpoint
ALTER TABLE `stock_transfer_items` ADD CONSTRAINT `stock_transfer_items_transfer_id_stock_transfers_id_fk` FOREIGN KEY (`transfer_id`) REFERENCES `stock_transfers`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
ALTER TABLE `stock_transfer_items` ADD CONSTRAINT `stock_transfer_items_item_id_items_id_fk` FOREIGN KEY (`item_id`) REFERENCES `items`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
ALTER TABLE `stock_transfers` ADD CONSTRAINT `stock_transfers_source_warehouse_id_warehouses_id_fk` FOREIGN KEY (`source_warehouse_id`) REFERENCES `warehouses`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
ALTER TABLE `stock_transfers` ADD CONSTRAINT `stock_transfers_destination_warehouse_id_warehouses_id_fk` FOREIGN KEY (`destination_warehouse_id`) REFERENCES `warehouses`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
ALTER TABLE `warehouse_stocks` ADD CONSTRAINT `warehouse_stocks_warehouse_id_warehouses_id_fk` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
ALTER TABLE `warehouse_stocks` ADD CONSTRAINT `warehouse_stocks_item_id_items_id_fk` FOREIGN KEY (`item_id`) REFERENCES `items`(`id`) ON DELETE restrict ON UPDATE restrict;
--> statement-breakpoint
CREATE INDEX `stock_transfer_items_item_idx` ON `stock_transfer_items` (`item_id`);
--> statement-breakpoint
CREATE INDEX `stock_transfers_created_idx` ON `stock_transfers` (`created_at`,`id`);
--> statement-breakpoint
CREATE INDEX `stock_transfers_source_idx` ON `stock_transfers` (`source_warehouse_id`,`created_at`,`id`);
--> statement-breakpoint
CREATE INDEX `stock_transfers_destination_idx` ON `stock_transfers` (`destination_warehouse_id`,`created_at`,`id`);
--> statement-breakpoint
CREATE INDEX `warehouse_stocks_item_idx` ON `warehouse_stocks` (`item_id`);
