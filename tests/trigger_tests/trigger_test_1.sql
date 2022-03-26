/* --------- Each shop should sell at least one product. ------------ */

/* --------------------------------------- insert VALID data ✅  ----*/

BEGIN;

INSERT INTO shop VALUES
	(1, 'Takashimaya');
INSERT INTO category VALUES
	(1, 'Home Appliances', NULL);
INSERT INTO manufacturer VALUES
	(1, 'Tefal', 'Germany');
INSERT INTO product VALUES
	(1, 'Rice Cooker', 'makes nice rice', 1, 1);
INSERT INTO sells VALUES
	(1, 1, NOW(), 59.99, 20);

COMMIT;

/* verify that insertion was SUCCESSFUL */
DO $$
DECLARE
	num_shops int := 0;
BEGIN
	
	SELECT COUNT(*) into num_shops
	FROM shop;

	IF (num_shops = 1) THEN
		RAISE NOTICE 'shop successfully inserted! ✅';
	ELSE
		RAISE WARNING 'shop should have been successfully inserted ❌';
	END IF;

END $$;

/* cleanup */
DELETE FROM sells;
DELETE FROM product;
DELETE FROM manufacturer;
DELETE FROM category;
DELETE FROM shop;

/* ------------------------------ insert INVALID data ❌ -------- */
BEGIN;

INSERT INTO shop VALUES
	(1, 'Takashimaya');

INSERT INTO users VALUES
	(1, 'clementi, singapore', 'Ah Beng', FALSE);

INSERT INTO complaint VALUES
	(1, 'not working', 'pending', 1, NULL);

INSERT INTO shop_complaint VALUES
	(1, 1);

COMMIT;

/* verify that insertion was PREVENTED */
DO $$
DECLARE
	num_shops int := 0;
	num_complaints int := 0;
BEGIN
	
	SELECT COUNT(*) into num_shops
	FROM shop;

	SELECT COUNT(*) into num_complaints
	FROM shop_complaint;

	IF (num_shops = 0) THEN
		RAISE NOTICE 'shop was not inserted! ✅';
	ELSE
		RAISE WARNING 'shop should not have been inserted ❌';
	END IF;

	IF (num_complaints = 0) THEN
		RAISE NOTICE 'complaints related to the shop were also not inserted! ✅';
	ELSE
		RAISE WARNING 'complaints related to the shop should not have been inserted since the shop technically does not exist ❌';
	END IF;
END $$;

/* cleanup */
DELETE FROM sells;
DELETE FROM product;
DELETE FROM manufacturer;
DELETE FROM category;
DELETE FROM shop;
DELETE FROM shop_complaint;
DELETE FROM complaint;
DELETE FROM users;