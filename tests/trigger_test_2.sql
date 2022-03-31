/* (2) An order must involve one or more products from one or more shops. */

/* --------------------------------------- insert VALID data ----*/

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
		(1, 1, '2016-06-22', 59.99, 1);
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);
COMMIT;

BEGIN;
	INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 55);
	INSERT INTO orderline VALUES
		(1, 1, 1, '2016-06-22', 1, 9.99, 'being_processed', NULL);
COMMIT;

/* verify that insertion was SUCCESSFUL */

DO $$
DECLARE
	num_orders INT := 0;
BEGIN	
	SELECT count(*) INTO num_orders
	FROM orders;

	IF (num_orders = 1) THEN
		RAISE NOTICE 'order was inserted - OK';
	ELSE
		RAISE WARNING 'order was not inserted when it should have been - WRONG';
	END IF;	
END $$;

/* cleanup */
DELETE FROM orderline;
DELETE FROM orders;

/* ------------------------------ insert INVALID data -------- */

BEGIN;
	INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 55);

	/* order inserted has no associate orderline entry */
COMMIT;

/* verify that insertion was PREVENTED */

DO $$
DECLARE
	num_orders INT := 0;
BEGIN	
	SELECT count(*) INTO num_orders
	FROM orders;

	IF (num_orders = 0) THEN
		RAISE NOTICE 'order was not inserted - OK';
	ELSE
		RAISE WARNING 'order was inserted when it should not have been - WRONG';
	END IF;	
END $$;

/* cleanup */
DELETE FROM orderline;
DELETE FROM orders;
DELETE FROM sells;
DELETE FROM product;
DELETE FROM manufacturer;
DELETE FROM category;
DELETE FROM shop;
DELETE FROM users;