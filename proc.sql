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
		DELETE FROM shop_complaint C /* also remove any complaints pertaining to the shop (if any were inserted in the same query) */
		WHERE C.shop_id = NEW.id;

		DELETE FROM shop S   		/* remove the shop to prevent it from being inserted */
		WHERE S.id = NEW.id;
	END IF;					

	num_products_sold := 0;			/* reset the variable to 0 */
	
	RETURN NULL; 					/* the return value does not matter since this function is executed AFTER op */
END;
$$ LANGUAGE plpgsql;

/* function to delete parent complaints */
CREATE OR REPLACE FUNCTION trigger1_a_func()
RETURNS TRIGGER AS $$
BEGIN
	
	DELETE FROM complaint C
	WHERE C.id = OLD.id;

	RETURN OLD;
	
END;
$$ LANGUAGE plpgsql;

/* trigger to also delete parent complaints of shop_complaints deleted */
CREATE TRIGGER trigger1_a
AFTER DELETE ON shop_complaint
FOR EACH ROW
	EXECUTE FUNCTION trigger1_a_func();

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
		DELETE FROM orders
		WHERE orders.id = NEW.id;
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
		/*
		UPDATE orders
		SET coupon_id = NULL
		WHERE orders.id = NEW.id;
		*/

		DELETE FROM orderline
		WHERE orderline.order_id = NEW.id;

		DELETE FROM orders
		WHERE orders.id = NEW.id;	
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
BEGIN
	
	SELECT quantity INTO orderline_product_quantity
	FROM orderline
	WHERE order_id = NEW.order_id AND 
		shop_id = NEW.shop_id AND
		product_id = NEW.product_id AND
		sell_timestamp = NEW.sell_timestamp;

	IF (COALESCE(orderline_product_quantity, 0) < NEW.quantity) THEN
		orderline_product_quantity := 0; /* reset the variable to 0 */
		RETURN NULL;
	END IF;

	orderline_product_quantity := 0; /* reset the variable to 0 */

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger4
BEFORE INSERT ON refund_request
FOR EACH ROW
	EXECUTE FUNCTION trigger4_func();



/* --- Procedures --------------------------------------------------------------------------- */


/* --- Functions ---------------------------------------------------------------------------- */