/* (1) Retrieves all info about all comments related to a product listing */

/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* ------------> TEST CASE 1 */

/* 3 users all ordered the rice cooker product and reviewed the product */

/* USER_ONE replied to USER_TWO review */

/* USER_ONE updated his review once */

/* Expected result:
    Ah Ming | 'product is very good'              |  5   | '2016-06-30'
    Ah Beng | 'product broke, it sucks'           |  1   | '2016-06-29'
    Ah Beng | 'product sucks, the lid fell off'   | NULL | '2016-06-29'
    Ah Lian | 'product very nice'                 |  5   | '2016-06-28'
*/

BEGIN;
	INSERT INTO users VALUES
		(1, 'clementi, singapore', 'Ah Beng', FALSE),
		(2, 'jurong, singapore', 'Ah Lian', TRUE),
		(3, 'pioneer, singapore', 'Ah Ming', FALSE);
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
		(1, 2, '2016-06-22', 12.99, 10);

    INSERT INTO orders VALUES
		(1, 1, NULL, 'clementi, singapore', 59.99),
		(2, 2, NULL, 'jurong, singapore', 59.99),
		(3, 3, NULL, 'pioneer, singapore', 59.99);
	INSERT INTO orderline VALUES
	    /* Each user orders 1 unit of Rice Cooker */
	    (1, 1, 1, '2016-06-22', 1, 59.99, 'delivered', '2016-06-26'),
	    (2, 1, 1, '2016-06-22', 1, 59.99, 'delivered', '2016-06-26'),
	    (3, 1, 1, '2016-06-22', 1, 59.99, 'delivered', '2016-06-26');

	INSERT INTO comment VALUES
	    (1, 1),
	    (2, 1),
	    (3, 2),
	    (4, 3);
	INSERT INTO review VALUES
	    (1, 1, 1, 1, '2016-06-22'),
	    (3, 2, 1, 1, '2016-06-22'),
	    (4, 3, 1, 1, '2016-06-22');
	INSERT INTO review_version VALUES
        (1, '2016-06-27', 'product is working fine', 4),
        (1, '2016-06-29', 'product broke, it sucks', 1),
        (3, '2016-06-28', 'product very nice', 5),
        (4, '2016-06-30', 'product is very good', 5);
	INSERT INTO reply VALUES
        (2, 3);
	INSERT INTO reply_version VALUES
        (2, '2016-06-29', 'product sucks, the lid fell off');
COMMIT;

/* verify results */
DO $$
DECLARE
    username_one TEXT;
    content_one TEXT;
    rating_one INTEGER;
    timestamp_one TIMESTAMP;

    username_two TEXT;
    content_two TEXT;
    rating_two INTEGER;
    timestamp_two TIMESTAMP;

    username_three TEXT;
    content_three TEXT;
    rating_three INTEGER;
    timestamp_three TIMESTAMP;

    username_four TEXT;
    content_four TEXT;
    rating_four INTEGER;
    timestamp_four TIMESTAMP;
BEGIN
    SELECT username, content, rating, comment_timestamp
    INTO username_one, content_one, rating_one, timestamp_one
    FROM view_comments(1, 1, '2016-06-22')
    LIMIT 1;

    SELECT username, content, rating, comment_timestamp
    INTO username_two, content_two, rating_two, timestamp_two
    FROM view_comments(1, 1, '2016-06-22')
    LIMIT 2
    OFFSET 1;

    SELECT username, content, rating, comment_timestamp
    INTO username_three, content_three, rating_three, timestamp_three
    FROM view_comments(1, 1, '2016-06-22')
    LIMIT 3
    OFFSET 2;

    SELECT username, content, rating, comment_timestamp
    INTO username_four, content_four, rating_four, timestamp_four
    FROM view_comments(1, 1, '2016-06-22')
    OFFSET 3;

    IF (
        (username_one = 'Ah Ming') AND
        (username_two = 'Ah Beng') AND
        (username_three = 'Ah Beng') AND
        (username_four = 'A Deleted User') AND
        (content_one = 'product is very good') AND
        (content_two = 'product broke, it sucks') AND
        (content_three = 'product sucks, the lid fell off') AND
        (content_four = 'product very nice') AND
        (rating_one = 5) AND
        (rating_two = 1) AND
        (rating_three IS NULL) AND
        (rating_four = 5) AND
        (timestamp_one = '2016-06-30 00:00:00') AND
        (timestamp_two = '2016-06-29 00:00:00') AND
        (timestamp_three = '2016-06-29 00:00:00') AND
        (timestamp_four = '2016-06-28 00:00:00')
    ) THEN
        RAISE NOTICE 'Test case 1 passed - OK';
    ELSE
        RAISE WARNING 'Test case 1 failed - WRONG';
        RAISE NOTICE '1st tuple: % | % | % | %', username_one, content_one, rating_one, timestamp_one;
        RAISE NOTICE '2nd tuple: % | % | % | %', username_two, content_two, rating_two, timestamp_two;
        RAISE NOTICE '3rd tuple: % | % | % | %', username_three, content_three, rating_three, timestamp_three;
        RAISE NOTICE '4th tuple: % | % | % | %', username_four, content_four, rating_four, timestamp_four;
    END IF;
END $$;