/* (3) Finds the N worst shops, judging by the number of negative indicators that they have */
/* negative indicators include: number of ref req (on diff orderlines), shop complaints, delivery complaints (on diff orderlines), 1-star (latest) ratings */

/* --------------------------------------- clear data and reset triggers ----*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
\i schema.sql;
\i proc.sql;

/* -----------> TEST CASE 1a */

/* SHOP_ONE has 0 negative indicators */

/* SHOP_TWO has 2 refund requests --> total 2 negative indicators */ 

/* SHOP_THREE has 1 refund request, 1 shop complaint, 1 delivery complaint */

/* Expected result : 
   3  SHOP_THREE  3
   2  SHOP_TWO    2
   1  SHOP_ONE    0 */
   
BEGIN; 
    INSERT INTO users VALUES 
       (DEFAULT, 'Redhill, Singapore', 'Alex Yeoh', FALSE);

    INSERT INTO employee VALUES 
       (DEFAULT, 'Employee_one', 1200);
    
    INSERT INTO shop VALUES 
       (DEFAULT, 'SHOP_ONE_SELLS_CHIPS'),
       (DEFAULT, 'SHOP_TWO_SELLS_SPORTS_EQUIPMENT'),
       (DEFAULT, 'SHOP_THREE_SELLS_FURNITURE');
    
    INSERT INTO category VALUES 
       (DEFAULT, 'Snacks', NULL),
       (DEFAULT, 'Sports', NULL),
       (DEFAULT, 'Furniture', NULL);
    
    INSERT INTO manufacturer VALUES
       (DEFAULT, 'Lays', 'US'),
       (DEFAULT, 'Yonex', 'Japan'),
       (DEFAULT, 'Ikea', 'Sweden');


    INSERT INTO product VALUES 
       (DEFAULT, 'Sour Cream and Onion Chips', 'Sour cream and onion flavour', 1, 1),
       (DEFAULT, 'Badminton Racket', 'Very lightweight', 2, 2),
       (DEFAULT, 'Study table', 'Ergonomic choice', 3, 3);


    INSERT INTO sells VALUES 
       (1, 1, '2022-01-01 00:00:00', 4.50, 10), 
       (2, 2, '2022-01-01 00:00:00', 100.00, 1),
       (3, 3, '2022-01-01 00:00:00', 200.00, 1),
       (2, 2, '2022-01-02 00:00:00', 100.00, 1);

    INSERT INTO orders VALUES
       /* orders 10 sour cream chips from shop 1, 
                 1 badminton racket from shop 2, and
                 1 study table from shop 3 */
       (DEFAULT, 1, NULL, 'Redhill, Singapore', 10 * 4.50  + 1 * 100.00 + 1 * 200.00 + 30.00),
       
       /* orders 1 badminton racket from shop 2 */
       (DEFAULT, 1, NULL, 'Redhill, Singapore', 1 * 100.00 + 5.00);

    INSERT INTO orderline VALUES 
       (1, 1, 1, '2022-01-01 00:00:00', 10, 5.00, 'delivered', '2022-01-10'),
       (1, 2, 2, '2022-01-01 00:00:00', 1, 5.00, 'delivered', '2022-01-10'),
       (1, 3, 3, '2022-01-01 00:00:00', 1, 15.00, 'delivered', '2022-01-10'),
       (2, 2, 2, '2022-01-02 00:00:00', 1, 5.00, 'delivered', '2022-01-11');

    INSERT INTO refund_request VALUES 
       /* user 1 refunds 1 badminton racket */
       (DEFAULT, 1, 1, 2, 2, '2022-01-01 00:00:00', 1, NULL, 'being_handled', NULL),

       /* user 1 refunds 1 study table */ 
       (DEFAULT, 1, 1, 3, 3, '2022-01-01 00:00:00', 1, NULL, 'being_handled', NULL),

       /* user 2 refunds 1 badminton racket */
       (DEFAULT, 1, 2, 2, 2, '2022-01-02 00:00:00', 1, NULL, 'being_handled', NULL);

    INSERT INTO complaint VALUES 
       /* user 1 makes a (shop) complaint for shop 3 */
       (DEFAULT, 'Rude staff! :(', 'pending', 1, NULL),

       /* user 1 makes a (delivery) complaint for shop 3 */
       (DEFAULT, 'Late delivery :(', 'pending', 1, NULL);


    INSERT INTO shop_complaint VALUES 
       (1, 3);
    
    INSERT INTO delivery_complaint VALUES
       (2, 1, 3, 3, '2022-01-01 00:00:00');


COMMIT; 

/* verify results */ 
DO $$ 
DECLARE 
    shop_one_id INTEGER;
    shop_one_name TEXT; 
    shop_one_num_negative_indicators INTEGER;

    shop_two_id INTEGER;
    shop_two_name TEXT; 
    shop_two_num_negative_indicators INTEGER;

    shop_three_id INTEGER;
    shop_three_name TEXT; 
    shop_three_num_negative_indicators INTEGER;

BEGIN 
    SELECT shop_id, shop_name, num_negative_indicators
    INTO shop_one_id, shop_one_name, shop_one_num_negative_indicators
    FROM get_worst_shops(3)
    OFFSET 2; /* SHOP_ONE should be in the 3rd row */

    SELECT shop_id, shop_name, num_negative_indicators
    INTO shop_two_id, shop_two_name, shop_two_num_negative_indicators
    FROM get_worst_shops(3)
    LIMIT 2
    OFFSET 1;  /* SHOP_TWO should be in the 2nd row */

    SELECT shop_id, shop_name, num_negative_indicators
    INTO shop_three_id, shop_three_name, shop_three_num_negative_indicators
    FROM get_worst_shops(3)
    LIMIT 1; /* SHOP_THREE should be in the 1st row */

    IF (
        (shop_one_id = 1) AND
        (shop_two_id = 2) AND 
        (shop_three_id = 3) AND 
        (shop_one_name = 'SHOP_ONE_SELLS_CHIPS') AND
        (shop_two_name = 'SHOP_TWO_SELLS_SPORTS_EQUIPMENT') AND
        (shop_three_name = 'SHOP_THREE_SELLS_FURNITURE') AND
        (shop_one_num_negative_indicators = 0) AND
        (shop_two_num_negative_indicators = 2) AND
        (shop_three_num_negative_indicators = 3)

    ) THEN 
        RAISE NOTICE 'Test case 1a passed - OK';
    ELSE 
        RAISE WARNING 'Test case 1a failed - WRONG';
        RAISE NOTICE 'Expected: Shop 3: 3 indicators | Shop 2: 2 indicators | Shop 1: 0 indicator';
        RAISE NOTICE 'Actual: Shop 3: % indicators | Shop 2: % indicators | Shop 1: % indicator',
                      shop_three_num_negative_indicators, shop_two_num_negative_indicators, shop_three_num_negative_indicators;

    END IF;
END $$;

/* -----------> TEST CASE 1b */
/* to check that get_worst_shops(n) produces a table with of n rows 
   and that order is still maintained. */ 

DO $$ 
DECLARE 
    shop_one_id INTEGER;

    shop_two_id INTEGER;
  
    shop_three_id INTEGER;

    no_of_shops_showed_if_3_as_args INTEGER;

    no_of_shops_showed_if_2_as_args INTEGER;

    no_of_shops_showed_if_1_as_args INTEGER;

    no_of_shops_showed_if_0_as_args INTEGER;
   
BEGIN 
    SELECT shop_id INTO shop_one_id
    FROM get_worst_shops(3)
    LIMIT 1
    OFFSET 2;  /* SHOP_ONE should be in the last row if 3 is passed in as argument */
    
    SELECT shop_id INTO shop_two_id
    FROM get_worst_shops(2)
    LIMIT 1
    OFFSET 1; /* SHOP_TWO should be in the last row if 2 is passed in as argument */

    SELECT shop_id INTO shop_three_id
    FROM get_worst_shops(1)
    LIMIT 1; /* SHOP_THREE should be in the 1st row if 1 is passed in as argument */

    SELECT COUNT(*) INTO no_of_shops_showed_if_3_as_args
    FROM get_worst_shops(3);

    SELECT COUNT(*) INTO no_of_shops_showed_if_2_as_args
    FROM get_worst_shops(2);
    
    SELECT COUNT(*) INTO no_of_shops_showed_if_1_as_args
    FROM get_worst_shops(1);

    SELECT COUNT(*) INTO no_of_shops_showed_if_0_as_args
    FROM get_worst_shops(0);


     IF (
        (shop_one_id = 1) AND
        (shop_two_id = 2) AND 
        (shop_three_id = 3) AND 
        (no_of_shops_showed_if_3_as_args = 3) AND
        (no_of_shops_showed_if_2_as_args = 2) AND
        (no_of_shops_showed_if_1_as_args = 1) AND
        (no_of_shops_showed_if_0_as_args = 0) 
    ) THEN 
        RAISE NOTICE 'Test case 1b passed - OK';
    ELSE 
        RAISE WARNING 'Test case 1b failed - WRONG';
        RAISE NOTICE 'Expected: 1 | 2 | 3 | 3 | 2 | 1 | 0';
        RAISE NOTICE 'Actual: % | % | % | % | % | % | % |',
                      shop_one_id, shop_two_id, shop_three_id,
                      no_of_shops_showed_if_3_as_args,
                      no_of_shops_showed_if_2_as_args,
                      no_of_shops_showed_if_1_as_args,
                      no_of_shops_showed_if_0_as_args;
    END IF;
END $$;



 















       

    



