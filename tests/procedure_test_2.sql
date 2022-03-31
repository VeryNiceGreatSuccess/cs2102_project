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

BEGIN;
	

COMMIT;