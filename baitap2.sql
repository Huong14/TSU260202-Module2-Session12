DELIMITER //
CREATE PROCEDURE sp_create_order(
      IN p_customer_id INT,
      IN p_product_id INT,
      IN p_quantity INT,
      IN p_price INT
)
BEGIN
     DECLARE new_order_id INT;
     START TRANSACTION;
     SELECT stock_quantity FROM inventory
     WHERE product_id = p_product_id;
     IF stock_quantity < p_quantity THEN
       ROLLBACK;
       SIGNAL SQLSTATE '45000'
       SET MESSAGE_TEXT = 'Hàng tồn kho không đủ';
	END IF;
    
    INSERT INTO orders(customer_id,total_amount,status)
	VALUES (p_customer_id,0,'pending');
    SET new_order_id = LAST_INSERT_ID();
    INSERT INTO order_items (order_id,product_id,quantity,price)
    VALUES (new_order_id,p_product_id,p_quantity,p_price);
    UPDATE inventory
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;
    UPDATE orders
    SET total_amount = p_quantity * p_price
    WHERE order_id = new_order_id;

    COMMIT;
END //
DELIMITER ;
    