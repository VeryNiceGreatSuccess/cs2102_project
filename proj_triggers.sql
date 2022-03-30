-- q5, q7, q9, q10, q11


--q5

CREATE OR REPLACE FUNCTION trigger5_func() RETURNS TRIGGER AS $$
DECLARE 
     dd DATE;
BEGIN 
     SELECT delivery_date INTO dd
     FROM orderline 
     WHERE NEW.order_id = orderline.order_id AND NEW.product_id = orderline.product_id;

     IF ((NEW.request_date - dd) < 30) THEN 
          RETURN NEW;
     ELSE 
               -- DELETE FROM refund_request WHERE NEW.id = refund_request.id;
               -- RETURN NULL;
                RAISE EXCEPTION 'Constraint 5 violated';
     END IF; 

END; 
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger5 
AFTER INSERT ON refund_request
FOR EACH ROW EXECUTE FUNCTION trigger5_func();

--q7
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

--q9
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

--q10
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


--q11
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


