/* (3) A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds
the minimum order amount. */

/* --------------------------------------- insert VALID data ----*/

BEGIN;
	INSERT INTO shop VALUES
		(1, 'Takashimaya');
	INSERT INTO category VALUES
		(1, 'Home Appliances', NULL),
		(2, 'Kitchenware', NULL);
	INSERT INTO manufacturer VALUES
		(1, 'Tefal', 'Germany');
	INSERT INTO product VALUES
		(1, 'Rice Cooker', 'makes nice rice', 1, 1),
		(2, 'Frying Pan', 'makes nice omelettes', 2, 1);
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 1),
		(1, 2, '2016-06-22', 15.99, 1);
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);
COMMIT;

BEGIN;
	INSERT INTO coupon_batch VALUES
		(1, '2016-06-01', '2017-06-01', 65, 65);
	INSERT INTO issued_coupon VALUES
		(1, 1);
	INSERT INTO orders VALUES
		(1, 1, 1, 'clementi, singapore', 59.99+15.99);
	INSERT INTO orderline VALUES
		(1, 1, 1, '2016-06-22', 1, 59.99, 'being_processed', NULL),
		(1, 1, 2, '2016-06-22', 1, 15.99, 'being_processed', NULL);
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
DELETE FROM issued_coupon;
DELETE FROM coupon_batch;

/* ------------------------------ insert INVALID data -------- */

BEGIN;
	INSERT INTO coupon_batch VALUES
		(1, '2016-06-01', '2017-06-01', 65, 65);
	INSERT INTO issued_coupon VALUES
		(1, 1);
	INSERT INTO orders VALUES
		(1, 1, 1, 'clementi, singapore', 59.99);		
	INSERT INTO orderline VALUES
		(1, 1, 1, '2016-06-22', 1, 59.99, 'being_processed', NULL);
		/* total value of this order is 59.99, which is less than the minimum order amount of 65 */
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
DELETE FROM issued_coupon;
DELETE FROM coupon_batch;
DELETE FROM sells;
DELETE FROM product;
DELETE FROM manufacturer;
DELETE FROM category;
DELETE FROM shop;
DELETE FROM users;