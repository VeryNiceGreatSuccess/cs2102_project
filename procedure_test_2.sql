/* review(...) */
/* Creates a review by the given user for the particular ordered product */

/* --------------------------------------- insert some data first ----*/
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

/* ----------> test case 1A */

BEGIN;
	/* --- PROCEDURE METHOD ---
		review(user_id INTEGER, order_id INTEGER,
    		shop_id INTEGER, product_id INTEGER, sell_timestamp TIMESTAMP,
    		content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
	*/	
	CALL review(1, 1, 1, 1, '2016-06-22', 'damn gud 10 outta 10', 5, '2016-06-25');

COMMIT;

/* verify that insertion was SUCCESSFUL */
DO $$
DECLARE
	num_comments INTEGER := 0;
	num_reviews INTEGER := 0;
	num_review_versions INTEGER := 0;
BEGIN
	
	SELECT COUNT(*) INTO num_comments
	FROM comment;

	SELECT COUNT(*) INTO num_reviews
	FROM review;

	SELECT COUNT(*) INTO num_review_versions
	FROM review_version;	

	IF ((num_comments = 1) AND (num_reviews = 1) AND (num_review_versions = 1)) THEN
		RAISE NOTICE 'review successfully inserted into all 3 tables! - OK';
	ELSE
		RAISE WARNING 'review not successfully inserted - WRONG';
	END IF;
END $$;

/* ----------> test case 1B */

BEGIN;
	/* --- PROCEDURE METHOD ---
		review(user_id INTEGER, order_id INTEGER,
    		shop_id INTEGER, product_id INTEGER, sell_timestamp TIMESTAMP,
    		content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
	*/	
	CALL review(1, 1, 1, 1, '2016-06-22', 'eh wah wait i change my mind dis sux', 1, '2016-06-27');
COMMIT;

/* verify that insertion was SUCCESSFUL */
DO $$
DECLARE
	num_comments INTEGER := 0;
	num_reviews INTEGER := 0;
	num_review_versions INTEGER := 0;
BEGIN
	
	SELECT COUNT(*) INTO num_comments
	FROM comment;

	SELECT COUNT(*) INTO num_reviews
	FROM review;

	SELECT COUNT(*) INTO num_review_versions
	FROM review_version;	

	IF ((num_comments = 1) AND (num_reviews = 1) AND (num_review_versions = 2)) THEN
		RAISE NOTICE 'review updated! - OK';
	ELSE
		RAISE WARNING 'review not successfully updated - WRONG';
	END IF;
END $$;

/* ignore this bit
SELECT *                   
    FROM review R
    WHERE R.order_id = 1 AND
        R.shop_id = 1 AND
        R.product_id = 1 AND
        R.sell_timestamp = '2016-06-22';

*/
