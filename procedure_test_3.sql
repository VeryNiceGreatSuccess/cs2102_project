/* reply(...) */
/* Creates a reply by the given user to a comment */

/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* --------------------------------------- insert some data ----*/

BEGIN;
	INSERT INTO shop VALUES
        (DEFAULT, 'Don Don Donki'),
        (DEFAULT, 'NTUC');

	INSERT INTO category VALUES
		(DEFAULT, 'Food', NULL),
        (DEFAULT, 'Necessities', NULL);

	INSERT INTO manufacturer VALUES
		(DEFAULT, 'Ichiran', 'Japan'),
        (DEFAULT, 'Bobo', 'Singapore'),
        (DEFAULT, 'Dettol', 'Singapore');

	INSERT INTO product VALUES
		(DEFAULT, 'Instant ramen', 'Delicious ramen', 1, 1),
        (DEFAULT, 'Bobo Fishball', 'Delicious fishball', 1, 2),
        (DEFAULT, 'Hand sanitiser', 'Stay hygienic!', 2, 3);	

	INSERT INTO sells VALUES
		(1, 1, '2011-01-01 00:00:00', 10.00, 2),
        (2, 3, '2021-05-05 00:00:00', 5.50, 5);

	INSERT INTO users VALUES
		(DEFAULT, 'clementi, singapore', 'Ah Beng', FALSE),
        (DEFAULT, 'NUS school of computing', 'John Doe', FALSE);

	INSERT INTO orders VALUES
		(DEFAULT, 2, NULL, 'NUS school of computing', 10.00 * 2),
        (DEFAULT, 1, NULL, 'clementi, singapore', 5.50 * 5);

	INSERT INTO orderline VALUES
		(1, 1, 1, '2011-01-01 00:00:00', 2, 9.99, 'being_processed', NULL),
        (2, 2, 3, '2021-05-05 00:00:00', 5, 5.50, 'being_processed', NULL);    

    INSERT INTO comment VALUES 
        (DEFAULT, 2);
    
    INSERT INTO review VALUES
        (1, 1, 1, 1, '2011-01-01 00:00:00');

    INSERT INTO review_version VALUES
        (1, '2011-01-05 00:00:00', 'would buy again!', 5);

COMMIT;


/* ----------> test case 1A */

BEGIN;
   /* --- PROCEDURE METHOD ---
       reply( user_id INTEGER, other_comment_id INTEGER, content TEXT, reply_timestamp TIMESTAMP)
    */
    CALL reply(2, 1, 'No I disagree and would not buy it again.', '2011-01-07 00:00:00');

COMMIT;

/* verify that insertion was SUCCESSFUL */
DO $$
DECLARE
	num_comments INTEGER := 0;
	num_replies INTEGER := 0;
	num_reply_versions INTEGER := 0;
BEGIN
	
	SELECT COUNT(*) INTO num_comments
	FROM comment;

	SELECT COUNT(*) INTO num_replies
	FROM reply;

	SELECT COUNT(*) INTO num_reply_versions
	FROM reply_version;	

	IF ((num_comments = 2) AND (num_replies = 1) AND (num_reply_versions = 1)) THEN
		RAISE NOTICE 'reply successfully inserted into all 3 tables! - OK';
	ELSE
		RAISE WARNING 'reply not successfully inserted - WRONG';
	END IF;

END $$;

/* ----------> test case 1B */

BEGIN;
     /* --- PROCEDURE METHOD ---
       reply(user_id INTEGER, other_comment_id INTEGER, content TEXT, reply_timestamp TIMESTAMP)
    */
	CALL reply(2, 1, 'Oopz changed my mind, the product is actually ok', '2011-01-09');
COMMIT;

/* verify that insertion was SUCCESSFUL */
DO $$
DECLARE
	num_comments INTEGER := 0;
	num_replies INTEGER := 0;
	num_reply_versions INTEGER := 0;
BEGIN
	
	SELECT COUNT(*) INTO num_comments
	FROM comment;

	SELECT COUNT(*) INTO num_replies
	FROM reply;

	SELECT COUNT(*) INTO num_reply_versions
	FROM reply_version;	

	IF ((num_comments = 2) AND (num_replies = 1) AND (num_reply_versions = 2)) THEN
		RAISE NOTICE 'reply updated! - OK';
	ELSE
		RAISE WARNING 'reply not successfully updated - WRONG';
	END IF;
END $$;
