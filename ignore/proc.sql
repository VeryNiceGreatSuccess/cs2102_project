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


/* --- Procedures --------------------------------------------------------------------------- */


/* --- Functions ---------------------------------------------------------------------------- */