 --- Triggers ----------------------------------------------------------------------------- */

/* (1) Each shop should sell at least one product */
CREATE OR REPLACE FUNCTION trigger1_func()
RETURNS TRIGGER AS $$
DECLARE
	num_products_sold INT := 0;
BEGIN
	SELECT COUNT(*) INTO num_products_sold
	FROM sells S
	WHERE S.shop_id = NEW.id;

	IF (num_products_sold = 0) THEN		
		RAISE EXCEPTION 'Each shop should sell at least one product';
	END IF;					

	num_products_sold := 0;			/* reset the variable to 0 */
	
	RETURN NULL; 					/* the return value does not matter since this function is executed AFTER op */
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger1
AFTER INSERT ON shop
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
	EXECUTE FUNCTION trigger1_func();


/* (2) An order must involve one or more products from one or more shops. */

CREATE OR REPLACE FUNCTION trigger2_func()
RETURNS TRIGGER AS $$
DECLARE
	num_products_in_order INT := 0;
BEGIN

	SELECT count(*) INTO num_products_in_order
	FROM orderline
	WHERE orderline.order_id = NEW.id;

	IF (num_products_in_order = 0) THEN
		RAISE EXCEPTION 'an order must involve one or more products from one or more shops';
	END IF;

	num_products_in_order := 0; /* reset the variable to 0 */

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger2
AFTER INSERT ON orders
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
	EXECUTE FUNCTION trigger2_func();


/* (3) A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds
the minimum order amount. */

CREATE OR REPLACE FUNCTION trigger3_func()
RETURNS TRIGGER AS $$
DECLARE
	total_amount_of_order INT := 0;
	min_order_amount_of_coupon INT := 0;
BEGIN

	IF (NEW.coupon_id IS NULL) THEN		
		RETURN NULL; /* don't have to check as no coupon was applied */
	END IF;

	WITH
	cte1 as (
		SELECT (L.quantity * S.price) as value
		FROM orderline L join sells S on
			L.product_id = S.product_id AND
			L.shop_id = S.shop_id AND
			L.sell_timestamp = S.sell_timestamp
		WHERE L.order_id = NEW.id		
	)

	SELECT COALESCE(sum(value), 0) INTO total_amount_of_order
	FROM cte1;

	SELECT min_order_amount INTO min_order_amount_of_coupon
	FROM coupon_batch
	WHERE coupon_batch.id = NEW.coupon_id;

	IF (total_amount_of_order <= min_order_amount_of_coupon) THEN
		RAISE EXCEPTION 'A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds
the minimum order amount';
	END IF;

	total_amount_of_order := 0;			/* reset the variable to 0 */
	min_order_amount_of_coupon := 0;	/* reset the variable to 0 */

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger3
AFTER INSERT ON orders
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
	EXECUTE FUNCTION trigger3_func();



/* (4) The refund quantity must not exceed the ordered quantity. */

CREATE OR REPLACE FUNCTION trigger4_func()
RETURNS TRIGGER AS $$
DECLARE
	orderline_product_quantity INT := 0;
	total_product_refund_request_quantity INT := 0;
BEGIN

	SELECT COALESCE(quantity, 0) INTO orderline_product_quantity
	FROM orderline
	WHERE order_id = NEW.order_id AND 
		shop_id = NEW.shop_id AND
		product_id = NEW.product_id AND
		sell_timestamp = NEW.sell_timestamp;
	
	SELECT COALESCE(SUM(quantity), 0) INTO total_product_refund_request_quantity 
	FROM refund_request
	GROUP BY order_id, shop_id, product_id, sell_timestamp;	

	IF (orderline_product_quantity < total_product_refund_request_quantity) THEN
		RAISE EXCEPTION 'the refund quantity must not exceed the ordered quantity';
	END IF;

	orderline_product_quantity := 0; /* reset the variable to 0 */
	total_product_refund_request_quantity := 0; /* reset the variable to 0 */

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger4
AFTER INSERT ON refund_request
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
	EXECUTE FUNCTION trigger4_func();

/* (5) The refund request date must be within 30 days of the delivery date. */

CREATE OR REPLACE FUNCTION trigger5_func() RETURNS TRIGGER AS $$
DECLARE 
     dd DATE;
BEGIN 
     SELECT delivery_date INTO dd
     FROM orderline 
     WHERE NEW.order_id = orderline.order_id AND NEW.product_id = orderline.product_id
            AND NEW.shop_id = orderline.shop_id AND NEW.sell_timestamp = orderline.sell_timestamp;

     IF ((NEW.request_date - dd) < 30) THEN 
          RETURN NEW;
     ELSE 
         RAISE EXCEPTION 'Constraint 5 violated';
     END IF; 

END; 
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger5 
AFTER INSERT ON refund_request
FOR EACH ROW EXECUTE FUNCTION trigger5_func();



/* (6) Refund request can only be made for a delivered product */

CREATE OR REPLACE FUNCTION trigger6_func()
RETURNS TRIGGER AS $$
DECLARE
    product_status VARCHAR(50);
BEGIN
    SELECT O.status INTO product_status
    FROM orderline O
    WHERE O.order_id = NEW.order_id
    AND O.shop_id = NEW.shop_id
    AND O.product_id = NEW.product_id
    AND O.sell_timestamp = NEW.sell_timestamp;

    IF (product_status = 'being_processed' OR product_status = 'shipped') THEN
        RAISE EXCEPTION 'Constraint 6 violated';
    END IF;
    
    RETURN NULL;    
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger6
AFTER INSERT ON refund_request
FOR EACH ROW
    EXECUTE FUNCTION trigger6_func();

/* (7) A user can only make a product review for a product that they themselves purchased. */

CREATE OR REPLACE FUNCTION trigger7_func() RETURNS TRIGGER AS $$ 
DECLARE 

    user_id INTEGER; 
    order_id INTEGER;
    

BEGIN

    SELECT comment.user_id INTO user_id 
    FROM comment 
    WHERE NEW.id = comment.id;
 
    SELECT o1.order_id INTO order_id 
    FROM orderline o1
    WHERE o1.order_id = NEW.order_id 
          AND o1.shop_id = NEW.shop_id
          AND o1.product_id = NEW.product_id
         AND o1.sell_timestamp = NEW.sell_timestamp;

     IF ((SELECT orders.user_id FROM orders
     WHERE orders.id = order_id
     GROUP BY orders.user_id) = user_id) THEN 
          RETURN NEW;

      ELSE 
           RAISE EXCEPTION 'Constraint 7 violated';
      END IF; 

END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER  trigger7
AFTER INSERT ON review
FOR EACH ROW EXECUTE FUNCTION trigger7_func();



/* (8) A comment is either a review or a reply, not both (non-overlapping and covering) */

CREATE OR REPLACE FUNCTION trigger8a_func()
RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.id IN (SELECT id FROM reply)) THEN
        RAISE EXCEPTION 'Comment cannot be both a review and a reply!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger8b_func()
RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.id IN (SELECT id FROM review)) THEN
        RAISE EXCEPTION 'Comment cannot be both a review and a reply!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger8c_func()
RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.id IN (SELECT id FROM review) OR NEW.id IN (SELECT id FROM reply)) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Comment has to be either a review or a reply!';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger8a
AFTER INSERT ON review
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
    EXECUTE FUNCTION trigger8a_func();

CREATE CONSTRAINT TRIGGER trigger8b
AFTER INSERT ON reply
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
    EXECUTE FUNCTION trigger8b_func();

CREATE CONSTRAINT TRIGGER trigger8c
AFTER INSERT ON comment
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
    EXECUTE FUNCTION trigger8c_func();

/* (9) A reply has at least one reply version */

CREATE OR REPLACE FUNCTION trigger9_func() RETURNS
TRIGGER AS $$ 
BEGIN        
IF ((SELECT COUNT(*)
      FROM reply_version
      WHERE reply_version.reply_id = NEW.id) < 1) THEN
      RAISE EXCEPTION 'Constraint 9 is violated';
ELSE
      RETURN NEW;
END IF;

END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger9
AFTER INSERT ON reply 
FOR EACH ROW EXECUTE FUNCTION trigger9_func(); 



/* (10) A review has at least one review version */

CREATE OR REPLACE FUNCTION trigger10_func() RETURNS
TRIGGER AS $$ 
BEGIN        
IF ((SELECT COUNT(*)
      FROM review_version
      WHERE review_version.review_id = NEW.i) < 1) THEN
      RAISE EXCEPTION 'Constraint 10 is violated';
ELSE
      RETURN NEW;
END IF;

END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger10
AFTER INSERT ON reply 
FOR EACH ROW EXECUTE FUNCTION trigger10_func();  



/* (11) A delivery complaint can only be made when the product has been delivered */

CREATE OR REPLACE FUNCTION trigger11_func() RETURNS TRIGGER AS $$ 
DECLARE 
      status VARCHAR(20);
BEGIN
       SELECT orderline.orderline_status INTO status
       FROM orderline
       WHERE orderline.order_id = NEW.order_id 
            AND orderline.shop_id = NEW.shop_id 
            AND orderline.product_id = NEW.product_id
            AND orderline.sell_timestamp = NEW.sell_timestamp;

       IF (status = 'delivered') THEN 
            RETURN NEW;
        ELSE 
             RAISE EXCEPTION 'Constraint 11 is violated';
        END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger11
AFTER INSERT ON delivery_complaint
FOR EACH ROW EXECUTE FUNCTION trigger11_func();

/* (12) A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related complaint (non-overlapping and covering) */
CREATE OR REPLACE FUNCTION trigger12a_func()
RETURNS TRIGGER AS $$
BEGIN

    IF (NEW.id IN (SELECT id FROM comment_complaint) OR NEW.id IN (SELECT id FROM delivery_complaint)) THEN
        RAISE EXCEPTION 'Comment can only be either a delivery-related complaint, a shop-related complaint or a comment-related complaint!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger12b_func()
RETURNS TRIGGER AS $$
BEGIN
 IF (NEW.id IN (SELECT id FROM shop_complaint) OR NEW.id IN (SELECT id FROM delivery_complaint)) THEN
        RAISE EXCEPTION 'Comment can only be either a delivery-related complaint, a shop-related complaint or a comment-related complaint!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger12c_func()
RETURNS TRIGGER AS $$
BEGIN
 IF (NEW.id IN (SELECT id FROM comment_complaint) OR NEW.id IN (SELECT id FROM shop_complaint)) THEN
        RAISE EXCEPTION 'Comment can only be either a delivery-related complaint, a shop-related complaint or a comment-related complaint!';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger12d_func()
RETURNS TRIGGER AS $$
BEGIN
 IF (NEW.id IN (SELECT id FROM comment_complaint) OR NEW.id IN (SELECT id FROM shop_complaint)
    OR NEW.id IN (SELECT id FROM delivery_complaint)) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Comment has to be either a delivery-related complaint, a shop-related complaint or a comment-related complaint!';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger12a
AFTER INSERT ON shop_complaint
FOR EACH ROW
    EXECUTE FUNCTION trigger12a_func();

CREATE CONSTRAINT TRIGGER trigger12b
AFTER INSERT ON comment_complaint
FOR EACH ROW
    EXECUTE FUNCTION trigger12b_func();

CREATE CONSTRAINT TRIGGER trigger12c
AFTER INSERT ON delivery_complaint
FOR EACH ROW
    EXECUTE FUNCTION trigger12c_func();

CREATE CONSTRAINT TRIGGER trigger12d
AFTER INSERT ON complaint
FOR EACH ROW
    EXECUTE FUNCTION trigger12d_func();

/* --- Procedures --------------------------------------------------------------------------- */

/* (2) */

/* NOTE:
    the names of the input parameters have been changed -> they are prefixed with an underscore "_"

   WHY:
    because the attribute names in the "review" relations were identical to the original names of the input paramters,
    which will cause ambiguity
*/
CREATE OR REPLACE PROCEDURE review(_user_id INTEGER, _order_id INTEGER,
    _shop_id INTEGER, _product_id INTEGER, _sell_timestamp TIMESTAMP,
    _content TEXT, _rating INTEGER, _comment_timestamp TIMESTAMP)
AS $$
DECLARE
    comment_id INTEGER;    
BEGIN
    /* check if a previous version of this review exists, */
    SELECT id INTO comment_id
    FROM review R
    WHERE R.order_id = _order_id AND
        R.shop_id = _shop_id AND
        R.product_id = _product_id AND
        R.sell_timestamp = _sell_timestamp;

    IF (comment_id IS NULL) THEN
        /* create a parent-entry in the "comments" relation; note that this entry will have id = next_comment_id */    
        INSERT INTO comment VALUES
            (DEFAULT, _user_id)
        RETURNING id INTO comment_id; /* get the id that was auto-assigned to the the comment just inserted */

        /* then, create a child-entry in the "reviews" relation */
        INSERT INTO review VALUES
            (comment_id, _order_id, _shop_id, _product_id, _sell_timestamp);

        /* then, create an entry in the "review_version" relation */
        INSERT INTO review_version VALUES
            (comment_id, _comment_timestamp, _content, _rating);
    ELSE
        /* insert another entry in the "review_version" relation to reflect the updated version */
        INSERT INTO review_version VALUES
            (comment_id, _comment_timestamp, _content, _rating);
    END IF;

END;
$$ LANGUAGE plpgsql;


/* (3) */

/* NOTE:
    the names of the input parameters have been changed -> they are prefixed with an underscore "_"

   WHY:
    because the attribute names in the "reply" relations were identical to the original names of the input paramters,
    which will cause ambiguity
*/

CREATE OR REPLACE PROCEDURE reply(_user_id INTEGER, _other_comment_id INTEGER, _content TEXT, _reply_timestamp TIMESTAMP)
AS $$

DECLARE 
    does_other_comment_exist INTEGER;
    comment_id INTEGER;

BEGIN 
    /* check if the comment that the user is replying to exists */
    SELECT count(*) INTO does_other_comment_exist
    FROM comment C
    WHERE C.id = _other_comment_id; /* get the id that was auto-assigned to the the comment just inserted */

    /* check if a version of the reply already exists */
    SELECT id into comment_id
    FROM reply R
    WHERE R.id = _user_id AND R.other_comment_id = _other_comment_id;

    /* raise exception if other comment does not exist */
    IF (does_other_comment_exist = 0) THEN
        RAISE EXCEPTION 'Other comment does not exist!';
    END IF;

    /* if there is already a reply to be updated */
    IF (comment_id IS NOT NULL) THEN 
        /* then, create an entry in the "reply_version" relation */
        INSERT INTO reply_version VALUES (comment_id, _reply_timestamp, _content);

    ELSE 
        /* create a parent-entry in the "comments" relation; note that this entry will have id = next_comment_id */
        INSERT INTO comment VALUES (DEFAULT, _user_id)
        RETURNING id INTO comment_id; 

        /* then, create a child-entry in the "reply" relation */
        INSERT INTO reply VALUES (comment_id, _other_comment_id);

        /* then, create an entry in the "reply_version" relation */
        INSERT INTO reply_version VALUES (comment_id, _reply_timestamp, _content);

    END IF; 

END;
$$ LANGUAGE plpgsql;


/* --- Functions ---------------------------------------------------------------------------- */

/* (2) */

CREATE OR REPLACE FUNCTION get_most_returned_products_from_manufacturer
    (manufacturer_id INTEGER, n INTEGER)
RETURNS TABLE(product_id INTEGER, product_name TEXT, return_rate NUMERIC(3, 2)) AS $$

BEGIN

RETURN QUERY (

    WITH
        /* find all products sold by the manufacturer */
        all_products AS (
            SELECT id, name
            FROM product
            WHERE manufacturer = manufacturer_id
        ),        
        /* find total quantity of each product successfully delivered */
        delivered_orders AS (
            SELECT O.product_id, O.quantity
            FROM orderline O
            WHERE O.status = 'delivered'
        ),
        num_delivered AS (
            SELECT A.id, A.name, COALESCE(SUM(O.quantity), 0) as quantity_delivered
            FROM all_products A LEFT JOIN delivered_orders O ON
                A.id = O.product_id
            GROUP BY A.id, A.name
        ),
        /* find total number of each product successfully refunded */
        accepted_refunds AS (
            SELECT R.product_id, R.quantity
            FROM refund_request R
            WHERE R.status = 'accepted'
        ),
        num_returned AS (
            SELECT A.id, A.name, COALESCE(SUM(R.quantity), 0) as quantity_returned
            FROM all_products A LEFT JOIN accepted_refunds R                
                ON A.id = R.product_id
            GROUP BY A.id, A.name
        ),
        /* calculate return rate of each product sold by the manufacturer */
        product_return_rate AS (
            SELECT D.id, D.name,
                (R.quantity_returned::NUMERIC / D.quantity_delivered::NUMERIC) AS rate
            FROM num_delivered D JOIN num_returned R ON
                D.id = R.id AND
                D.name = R.name
        )

        SELECT id AS product_id, name AS product_name, rate::NUMERIC(3, 2) AS return_rate
        FROM product_return_rate
        ORDER BY return_rate DESC, product_id ASC
        LIMIT n

);
END;
$$ LANGUAGE plpgsql;


/* (3) */ 
CREATE OR REPLACE FUNCTION get_worst_shops(n INTEGER) RETURNS
TABLE (shop_id INTEGER, shop_name TEXT, num_negative_indicators INTEGER) AS $$

BEGIN 

RETURN QUERY (
    WITH 

        /* filtering out multiple refund requests made on the same orderline */
        no_of_refund_requests AS (
            SELECT DISTINCT order_id, shop_id, product_id, sell_timestamp
            FROM refund_request
            GROUP BY order_id, shop_id, product_id, sell_timestamp
        ), 

        /* filtering out multiple delivery requests made on the same orderline */
        no_of_delivery_complaints AS (
            SELECT DISTINCT order_id, shop_id, product_id, sell_timestamp
            FROM delivery_complaint
            GROUP BY order_id, shop_id, product_id, sell_timestamp
        ),

        /* get latest review version for each review */
        latest_review_versions AS (
            SELECT DISTINCT review_id, rating
            FROM review_version RV_1
            WHERE RV_1.review_timestamp >= all (
                SELECT review_timestamp
                FROM review_version RV_2
                WHERE RV_1.review_id = RV_2.review_id
            )
        ),

        /* join each latest 1-star review version with its corresponding shop */
        latest_review_version_to_shop AS (
            SELECT DISTINCT shop_id, review_id, rating
            FROM latest_review_versions RV inner join review R
            ON RV.review_id = R.id
            WHERE RV.rating = 1
        ),

        /* number of negative indicators per shop */
        negative_indicators_per_shop AS (
            SELECT DISTINCT S.id, 

                /*scalar query to get number of refund requests per shop */
                ((SELECT COUNT(*) WHERE no_of_refund_requests.shop_id = S.id) + 

                /* scalar query to get number of shop complaints per shop */
                (SELECT COUNT(*) WHERE shop_complaint.shop_id = S.id) + 

                /* scalar query to get number of delivery complaints per shop */
                (SELECT COUNT(*) WHERE no_of_delivery_complaints.shop_id = S.id) + 

                /* scalar query to get number of 1-star reviews per shop */
                (SELECT COUNT(*) WHERE latest_review_version_to_shop.shop_id = S.id))

                AS num_negative_indicators_per_shop

            FROM shops    

        )

        SELECT S.id AS shop_id, S.name AS shop_name, N.num_negative_indicators_per_shop AS num_negative_indicators
        FROM shop S natural join negative_indicators_per_shop N
        ORDER BY num_negative_indicators DESC, shop_id ASC
        LIMIT n
);
END;
$$ LANGUAGE plpgsql;





