/* (4) The refund quantity must not exceed the ordered quantity. */

/* --------------------------------------- insert VALID data ✅  ----*/

BEGIN;
	INSERT INTO shop VALUES
		(1, 'Takashimaya');
	INSERT INTO category VALUES
		(1, 'Home Appliances', NULL),
		(2, 'Kitchenware', NULL);
	INSERT INTO manufacturer VALUES
		(1, 'Tefal', 'Germany');
	INSERT INTO product VALUES
		(1, 'Rice Cooker', 'makes nice rice', 1, 1);	
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 5);
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);	
	INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 59.99*5);
	INSERT INTO orderline VALUES
		(1, 1, 1, '2016-06-22', 5, 9.99, 'being_processed', NULL);		
COMMIT;

BEGIN;
	INSERT INTO refund_request VALUES
		(1, NULL, 1, 1, 1, '2016-06-22', 5, '2016-06-27', 'pending', NULL, NULL);
COMMIT;

/* verify that insertion was SUCCESSFUL */

DO $$
DECLARE
	num_refunds INT := 0;
BEGIN	
	SELECT count(*) INTO num_refunds
	FROM refund_request;

	IF (num_refunds = 1) THEN
		RAISE NOTICE 'refund request was inserted ✅';
	ELSE
		RAISE WARNING 'refund request was not inserted when it should have been ❌';
	END IF;
END $$;

/* cleanup */
DELETE FROM refund_request;
DELETE FROM orderline;
DELETE FROM orders;
DELETE FROM sells;

/* ------------------------------ insert INVALID data ❌ -------- */

BEGIN;
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 3);
	INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 59.99*3);
	INSERT INTO orderline VALUES
		(1, 1, 1, '2016-06-22', 3, 9.99, 'being_processed', NULL);	

	/* ❌ customer tries to make a refund for quantity of 2+3=5 when only placed order for 3 */
	INSERT INTO refund_request VALUES
		(1, NULL, 1, 1, 1, '2016-06-22', 2, '2016-06-27', 'pending', NULL, NULL),
		(2, NULL, 1, 1, 1, '2016-06-22', 3, '2016-06-27', 'pending', NULL, NULL);
COMMIT;

/* verify that insertion was PREVENTED */

DO $$
DECLARE
	num_refunds INT := 0;
	total_refund_quantity INT := 0;
BEGIN	
	SELECT count(*) INTO num_refunds
	FROM refund_request;

	IF (num_refunds = 0) THEN
		RAISE NOTICE 'refund request(s) were NOT inserted ✅';
	ELSE
		RAISE WARNING 'refund request(s) were inserted when they should not have been ❌';
	END IF;

END $$;

/* cleanup */
DELETE FROM refund_request;
DELETE FROM orderline;
DELETE FROM orders;
DELETE FROM sells;
DELETE FROM product;
DELETE FROM manufacturer;
DELETE FROM category;
DELETE FROM shop;
DELETE FROM users;