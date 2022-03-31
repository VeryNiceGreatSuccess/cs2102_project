/* (2) Obtains the N products from the provided manufacturer that have the highest return rate (successfully refunded)*/

/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* -----------> TEST CASE 1 */

BEGIN;
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE);
	INSERT INTO employee VALUES
		(1, 'wagie', 1200);		
	INSERT INTO shop VALUES
		(1, 'Takashimaya');

	INSERT INTO category VALUES
		(1, 'Home Appliances', NULL),
		(2, 'Kitchenware', NULL);
	INSERT INTO manufacturer VALUES
		(1, 'Tefal', 'Germany');
	INSERT INTO product VALUES
		(1, 'Rice Cooker', 'makes nice rice', 2, 1),
		(2, 'Frying Pan', 'makes nice eggs', 2, 1),
		(3, 'Television', 'not very nice tv', 1, 1);
	INSERT INTO sells VALUES
		(1, 1, '2016-06-22', 59.99, 10),
		(1, 2, '2016-06-22', 12.99, 10),
		(1, 3, '2016-06-22', 210.99, 10);

	INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 59.99*10 + 12.99*10 + 210.99*10);
	INSERT INTO orderline VALUES
		/* customer 1 orders 10 units of every item -> all are delivered */
		(1, 1, 1, '2016-06-22', 10, 59.99, 'delivered', '2016-06-26'),
		(1, 1, 2, '2016-06-22', 10, 12.99, 'delivered', '2016-06-26'),
		(1, 1, 3, '2016-06-22', 10, 210.99, 'delivered', '2016-06-26');

	INSERT INTO refund_request VALUES
		/* customer's request to return 5 units of 'Rice Cooker' is accepted */
		(1, 1, 1, 1, 1, '2016-06-22', 5, '2016-06-27', 'accepted', '2016-06-28', NULL);		
COMMIT;

/* verify results */
DO $$
DECLARE
	ricecooker_returnrate NUMERIC(3,2) := 0;
	fryingpan_returnrate NUMERIC(3,2) := 0;
	television_returnrate NUMERIC(3,2) := 0;
BEGIN
	SELECT return_rate INTO ricecooker_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Rice Cooker';

	SELECT return_rate INTO fryingpan_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Frying Pan';

	SELECT return_rate INTO television_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Television';

	/* 5 units of ricecooker have been returned; out of 10 units successfully delivered */
	/* no units of fryingpan or television have been returned */	
	IF (
		(ricecooker_returnrate = 0.50) AND
		(fryingpan_returnrate = 0) AND
		(television_returnrate = 0)
	) THEN
		RAISE NOTICE 'Test case 1 passed - OK';
	ELSE		
		RAISE WARNING 'Test case 1 failed - WRONG';
		RAISE NOTICE 'Expected: 0.50 | 0 | 0';
		RAISE NOTICE 'Actual: % | % | % ', ricecooker_returnrate, fryingpan_returnrate, television_returnrate;
	END IF;
END $$;

/* -----------> TEST CASE 2 */
BEGIN;

	INSERT INTO refund_request VALUES
		/* customer's request to return 5 units of 'Frying Pan' is submitted, but is still pending */
		(2, NULL, 1, 1, 2, '2016-06-22', 5, '2016-06-27', 'pending', NULL, NULL),
		/* customer's request to return 5 units of 'Television' was rejected */
		(3, 1, 1, 1, 3, '2016-06-22', 5, '2016-06-27', 'rejected', '2016-06-28', 'nice one who ask u buy too bad ecksdee');

COMMIT;

/* verify results */
DO $$
DECLARE
	ricecooker_returnrate NUMERIC(3,2) := 0;
	fryingpan_returnrate NUMERIC(3,2) := 0;
	television_returnrate NUMERIC(3,2) := 0;
BEGIN
	SELECT return_rate INTO ricecooker_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Rice Cooker';

	SELECT return_rate INTO fryingpan_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Frying Pan';

	SELECT return_rate INTO television_returnrate
	FROM get_most_returned_products_from_manufacturer(1, 5)
	WHERE product_name = 'Television';

	/* 5 units of ricecooker have been returned; out of 10 units successfully delivered */
	/* although refund requests for fryingpan and television were also submitted,
		they are either pending or rejected, so should not be counted in the return-rate */
	IF (
		(ricecooker_returnrate = 0.50) AND
		(fryingpan_returnrate = 0) AND
		(television_returnrate = 0)
	) THEN
		RAISE NOTICE 'Test case 2 passed - OK';
	ELSE		
		RAISE WARNING 'Test case 2 failed - WRONG';
		RAISE NOTICE 'Expected: 0.50 | 0 | 0';
		RAISE NOTICE 'Actual: % | % | % ', ricecooker_returnrate, fryingpan_returnrate, television_returnrate;
	END IF;
END $$;


