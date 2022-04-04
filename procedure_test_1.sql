/* TEST FOR INSERTING ORDER */
/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* --------------------------------------- insert some data ----*/

BEGIN;
	INSERT INTO shop VALUES
		(1, 'Takashimaya'),
        (2, 'Sheng Shiong');
	INSERT INTO category VALUES
		(1, 'Home Appliances', NULL),
		(2, 'Kitchenware', NULL);
	INSERT INTO manufacturer VALUES
		(1, 'Tefal', 'Germany');
	INSERT INTO product VALUES
		(1, 'Rice Cooker', 'makes nice rice', 1, 1);	
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 5),
        (2, 1, '2016-06-23', 45.99, 3);
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);	
    INSERT INTO coupon_batch VALUES
        (1, '2022-01-01', '2022-12-31', 19, 200);
    INSERT INTO issued_coupon VALUES
        (1, 1);	
COMMIT;

BEGIN;

    CALL place_order(1, 1, 'Sinagpore'::TEXT, ARRAY[2,1], ARRAY[1,1], ARRAY['2016-06-23', '2016-06-22']::timestamp[], ARRAY[2, 3], ARRAY[3, 4]);

COMMIT;

DO $$
DECLARE
    correct_payment INTEGER := 0;
    actual_payment INTEGER := 0;
BEGIN
    /*
        correct total amount -> $260
        quantity of product from shop after call
        shop 1: 5 -> 2
        shop 2: 3 -> 1
    */
    IF ((SELECT payment_amount from orders) = 260 AND ((SELECT quantity from sells where shop_id = 2) = 1) AND (SELECT quantity from sells where shop_id = 1) = 2) THEN
        RAISE NOTICE 'PASSED! order successfully added! (with coupon)';
    ELSE 
        RAISE WARNING 'FAILED! order did not get added';
    END IF;
END $$;


    /* TEST FOR INSERTING ORDER WITHOUT COUPON */
/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* --------------------------------------- insert some data ----*/

BEGIN;
	INSERT INTO shop VALUES
		(1, 'Takashimaya'),
        (2, 'Sheng Shiong');
	INSERT INTO category VALUES
		(1, 'Home Appliances', NULL),
		(2, 'Kitchenware', NULL);
	INSERT INTO manufacturer VALUES
		(1, 'Tefal', 'Germany');
	INSERT INTO product VALUES
		(1, 'Rice Cooker', 'makes nice rice', 1, 1);	
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 5),
        (2, 1, '2016-06-23', 45.99, 3);
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);	
    INSERT INTO coupon_batch VALUES
        (1, '2022-01-01', '2022-12-31', 19, 200);
    INSERT INTO issued_coupon VALUES
        (1, 1);	
COMMIT;

BEGIN;

    CALL place_order(1, NULL, 'Sinagpore'::TEXT, ARRAY[2,1], ARRAY[1,1], ARRAY['2016-06-23', '2016-06-22']::timestamp[], ARRAY[2, 3], ARRAY[3, 4]);

COMMIT;

DO $$
DECLARE
    correct_payment INTEGER := 0;
    actual_payment INTEGER := 0;
BEGIN
    /*
        correct total amount -> $279
        quantity of product from shop after call
        shop 1: 5 -> 2
        shop 2: 3 -> 1
    */
    IF ((SELECT payment_amount from orders) = 279 AND ((SELECT quantity from sells where shop_id = 2) = 1) AND (SELECT quantity from sells where shop_id = 1) = 2) THEN
        RAISE NOTICE 'PASSED! order successfully added! (without coupon)';
    ELSE 
        RAISE WARNING 'FAILED! order did not get added';
    END IF;
END $$;
