-- Oracle Database Initialization Script
-- Demonstrates Oracle-specific features and best practices

-- ============================================================================
-- PART 1: CREATE APPLICATION USER (Best Practice)
-- ============================================================================
-- Never use SYS/SYSTEM for applications - create dedicated users

CREATE USER app_user IDENTIFIED BY AppPass2024!;

-- Grant minimum necessary privileges (Principle of Least Privilege)
GRANT CREATE SESSION TO app_user;
GRANT CREATE TABLE TO app_user;
GRANT CREATE SEQUENCE TO app_user;
GRANT UNLIMITED TABLESPACE TO app_user;

ALTER USER app_user DEFAULT TABLESPACE users;

-- ============================================================================
-- PART 2: CREATE SCHEMA OBJECTS
-- ============================================================================
-- Switch to app_user context
CONNECT app_user/AppPass2024!@localhost:1521/xe;

-- Create USERS table (Oracle-style with SEQUENCE)
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Create PRODUCTS table with CHECK constraints (Oracle feature: CONSTRAINT naming)
CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    description CLOB,  -- Character Large Object (Oracle feature)
    price NUMBER(10,2) CONSTRAINT price_check CHECK (price > 0),
    stock_quantity NUMBER DEFAULT 0 CONSTRAINT stock_check CHECK (stock_quantity >= 0),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Create ORDERS table with foreign keys and constraints
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    user_id NUMBER CONSTRAINT fk_orders_user REFERENCES users(user_id) ON DELETE CASCADE,
    product_id NUMBER CONSTRAINT fk_orders_product REFERENCES products(product_id),
    quantity NUMBER CONSTRAINT qty_check CHECK (quantity > 0),
    total_price NUMBER(10,2) CONSTRAINT total_check CHECK (total_price > 0),
    order_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- ============================================================================
-- PART 3: CREATE SEQUENCES (Oracle's auto-increment equivalent)
-- ============================================================================
-- Oracle doesn't have SERIAL/AUTOINCREMENT; use sequences instead

CREATE SEQUENCE users_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE products_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

CREATE SEQUENCE orders_seq
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

-- ============================================================================
-- PART 4: CREATE INDEXES (Performance optimization)
-- ============================================================================
-- Primary keys automatically create indexes
-- Add additional indexes for frequently queried columns

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_products_name ON products(name);

-- ============================================================================
-- PART 5: INSERT SAMPLE DATA
-- ============================================================================

-- Insert sample users using sequence
INSERT INTO users (user_id, username, email)
VALUES (users_seq.NEXTVAL, 'john_doe', 'john@example.com');

INSERT INTO users (user_id, username, email)
VALUES (users_seq.NEXTVAL, 'jane_smith', 'jane@example.com');

INSERT INTO users (user_id, username, email)
VALUES (users_seq.NEXTVAL, 'alice_wonder', 'alice@example.com');

-- Insert sample products
INSERT INTO products (product_id, name, description, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Laptop', 'High-performance laptop', 999.99, 10);

INSERT INTO products (product_id, name, description, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Mouse', 'Wireless ergonomic mouse', 29.99, 50);

INSERT INTO products (product_id, name, description, price, stock_quantity)
VALUES (products_seq.NEXTVAL, 'Keyboard', 'Mechanical keyboard', 79.99, 25);

-- Insert sample orders
INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
VALUES (orders_seq.NEXTVAL, 1, 1, 1, 999.99);

INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
VALUES (orders_seq.NEXTVAL, 2, 2, 2, 59.98);

INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
VALUES (orders_seq.NEXTVAL, 1, 3, 1, 79.99);

-- ============================================================================
-- PART 6: CREATE VIEWS (Oracle feature for data abstraction)
-- ============================================================================

-- View: User order summary
CREATE OR REPLACE VIEW user_order_summary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_price) as total_spending
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username, u.email;

-- View: Product sales performance
CREATE OR REPLACE VIEW product_sales AS
SELECT 
    p.product_id,
    p.name,
    COUNT(o.order_id) as times_ordered,
    SUM(o.quantity) as total_quantity_sold,
    SUM(o.total_price) as total_revenue
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.name;

-- ============================================================================
-- PART 7: CREATE STORED PROCEDURES (Oracle feature)
-- ============================================================================

-- Procedure: Create new order with automatic ID
CREATE OR REPLACE PROCEDURE create_new_order(
    p_user_id IN NUMBER,
    p_product_id IN NUMBER,
    p_quantity IN NUMBER,
    p_total_price IN NUMBER
)
AS
BEGIN
    INSERT INTO orders (order_id, user_id, product_id, quantity, total_price)
    VALUES (orders_seq.NEXTVAL, p_user_id, p_product_id, p_quantity, p_total_price);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order created successfully');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error creating order: ' || SQLERRM);
END;
/

-- ============================================================================
-- PART 8: VERIFY DATA
-- ============================================================================

SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders;

-- View sample data
SELECT * FROM users;
SELECT * FROM products;
SELECT * FROM orders;

-- Query views
SELECT * FROM user_order_summary;
SELECT * FROM product_sales;

COMMIT;
