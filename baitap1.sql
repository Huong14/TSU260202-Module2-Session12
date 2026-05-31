CREATE DATABASE ecommerce;
USE ecommerce;
-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

INSERT INTO products VALUES
     (null,'ip7',5000,'64G',default),
     (null,'ip8',5000,'128G',default),
     (null,'ip11',5000,'128G',default),
     (null,'ip12',5000,'256G',default),
     (null,'ip14',5000,'256G',default);

INSERT INTO inventory VALUES
     (1,8,default),
     (2,11,default),
     (3,5,default),
     (4,6,default),
     (5,14,default);
     
INSERT INTO customers VALUES
     (null,'Trang','trang@gmail.com',0123456789,'Ha Noi',default),
     (null,'Ngoc','ngoc@gmail.com',0123456788,'Hai Phong',default),
     (null,'Nhi','nhi@gmail.com',0123456787,'Ha Noi',default),
     (null,'Phong','phong@gmail.com',0123456786,'Da Nang',default);
     
INSERT INTO orders VALUES
     (null,1,default,15000,'pending'),
     (null,2,default,25000,'pending'),
     (null,3,default,20000,'pending'),
     (null,4,default,15000,'Completed');
     

-- Trigger BEFORE INSERT
  DELIMITER //
  CREATE TRIGGER trigger_beforeinsert_order_items
  BEFORE INSERT ON order_items
  FOR EACH ROW
  BEGIN
      if NEW.quantity > (SELECT stock_quantity FROM inventory WHERE  product_id = NEW.product_id)
      THEN SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hàng tồn kho không đủ';
        END IF ;
  END //
  DELIMITER ;
  
  INSERT INTO order_items VALUES (null,1,1,11,5000);
  
  -- Trigger AFTER INSERT
  DELIMITER //
  CREATE TRIGGER trigger_afterinsert_order_items
  AFTER INSERT ON order_items
  FOR EACH ROW
  BEGIN
      UPDATE orders
      SET total_amount = total_amount + (NEW.quantity * NEW.price)
      WHERE order_id = NEW.order_id;
  END //
  DELIMITER ;
  
  INSERT INTO order_items VALUES (null,1,1,1,5000);
  
  -- Trigger BEFORE UPDATE 
  DELIMITER //
  CREATE TRIGGER trigger_beforeupdate_order_items
  BEFORE UPDATE ON order_items
  FOR EACH ROW
  BEGIN
        IF NEW.quantity > (SELECT stock_quantity FROM inventory WHERE product_id = NEW.product_id)
        THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Hàng tồn kho không đủ';
        END IF;
  END //
  DELIMITER ;
  
  UPDATE order_items SET quantity = 11 WHERE order_item_id = 1;
  
  -- Trigger AFTER UPDATE
DELIMITER //
  CREATE TRIGGER trigger_afterupdate_order_items
  AFTER UPDATE ON order_items
  FOR EACH ROW
  BEGIN
      UPDATE orders SET total_amount = NEW.quantity * NEW.price
      WHERE order_id = NEW.order_id;
      
      UPDATE inventory SET stock_quantity = stock_quantity - NEW.quantity
      WHERE product_id = NEW.product_id;
  END //
  DELIMITER ;
  
  UPDATE order_items SET quantity = 5 WHERE order_item_id = 1;
  
  -- BEFORE DELETE – Ngăn xóa đơn hàng Completed
  
DELIMITER //
  CREATE TRIGGER trigger_beforedelete_orders
  BEFORE DELETE ON orders
  FOR EACH ROW
  BEGIN
      IF OLD.status = 'Completed' THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Không thể xóa đơn hàng comleted';
      END IF;
  END //
  DELIMITER ;
  
  DELETE FROM orders WHERE order_id = 4;
  
  -- AFTER DELETE – Hoàn trả tồn kho khi xóa order_items
 DELIMITER // 
CREATE TRIGGER trigger_afterdelete_order_items
  AFTER DELETE ON order_items
  FOR EACH ROW
  BEGIN
     UPDATE inventory
     SET stock_quantity = stock_quantity + OLD.quantity
     WHERE product_id = OLD.product_id;
  END //
  DELIMITER ;
  
DELETE FROM order_items WHERE product_id = 1;
  
DROP TRIGGER IF EXISTS trigger_beforeinsert_order_items ;
DROP TRIGGER IF EXISTS trigger_afterinsert_order_items ;
DROP TRIGGER IF EXISTS trigger_beforeupdate_order_items ;
DROP TRIGGER IF EXISTS trigger_afterupdate_order_items ;
DROP TRIGGER IF EXISTS trigger_afterdelete_order_items ;
DROP TRIGGER IF EXISTS trigger_beforedelete_orders ;
 

