 --- Triggers ----------------------------------------------------------------------------- */

/* --------------------------------------------------------------- Product related ---------- */

/* 1. each shop should sell at least one product */

CREATE OR REPLACE FUNCTION check_shop_sells_at_least_one_product_func()
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
	ELSE
		RETURN NEW;					/* allow the shop to be inserted */
	END IF;					

	num_products_sold := 0; 		/* reset the variable to 0 */
	
	RETURN NULL; 					/* the return value does not matter since this function is executed AFTER op */
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_parent_complaint_func()
RETURNS TRIGGER AS $$
BEGIN
	
	DELETE FROM complaint C
	WHERE C.id = OLD.id;

	RETURN OLD;
	
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_parent_of_shop_complaint
AFTER DELETE ON shop_complaint
FOR EACH ROW
	EXECUTE FUNCTION delete_parent_complaint_func();

CREATE CONSTRAINT TRIGGER check_shop_sells_at_least_one_product
AFTER INSERT ON shop
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
	EXECUTE FUNCTION check_shop_sells_at_least_one_product_func();

/* --- Procedures --------------------------------------------------------------------------- */


/* --- Functions ---------------------------------------------------------------------------- */