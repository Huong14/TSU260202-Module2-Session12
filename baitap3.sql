CREATE TABLE order_logs (

    log_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    old_status ENUM('Pending', 'Completed', 'Cancelled'),

    new_status ENUM('Pending', 'Completed', 'Cancelled'),

    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE

);


DELIMITER //
CREATE TRIGGER before_insert_check_payment
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE c_total DECIMAL(10,2);
    SELECT total_amount INTO c_total
    FROM orders
    WHERE order_id = NEW.order_id;

    IF c_total IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order không tồn tại';
    END IF;

    IF NEW.amount <> c_total THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số tiền thanh toán không khớp tổng tiền đơn hàng';
    END IF;
END //
DELIMITER ;