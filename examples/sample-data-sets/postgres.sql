-- PostgreSQL dump for inventory schema
--
-- Supports: PostgreSQL, Aurora PostgreSQL
-- This schema includes foreign key constraints for referential integrity testing

--
-- Table structure for table customers
--

DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  first_name varchar(255) NOT NULL,
  last_name varchar(255) NOT NULL,
  email varchar(255) NOT NULL UNIQUE
);

--
-- Dumping data for table customers
--

INSERT INTO customers (id, first_name, last_name, email) VALUES
(1001,'Sally','Thomas','sally.thomas@acme.com'),
(1002,'George','Bailey','gbailey@foobar.com'),
(1003,'Edward','Walker','ed@walker.com'),
(1004,'Anne','Kretchmar','annek@noanswer.org');

--
-- Table structure for table addresses
--

DROP TABLE IF EXISTS addresses CASCADE;
CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  customer_id int NOT NULL,
  street varchar(255) NOT NULL,
  city varchar(255) NOT NULL,
  state varchar(255) NOT NULL,
  zip varchar(255) NOT NULL,
  type varchar(255) NOT NULL,
  CONSTRAINT addresses_customer_fk FOREIGN KEY (customer_id) REFERENCES customers (id)
);

--
-- Dumping data for table addresses
--

INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES
(10,1001,'3183 Moore Avenue','Euless','Texas','76036','SHIPPING'),
(11,1001,'2389 Hidden Valley Road','Harrisburg','Pennsylvania','17116','BILLING'),
(12,1002,'281 Riverside Drive','Augusta','Georgia','30901','BILLING'),
(13,1003,'3787 Brownton Road','Columbus','Mississippi','39701','SHIPPING'),
(14,1003,'2458 Lost Creek Road','Bethlehem','Pennsylvania','18018','SHIPPING'),
(15,1003,'4800 Simpson Square','Hillsdale','Oklahoma','73743','BILLING'),
(16,1004,'1289 University Hill Road','Canehill','Arkansas','72717','LIVING');

--
-- Table structure for table products
--

DROP TABLE IF EXISTS products CASCADE;
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name varchar(255) NOT NULL,
  description varchar(512) DEFAULT NULL,
  weight float DEFAULT NULL
);

--
-- Dumping data for table products
--

INSERT INTO products (id, name, description, weight) VALUES
(101,'scooter','Small 2-wheel scooter',3.14),
(102,'car battery','12V car battery',8.1),
(103,'12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3',0.8),
(104,'hammer','12oz carpenter''s hammer',0.75),
(105,'hammer','14oz carpenter''s hammer',0.875),
(106,'hammer','16oz carpenter''s hammer',1),
(107,'rocks','box of assorted rocks',5.3),
(108,'jacket','water resistent black wind breaker',0.1),
(109,'spare tire','24 inch spare tire',22.2);

--
-- Table structure for table orders
--

DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders (
  order_number SERIAL PRIMARY KEY,
  order_date date NOT NULL,
  purchaser int NOT NULL,
  quantity int NOT NULL,
  product_id int NOT NULL,
  CONSTRAINT orders_customer_fk FOREIGN KEY (purchaser) REFERENCES customers (id),
  CONSTRAINT orders_product_fk FOREIGN KEY (product_id) REFERENCES products (id)
);

--
-- Dumping data for table orders
--

INSERT INTO orders (order_number, order_date, purchaser, quantity, product_id) VALUES
(10001,'2016-01-16',1001,1,102),
(10002,'2016-01-17',1002,2,105),
(10003,'2016-02-19',1002,2,106),
(10004,'2016-02-21',1003,1,107);

--
-- Table structure for table geom
--

DROP TABLE IF EXISTS geom CASCADE;
CREATE TABLE geom (
  id SERIAL PRIMARY KEY,
  g bytea NOT NULL,
  h bytea DEFAULT NULL
);

--
-- Dumping data for table geom
--

INSERT INTO geom (id, g, h) VALUES
(1, E'\\001\\000\\000\\000\\001\\000\\000\\000\\000\\000\\000\\360?\\000\\000\\000\\000\\000\\000\\360?', NULL),
(2, E'\\001\\000\\000\\000\\002\\000\\000\\000\\002\\000\\000\\000\\000\\000\\000@\\000\\000\\000\\000\\000\\000\\360?\\000\\000\\000\\000\\000\\024@\\000\\000\\000\\000\\000\\024@', NULL),
(3, E'\\001\\000\\000\\000\\003\\000\\000\\000\\001\\000\\000\\000\\005\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\024@\\000\\000\\000\\000\\000\\000@\\000\\000\\000\\000\\000\\024@\\000\\000\\000\\000\\000\\000@\\000\\000\\000\\000\\000\\034@\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\034@\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\000\\024@', NULL);
