/* CREATE QUERIES */
/* ASSIGNMENT 3 - Creating Models */ 
CREATE TABLE MUTABAY.categories(
	category_id INT PRIMARY KEY,
	category_name VARCHAR (100) NOT NULL
);

CREATE TABLE MUTABAY.brands(
	brand_id INT PRIMARY KEY,
    brand_name VARCHAR (100) NOT NULL
);

CREATE TABLE MUTABAY.products(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year INT NOT NULL,
    list_price DECIMAL (10, 2) NOT NULL,
    FOREIGN KEY(category_id) REFERENCES MUTABAY.categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY(brand_id) REFERENCES MUTABAY.brands(brand_id) ON DELETE CASCADE 
);

CREATE TABLE MUTABAY.customers(
	customer_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip_code VARCHAR(50)
);

CREATE TABLE MUTABAY.stores(
	store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100),
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip_code VARCHAR(50)
);

CREATE TABLE MUTABAY.staffs(
	staff_id INT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    store_id INT NOT NULL,
    manager_id INT,
    active NUMBER(3,0) NOT NULL,
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(manager_id) REFERENCES MUTABAY.staffs(staff_id)
);

CREATE TABLE MUTABAY.orders(
	order_id INT PRIMARY KEY,
    customer_id INT,
    order_status NUMBER(3,0),
	-- Order status: 1 = Pending; 2 = Processing; 3 = Rejected; 4 = Completed
	order_date VARCHAR2(20) NOT NULL,
    required_date VARCHAR2(20) NOT NULL,
    shipped_date VARCHAR2(20),
    store_id INT NOT NULL,
    staff_id INT NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES MUTABAY.customers(customer_id) ON DELETE CASCADE ,
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(staff_id) REFERENCES MUTABAY.staffs(staff_id) 
);

CREATE TABLE MUTABAY.order_items(
	order_id INT,
    item_id INT,
    product_id INT NOT NULL,
    quantity_id INT NOT NULL,
    list_price DECIMAL (10, 2) NOT NULL,
    discount DECIMAL (10, 2) NOT NULL ,
    PRIMARY KEY(order_id, item_id),
    FOREIGN KEY(order_id) REFERENCES MUTABAY.orders(order_id) ON DELETE CASCADE ,
    FOREIGN KEY(product_id) REFERENCES MUTABAY.products(product_id) ON DELETE CASCADE 
);

CREATE TABLE MUTABAY.stocks(
	store_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY(store_id, product_id),
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(product_id) REFERENCES MUTABAY.products(product_id) ON DELETE CASCADE 
);


/* Testing Data Count */
SELECT COUNT(*) FROM MUTABAY.products;


/* Cleaning Cache and Pool */ 
alter system flush buffer_cache;
alter system flush shared_pool;

/* Testing Simple Query */ 
SELECT 
    stores.store_name,
    SUM(orders.order_id) AS order,
    AVG(ISNULL (DATEDIFF(day, orders.order_date, orders.required_date), 0)) AS avg_difference
FROM MUTABAY.stores
LEFT JOIN MUTABAY.staffs staffs ON staffs.store_id = stores.store_id
LEFT JOIN MUTABAY.orders orders ON orders.staff_id = staffs.staff_id 
GROUP BY
    stores.store_id,
    stores.store_name
ORDER BY order DESC, stores.store_id ASC;

/* ASSIGNMENT 4 - Workload - Complex Queries */

set timing on;
/* 1ST QUERY */
EXPLAIN PLAN FOR
SELECT product_id,brand_name ,product_name, model_year, list_price, category_name FROM
(
      (SELECT * FROM
            (SELECT * FROM
                ( SELECT * from MUTABAY.products prod_outer
                     where 1 = (
                            SELECT COUNT(Distinct list_price)
                            FROM MUTABAY.products prod_inner
                            WHERE prod_outer.brand_id = prod_inner.brand_id
                            AND prod_outer.list_price < prod_inner.list_price
                            )
                ) prod
                FULL OUTER JOIN
                MUTABAY.brands brands on brands.brand_id = prod.brand_id
            ) prod_brand
            FULL OUTER JOIN
            MUTABAY.categories categories on categories.category_id = prod_brand.category_id
      )prod_brand_cat
)
where list_price > 990000 AND model_year < 2020 

GROUP BY product_id,brand_name ,product_name, model_year, list_price, category_name
ORDER BY product_id ASC;

set timing off;


set timing on;
/* 1ST QUERY PARTITIONED EDITION FOR COMPARISON*/
EXPLAIN PLAN FOR
SELECT product_id,brand_name ,product_name, model_year, list_price, category_name FROM
(
      (SELECT * FROM
            (SELECT * FROM
                ( SELECT * from MUTABAY.products_range prod_outer
                     where 1 = (
                            SELECT COUNT(Distinct list_price)
                            FROM MUTABAY.products_range prod_inner
                            WHERE prod_outer.brand_id = prod_inner.brand_id
                            AND prod_outer.list_price < prod_inner.list_price
                            )
                ) prod
                FULL OUTER JOIN
                MUTABAY.brands_hash brands on brands.brand_id = prod.brand_id
            ) prod_brand
            FULL OUTER JOIN
            MUTABAY.categories categories on categories.category_id = prod_brand.category_id
      )prod_brand_cat
)
where list_price > 990000 AND model_year < 2020

GROUP BY product_id,brand_name ,product_name, model_year, list_price, category_name
ORDER BY product_id ASC;

set timing off;

/* Prints Selected Explain Plan */
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* 1ST QUERY COLUMNAR STORAGE (IN-MEMORY) EDITION FOR COMPARISON*/
set timing on

EXPLAIN PLAN FOR
SELECT product_id,brand_name ,product_name, model_year, list_price, category_name FROM
(
      (SELECT * FROM
            (SELECT * FROM
                ( SELECT * from MUTABAY.products_column prod_outer
                     where 1 = (
                            SELECT COUNT(Distinct list_price)
                            FROM MUTABAY.products_column prod_inner
                            WHERE prod_outer.brand_id = prod_inner.brand_id
                            AND prod_outer.list_price < prod_inner.list_price
                            )
                ) prod
                FULL OUTER JOIN
                MUTABAY.brands brands on brands.brand_id = prod.brand_id
            ) prod_brand
            FULL OUTER JOIN
            MUTABAY.categories categories on categories.category_id = prod_brand.category_id
      )prod_brand_cat
)
where list_price > 990000 AND model_year < 2020 

GROUP BY product_id,brand_name ,product_name, model_year, list_price, category_name
ORDER BY product_id ASC;

set timing off;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());



/* 2ND QUERY */
/* Selecting staffs and stores which have avg salary bigger than avg salary then having bigger than 10000 and not null or Aberdeen city and active */
set timing on;
EXPLAIN PLAN FOR
SELECT first_name,last_name, active, salary, stores.store_name, stores.city, stores.state
FROM
(
    SELECT staffs.*,avg(salary) over (partition by store_id) as avgSalary
    from MUTABAY.staffs staffs
)staffs
FULL OUTER JOIN MUTABAY.stores stores
ON staffs.store_id=stores.store_id
FULL OUTER JOIN MUTABAY.orders orders
ON stores.store_id = orders.store_id
FULL OUTER JOIN MUTABAY.order_items order_items
ON orders.order_id = order_items.order_id
FULL OUTER JOIN MUTABAY.products products
ON order_items.product_id = products.product_id
WHERE staffs.salary < staffs.avgsalary or order_items.discount > 0.05 or customer_id > 1500
GROUP BY store_name, first_name, salary, city, state, last_name, active
having (avg(staffs.salary) > 1000 OR state IS NOT NULL) OR (city = 'Aberdeen' AND active = 1)
ORDER BY store_name asc;

set timing off;

/* 2ND QUERY PARTITIONED EDITION FOR COMPARISON*/
/* Selecting staffs and stores which have avg salary bigger than avg salary then having bigger than 10000 and not null or Aberdeen city and active */
set timing on;
EXPLAIN PLAN FOR
SELECT first_name,last_name, active, salary, stores.store_name, stores.city, stores.state
FROM
(
    SELECT staffs.*,avg(salary) over (partition by store_id) as avgSalary
    from MUTABAY.staffs_range staffs
)staffs
FULL OUTER JOIN MUTABAY.stores_hash stores
ON staffs.store_id=stores.store_id
FULL OUTER JOIN MUTABAY.orders_range orders
ON stores.store_id = orders.store_id
FULL OUTER JOIN MUTABAY.order_items order_items
ON orders.order_id = order_items.order_id
FULL OUTER JOIN MUTABAY.products_range products
ON order_items.product_id = products.product_id
WHERE staffs.salary > staffs.avgsalary AND order_items.discount > 0.05 AND customer_id > 1500
GROUP BY store_name, first_name, salary, city, state, last_name, active
having (avg(staffs.salary) > 1000 AND state IS NOT NULL) OR (city = 'Aberdeen' AND active = 1)
ORDER BY store_name asc;

set timing off;


SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* 2nd QUERY Columnar Storage */
/* Selecting staffs and stores which have avg salary bigger than avg salary then having bigger than 10000 and not null or Aberdeen city and active */
set timing on

SELECT first_name,last_name, active, salary, stores.store_name, stores.city, stores.state
FROM
(
    SELECT staffs.*,avg(salary) over (partition by store_id) as avgSalary
    from MUTABAY.staffs_column staffs
)staffs
FULL OUTER JOIN MUTABAY.stores_column stores
ON staffs.store_id=stores.store_id
FULL OUTER JOIN MUTABAY.orders_column orders
ON stores.store_id = orders.store_id
FULL OUTER JOIN MUTABAY.order_items_column order_items
ON orders.order_id = order_items.order_id
FULL OUTER JOIN MUTABAY.products_column products
ON order_items.product_id = products.product_id
WHERE staffs.salary < staffs.avgsalary or order_items.discount > 0.05 or customer_id > 1500
GROUP BY store_name, first_name, salary, city, state, last_name, active
having (avg(staffs.salary) > 1000 OR state IS NOT NULL) OR (city = 'Aberdeen' AND active = 1)
ORDER BY store_name asc;

set timing off;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* ASSIGNMENT 13 - 2nd QUERY PARTITION- Columnar Storage */
set timing on

SELECT first_name,last_name, active, salary, stores.store_name, stores.city, stores.state
FROM
(
    SELECT staffs.*,avg(salary) over (partition by store_id) as avgSalary
    from MUTABAY.staffs_column_partition staffs
)staffs
FULL OUTER JOIN MUTABAY.stores_column stores
ON staffs.store_id=stores.store_id
FULL OUTER JOIN MUTABAY.orders_column_partition orders
ON stores.store_id = orders.store_id
FULL OUTER JOIN MUTABAY.order_items_column order_items
ON orders.order_id = order_items.order_id
FULL OUTER JOIN MUTABAY.products_column_partition products
ON order_items.product_id = products.product_id
WHERE staffs.salary < staffs.avgsalary or order_items.discount > 0.05 or customer_id > 1500
GROUP BY store_name, first_name, salary, city, state, last_name, active
having (avg(staffs.salary) > 1000 OR state IS NOT NULL) OR (city = 'Aberdeen' AND active = 1)
ORDER BY store_name asc;

set timing off;



SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());
/* 3rd QUERY */
set timing on;
EXPLAIN PLAN FOR
SELECT  products.product_id, products.product_name, products.list_price, 
        orders.order_date, orders.required_date, orders.order_status,
        categories.category_name, brands.brand_name, quantity_id,
        
        discount,COUNT(quantity_id) quantity_count, (quantity_id * discount * products.list_price) total
FROM MUTABAY.order_items order_items
    full outer join MUTABAY.orders orders on 
        (orders.order_id = order_items.order_id)
    full outer join MUTABAY.products products on 
        (products.product_id = order_items.product_id)
    full outer join MUTABAY.brands brands on
        (brands.brand_id = products.brand_id)
    full outer join MUTABAY.categories categories on
        (categories.category_id = products.category_id)
    full outer join MUTABAY.staffs staffs on
        (staffs.staff_id = orders.staff_id)
    WHERE   (shipped_date  - order_date ) > 2 
        OR
        (shipped_date - order_date ) = 0  
        OR
        (shipped_date - order_date ) < 0  

GROUP BY products.product_id, products.product_name, products.list_price, 
       orders.order_date, orders.required_date, orders.order_status,
       categories.category_name, brands.brand_name, quantity_id,
       discount
having AVG(list_price) > 10000
Order by order_status;

set timing off;



SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* 3RD QUERY PARTITIONED EDITION FOR COMPARISON */
set timing on;
EXPLAIN PLAN FOR
SELECT  products.product_id, products.product_name, products.list_price, 
        orders.order_date, orders.required_date, orders.order_status,
        categories.category_name, brands.brand_name, quantity_id,
        discount,COUNT(quantity_id) quantity_count, (quantity_id * discount * products.list_price) total
FROM MUTABAY.order_items order_items
    full outer join MUTABAY.orders_range orders on 
        (orders.order_id = order_items.order_id)
    full outer join MUTABAY.products_range products on 
        (products.product_id = order_items.product_id)
    full outer join MUTABAY.brands_hash brands on
        (brands.brand_id = products.brand_id)
    full outer join MUTABAY.categories categories on
        (categories.category_id = products.category_id)
    full outer join MUTABAY.staffs_range staffs on
        (staffs.staff_id = orders.staff_id)
WHERE   (shipped_date  - order_date ) > 2 
        OR
        (shipped_date - order_date ) = 0  
        OR
        (shipped_date - order_date ) < 0  

GROUP BY products.product_id, products.product_name, products.list_price, 
       orders.order_date, orders.required_date, orders.order_status,
       categories.category_name, brands.brand_name, quantity_id,
       discount
having AVG(list_price) > 10000
Order by order_status;

set timing off;


/* 3RD QUERY COLUMNAR STORAGE FOR COMPARISON */
set timing on;
EXPLAIN PLAN FOR
SELECT  products.product_id, products.product_name, products.list_price, 
        orders.order_date, orders.required_date, orders.order_status,
        categories.category_name, brands.brand_name, quantity_id,
        
        discount,COUNT(quantity_id) quantity_count, (quantity_id * discount * products.list_price) total
FROM MUTABAY.order_items_column order_items
    full outer join MUTABAY.orders_column orders on 
        (orders.order_id = order_items.order_id)
    full outer join MUTABAY.products_column products on 
        (products.product_id = order_items.product_id)
    full outer join MUTABAY.brands brands on
        (brands.brand_id = products.brand_id)
    full outer join MUTABAY.categories categories on
        (categories.category_id = products.category_id)
    full outer join MUTABAY.staffs_column staffs on
        (staffs.staff_id = orders.staff_id)
    WHERE   (shipped_date  - order_date ) > 2 
        OR
        (shipped_date - order_date ) = 0  
        OR
        (shipped_date - order_date ) < 0  

GROUP BY products.product_id, products.product_name, products.list_price, 
       orders.order_date, orders.required_date, orders.order_status,
       categories.category_name, brands.brand_name, quantity_id,
       discount
having AVG(list_price) > 10000
Order by order_status;

set timing off;


ROLLBACK;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/*UPDATE STATEMENT -1*/
/* 4TH QUERY */
set timing on;

EXPLAIN PLAN FOR
update MUTABAY.products products
set model_year =  
		(
            select distinct(product_id) as total_product
            from MUTABAY.order_items order_items
                full outer join MUTABAY.orders orders on
                    (orders.order_id = order_items.order_id)
                full outer join MUTABAY.stores stores on 
                    (orders.store_id = stores.store_id)
                where stores.store_id = 
                     (
                    select store_id from MUTABAY.stocks
                        full outer join MUTABAY.products products on
                            (stocks.product_id = products.product_id)
                                where ((model_year between 2020 and 1958) or (ROUND(list_price) < 990.000))
                                       or UPPER ( SUBSTR(product_name,2,3 ) )LIKE 'D%'
                                fetch first 1 rows only
                     )
            fetch first 1 rows only
		);

set timing off;

ROLLBACK;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/*UPDATE STATEMENT - 4TH QUERY PARTITIONED EDITION FOR COMPARISON*/
SET TIMING ON;
EXPLAIN PLAN FOR
update MUTABAY.products_range products
set model_year =  
		(
            select distinct(product_id) as total_product
            from MUTABAY.order_items order_items
                full outer join MUTABAY.orders_range orders on
                    (orders.order_id = order_items.order_id)
                full outer join MUTABAY.stores_hash stores_hash on 
                    (orders.store_id = stores_hash.store_id)
                where stores_hash.store_id = 
                     (
                    select store_id from MUTABAY.stocks
                        full outer join MUTABAY.products_range products on
                            (stocks.product_id = products.product_id)
                                where ((model_year between 2020 and 1958) or (ROUND(list_price) < 990.000))
                                       or UPPER ( SUBSTR(product_name,2,3 ) )LIKE 'D%'
                                fetch first 1 rows only
                     )
            fetch first 1 rows only
		);
        
SET TIMING OFF;

ROLLBACK;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());



/*UPDATE STATEMENT - 4TH QUERY COLUMNAR STORAGE EDITION FOR COMPARISON*/
set timing on;
EXPLAIN PLAN FOR
update MUTABAY.products_column products
set model_year =  
		(
            select distinct(product_id) as total_product
            from MUTABAY.order_items_column order_items
                full outer join MUTABAY.orders_column orders on
                    (orders.order_id = order_items.order_id)
                full outer join MUTABAY.stores_column stores on 
                    (orders.store_id = stores.store_id)
                where stores.store_id = 
                     (
                    select store_id from MUTABAY.stocks
                        full outer join MUTABAY.products_column products on
                            (stocks.product_id = products.product_id)
                                where ((model_year between 2020 and 1958) or (ROUND(list_price) < 990.000))
                                       or UPPER ( SUBSTR(product_name,2,3 ) )LIKE 'D%'
                                fetch first 1 rows only
                     )
            fetch first 1 rows only
		);

set timing off;

ROLLBACK;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


/* UPDATE 2*/
/* 5TH QUERY */
set timing on;

EXPLAIN PLAN FOR
update MUTABAY.order_items set quantity_id = 
(
    select quantity_id from MUTABAY.products products
    full outer join MUTABAY.order_items order_items on order_items.product_id = products.product_id
    full outer join MUTABAY.stocks stocks on stocks.product_id = products.product_id
    full outer join MUTABAY.orders orders on order_items.order_id=orders.order_id
    full outer join MUTABAY.customers customers on orders.customer_id=customers.customer_id
    full outer join MUTABAY.stores stores on orders.store_id=stores.store_id
    full outer join MUTABAY.staffs staffs on orders.staff_id=staffs.staff_id
    where products.product_id in
        (
            Select product_id from MUTABAY.order_items where order_id in 
            (
                Select order_id from MUTABAY.orders 
                WHERE 
                (order_status = 1 AND ( shipped_date - required_date = 1 ))
                OR
                (order_status = 2 AND (shipped_date - required_date = 0 ))
            )
            
        )fetch next 1 rows only 
); 

set timing off;
ROLLBACK;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/*UPDATE STATEMENT 2 - 5TH QUERY PARTITIONED EDITION FOR COMPARISON*/
set timing on;
explain plan for
update MUTABAY.order_items set quantity_id = 
(
    select quantity_id from MUTABAY.products_range products
    full outer join MUTABAY.order_items order_items on order_items.product_id = products.product_id
    full outer join MUTABAY.stocks stocks on stocks.product_id = products.product_id
    full outer join MUTABAY.orders_range orders on order_items.order_id=orders.order_id
    full outer join MUTABAY.customers_hash customers on orders.customer_id=customers.customer_id
    full outer join MUTABAY.stores stores on orders.store_id=stores.store_id
    full outer join MUTABAY.staffs_range staffs on orders.staff_id=staffs.staff_id
    where products.product_id in
        (
            Select product_id from MUTABAY.order_items where order_id in 
            (
                Select order_id from MUTABAY.orders 
                WHERE 
                (order_status = 1 AND ( shipped_date - required_date = 1 ))
                OR
                (order_status = 2 AND (shipped_date - required_date = 0 ))
            )
            
        )fetch next 1 rows only 
); 
/*
*/
set timing off;
ROLLBACK;
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* UPDATE STATEMENT 2 - 5TH QUERY COLUMNAR STORAGE EDITION FOR COMPARISON*/
set timing on;
EXPLAIN PLAN FOR
update MUTABAY.order_items_column set quantity_id = 
(
    select quantity_id from MUTABAY.products_column products
    full outer join MUTABAY.order_items_column order_items on order_items.product_id = products.product_id
    full outer join MUTABAY.stocks stocks on stocks.product_id = products.product_id
    full outer join MUTABAY.orders_column orders on order_items.order_id=orders.order_id
    full outer join MUTABAY.customers customers on orders.customer_id=customers.customer_id
    full outer join MUTABAY.stores_column stores on orders.store_id=stores.store_id
    full outer join MUTABAY.staffs_column staffs on orders.staff_id=staffs.staff_id
    where products.product_id in
        (
            Select product_id from MUTABAY.order_items_column where order_id in 
            (
                Select order_id from MUTABAY.orders_column 
                WHERE 
                (order_status = 1 AND ( shipped_date - required_date = 1 ))
                OR
                (order_status = 2 AND (shipped_date - required_date = 0 ))
            )
            
        )fetch next 1 rows only 
); 

set timing off;
/* Returns back to changing data */
ROLLBACK;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


/* UPDATE STATEMENT -3 - 6TH QUERY  */ 
set timing on;

EXPLAIN PLAN FOR

UPDATE MUTABAY.stores
SET MUTABAY.stores.store_name = (
    SELECT store_name FROM MUTABAY.stores stores
    INNER JOIN 
    (
        SELECT order_i.staff_id, first_name, last_name, phone, email, order_i.store_id, manager_id, active, salary ,
        order_i.item_id ,order_i.product_id ,order_i.quantity_id ,order_i.discount ,order_i.customer_id ,order_i.order_status ,
        order_i.order_date ,order_i.required_date ,order_i.shipped_date
        FROM MUTABAY.staffs staffs
        FULL OUTER JOIN
        (   
            SELECT orders.order_id, item_id, product_id, quantity_id, discount, orders.customer_id, orders.order_status,
                    orders.order_date, orders.required_date, orders.shipped_date, orders.store_id, orders.staff_id
            FROM MUTABAY.order_items order_items
            FULL OUTER JOIN MUTABAY.orders orders
            ON orders.order_id = order_items.order_id
            WHERE ORDERS.ORDER_ID IN (SELECT ORDER_ID FROM MUTABAY.ORDER_ITEMS WHERE DISCOUNT > (SELECT AVG(DISCOUNT) FROM MUTABAY.ORDER_ITEMS))
            OR
            (order_status = 2)
            
        ) order_i
        ON order_i.staff_id = staffs.staff_id
        WHERE (discount > 0.48 AND discount < 0.05) AND salary > 5000
        OR
        (active = 1 AND discount = 0.4)
    )order_i_staff
    ON order_i_staff.store_id = stores.store_id
    WHERE street='1 Fremont Point' or STATE IS NOT NULL 
                    fetch first 1 rows only
);

set timing off;

ROLLBACK;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

/* UPDATE STATEMENT 3 - 6TH QUERY PARTITIONED*/ 
set timing on;

EXPLAIN PLAN FOR
UPDATE MUTABAY.stores_hash
SET MUTABAY.stores_hash.store_name = (
    SELECT store_name FROM MUTABAY.stores_hash stores
    INNER JOIN 
    (
        SELECT order_i.staff_id, first_name, last_name, phone, email, order_i.store_id, manager_id, active, salary ,
        order_i.item_id ,order_i.product_id ,order_i.quantity_id ,order_i.discount ,order_i.customer_id ,order_i.order_status ,
        order_i.order_date ,order_i.required_date ,order_i.shipped_date
        FROM MUTABAY.staffs_range staffs
        FULL OUTER JOIN
        (   
            SELECT orders.order_id, item_id, product_id, quantity_id, discount, orders.customer_id, orders.order_status,
                    orders.order_date, orders.required_date, orders.shipped_date, orders.store_id, orders.staff_id
            FROM MUTABAY.order_items order_items
            FULL OUTER JOIN MUTABAY.orders_range orders
            ON orders.order_id = order_items.order_id
            WHERE ORDERS.ORDER_ID IN (SELECT ORDER_ID FROM MUTABAY.ORDER_ITEMS WHERE DISCOUNT > (SELECT AVG(DISCOUNT) FROM MUTABAY.ORDER_ITEMS))
            OR
            (order_status = 2)
            
        ) order_i
        ON order_i.staff_id = staffs.staff_id
        WHERE (discount > 0.48 AND discount < 0.05) AND salary > 5000
        OR
        (active = 1 AND discount = 0.4)
    )order_i_staff
    ON order_i_staff.store_id = stores.store_id
    WHERE street='1 Fremont Point' or STATE IS NOT NULL 
                    fetch first 1 rows only
);

set timing off;


ROLLBACK;

/* UPDATE STATEMENT 3 - 6TH QUERY COLUMNAR STORAGE*/ 
set timing on;


UPDATE MUTABAY.stores_column
SET MUTABAY.stores_column.store_name = (
    SELECT store_name FROM MUTABAY.stores_column stores
    INNER JOIN 
    (
        SELECT order_i.staff_id, first_name, last_name, phone, email, order_i.store_id, manager_id, active, salary ,
        order_i.item_id ,order_i.product_id ,order_i.quantity_id ,order_i.discount ,order_i.customer_id ,order_i.order_status ,
        order_i.order_date ,order_i.required_date ,order_i.shipped_date
        FROM MUTABAY.staffs_column staffs
        FULL OUTER JOIN
        (   
            SELECT orders.order_id, item_id, product_id, quantity_id, discount, orders.customer_id, orders.order_status,
                    orders.order_date, orders.required_date, orders.shipped_date, orders.store_id, orders.staff_id
            FROM MUTABAY.order_items_column order_items
            FULL OUTER JOIN MUTABAY.orders_column orders
            ON orders.order_id = order_items.order_id
            WHERE ORDERS.ORDER_ID IN (SELECT ORDER_ID FROM MUTABAY.ORDER_ITEMS_COLUMN WHERE DISCOUNT > (SELECT AVG(DISCOUNT) FROM MUTABAY.order_items_column))
            OR
            (order_status = 2)
            
        ) order_i
        ON order_i.staff_id = staffs.staff_id
        WHERE (discount > 0.48 AND discount < 0.05) AND salary > 5000
        OR
        (active = 1 AND discount = 0.4)
    )order_i_staff
    ON order_i_staff.store_id = stores.store_id
    WHERE street='1 Fremont Point' or STATE IS NOT NULL 
                    fetch first 1 rows only
);

set timing off;

ROLLBACK;

/* ASSIGNMENT - 13 */
/* UPDATE STATEMENT 3 - 6TH QUERY - COLUMNAR STORAGE + Partitioned */ 
set timing on;

UPDATE MUTABAY.stores_column
SET MUTABAY.stores_column.store_name = (
    SELECT store_name FROM MUTABAY.stores_column stores
    INNER JOIN 
    (
        SELECT order_i.staff_id, first_name, last_name, phone, email, order_i.store_id, manager_id, active, salary ,
        order_i.item_id ,order_i.product_id ,order_i.quantity_id ,order_i.discount ,order_i.customer_id ,order_i.order_status ,
        order_i.order_date ,order_i.required_date ,order_i.shipped_date
        FROM MUTABAY.staffs_column_partition staffs
        FULL OUTER JOIN
        (   
            SELECT orders.order_id, item_id, product_id, quantity_id, discount, orders.customer_id, orders.order_status,
                    orders.order_date, orders.required_date, orders.shipped_date, orders.store_id, orders.staff_id
            FROM MUTABAY.order_items_column order_items
            FULL OUTER JOIN MUTABAY.orders_column_partition orders
            ON orders.order_id = order_items.order_id
            WHERE ORDERS.ORDER_ID IN (SELECT ORDER_ID FROM MUTABAY.ORDER_ITEMS_COLUMN WHERE DISCOUNT > (SELECT AVG(DISCOUNT) FROM MUTABAY.order_items_column))
            OR
            (order_status = 2)
            
        ) order_i
        ON order_i.staff_id = staffs.staff_id
        WHERE (discount > 0.48 AND discount < 0.05) AND salary > 5000
        OR
        (active = 1 AND discount = 0.4)
    )order_i_staff
    ON order_i_staff.store_id = stores.store_id
    WHERE street='1 Fremont Point' or STATE IS NOT NULL 
                    fetch first 1 rows only
);

set timing off;

ROLLBACK;


SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


/* DELETE */
set timing on;

DELETE FROM MUTABAY.order_items order_items
WHERE order_items.order_id = (
        SELECT order_id from MUTABAY.orders orders
            full outer join MUTABAY.customers customers on
                customers.customer_id = orders.customer_id
            where customers.street LIKE 'A%'
            FETCH FIRST 1 ROWS ONLY
            );
            
set timing off;
ROLLBACK;



/* Creating Indexes to Existing Tables*/
/* ASSIGNMENT 7 */
/* ASSIGNMENT 13 */

/* btree PRODUCTS->LIST_PRICE */
CREATE INDEX idx_btree_list_price ON MUTABAY.products(list_price);
DROP INDEX idx_btree_list_price;

CREATE INDEX idx_btree_list_price_PARTITIONED ON MUTABAY.products_range(list_price);
DROP INDEX idx_btree_list_price_PARTITIONED;

CREATE INDEX idx_btree_list_price_PARTITIONED ON MUTABAY.products_range(list_price);
DROP INDEX idx_btree_list_price_COLUMN;

/*bitmap PRODUCTS->MODEL_YEAR */
CREATE BITMAP INDEX idx_bitmap_products_model_year ON MUTABAY.products(model_year);
DROP INDEX idx_bitmap_products_model_year;

CREATE BITMAP INDEX idx_bitmap_products_model_year_PARTITIONED ON MUTABAY.products_range(model_year);
DROP INDEX idx_bitmap_products_model_year_PARTITIONED;

CREATE BITMAP INDEX idx_bitmap_products_model_year_COLUMN ON MUTABAY.products_column(model_year);
DROP INDEX idx_bitmap_products_model_year_COLUMN;

/* btree ORDERS->ORDER_DATE*/ 
CREATE INDEX idx_btree_orders_order_date_PARTITIONED ON MUTABAY.orders_range(order_date);
DROP INDEX idx_btree_orders_order_date_PARTITIONED;

CREATE INDEX idx_btree_orders_order_date_column ON MUTABAY.orders_column(order_date);
DROP INDEX idx_btree_orders_order_date_column;

/* btree ORDERS->SHIPPED_DATE*/ 
CREATE INDEX idx_btree_orders_shipped_date_PARTITIONED ON MUTABAY.orders_range(shipped_date);
DROP INDEX idx_btree_orders_shipped_date_PARTITIONED; 

/* btree ORDERS->SHIPPED_DATE*/ 
CREATE INDEX idx_btree_orders_shipped_date_column ON MUTABAY.orders_column(shipped_date);
DROP INDEX idx_btree_orders_shipped_date_column; 

/* btree ORDERS->REQUIRED_DATE*/ 
CREATE INDEX idx_btree_orders_required_date_PARTITIONED ON MUTABAY.orders_range(required_date);
DROP INDEX idx_btree_orders_required_date_PARTITIONED;

/* btree ORDERS->REQUIRED_DATE*/ 
CREATE INDEX idx_btree_orders_required_date_column ON MUTABAY.orders_column(required_date);
DROP INDEX idx_btree_orders_required_date_column;

/* bitmap ORDERS->DISCOUNT*/ 
CREATE BITMAP INDEX idx_bitmap_order_items_discount_column ON MUTABAY.order_items_column(discount);
DROP INDEX idx_bitmap_order_items_discount_column;

/* btree STAFFS-> SALARY*/ 
CREATE INDEX idx_btree_staffs_salary_PARTITIONED ON MUTABAY.staffs_range(salary);
DROP INDEX idx_btree_staffs_salary_PARTITIONED;

/* btree STAFFS-> SALARY*/ 
CREATE INDEX idx_btree_staffs_salary_column ON MUTABAY.staffs_column(salary);
DROP INDEX idx_btree_staffs_salary_column;

/* bitmap STAFFS-> ACTIVE*/ 
CREATE BITMAP INDEX idx_bitmap_staffs_active_column ON MUTABAY.staffs_column(active);
DROP INDEX idx_bitmap_staffs_active_column;

/* btree STORES-> CITY*/ 
CREATE INDEX idx_btree_store_city_column ON MUTABAY.stores_column (city);
DROP INDEX idx_btree_store_city_column;

/* bitmap ORDERS-> order_status*/
CREATE BITMAP INDEX idx_bitmap_order_status_column ON MUTABAY.ORDERS_column (order_status);
DROP INDEX idx_bitmap_order_status_column;

/* Function PRODUCTS-> PRODUCT_NAME*/ 
CREATE INDEX FBI_IDX_LOCATION_product_name_column ON MUTABAY.products_column (UPPER(SUBSTR(product_name,2,3 ))); 
--EXPLAIN PLAN FOR SELECT * FROM MUTABAY.products WHERE UPPER(product_name)=1 ; 
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());
DROP INDEX FBI_IDX_LOCATION_product_name;



/* Function STORES -> STREET*/
CREATE INDEX FBI_IDX_LOCATION_street_column ON MUTABAY.stores_column(LOWER(street)); 
EXPLAIN PLAN FOR SELECT * FROM MUTABAY.stores WHERE LOWER(street)=3 ; 
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());
DROP INDEX FBI_IDX_LOCATION_street_PARTITIONED;




SELECT 
    index_name, 
    index_type, 
    visibility, 
    status 
FROM 
    all_indexes
WHERE 
    table_name = 'STORES';

DROP INDEX IDX_BITMAP_ORDER_STATUS;

SELECT COUNT(*) FROM MUTABAY.orders_range;


/* ASSIGNMENT 9 */
/* CREATE PARTITIONED TABLES */

/* PARTITIONING */
/* 1st Partition */


CREATE TABLE MUTABAY.stores_hash(
	store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100),
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip_code VARCHAR(50)
)
PARTITION BY HASH(store_id) PARTITIONS 8;

insert into MUTABAY.stores_hash select * from MUTABAY.stores;
commit;



BEGIN
    DBMS_STATS.gather_table_stats('MUTABAY', 'STORES_HASH');
end;

UPDATE MUTABAY.orders
set order_date = to_date(order_date , 'dd-mon-YYYY');




/* 2st Partition */
ALTER TABLE MUTABAY.brands MODIFY PARTITION BY HASH(brand_id) PARTITIONS 4;

CREATE TABLE MUTABAY.brands_hash(
	brand_id INT PRIMARY KEY,
    brand_name VARCHAR (100) NOT NULL
)
PARTITION BY HASH(brand_id) PARTITIONS 4;

DROP table MUTABAY.orders_range;

/* 3rd Partition */

alter TABLE MUTABAY.orders_range modify
PARTITION BY RANGE ( order_date )
 ( PARTITION sales_q1_2017 VALUES LESS THAN (TO_DATE('1/1/2017','MM/DD/YYYY'))
 , PARTITION sales_q2_2017 VALUES LESS THAN (TO_DATE('2/2/2017','MM/DD/YYYY' ))
 , PARTITION sales_q3_2017 VALUES LESS THAN (TO_DATE('4/4/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q4_2017 VALUES LESS THAN (TO_DATE('6/6/2017' ,'MM/DD/YYYY'))
 , PARTITION sales_q5_2017 VALUES LESS THAN (TO_DATE('8/8/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q6_2017 VALUES LESS THAN (TO_DATE('10/10/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q7_2017 VALUES LESS THAN (TO_DATE('12/14/2017', 'MM/DD/YYYY'))
 );
 
insert into MUTABAY.orders_range select * from MUTABAY.orders;
commit;

SELECT * FROM MUTABAY.orders_range;


ALTER TABLE MUTABAY.orders_range ADD (shippeds_date DATE);
UPDATE MUTABAY.orders_range SET shippeds_date=TO_DATE(shipped_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_range DROP (shipped_date);
ALTER TABLE MUTABAY.orders_range RENAME COLUMN shippeds_date TO shipped_date;

ALTER TABLE MUTABAY.orders_range ADD (requireds_date DATE);
UPDATE MUTABAY.orders_range SET requireds_date=TO_DATE(required_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_range DROP (required_date);
ALTER TABLE MUTABAY.orders_range RENAME COLUMN requireds_date TO required_date;

ALTER TABLE MUTABAY.orders_range ADD (orders_date DATE);
UPDATE MUTABAY.orders_range SET orders_date=TO_DATE(order_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_range DROP (order_date);
ALTER TABLE MUTABAY.orders_range RENAME COLUMN orders_date TO order_date;


 /*4th partition*/
ALTER TABLE MUTABAY.STAFFS_RANGE MODIFY
 PARTITION BY RANGE (salary)
 ( PARTITION salary_q1 VALUES LESS THAN (6500.00)
 , PARTITION salary_q2 VALUES LESS THAN (13000.00)
 , PARTITION salary_q3 VALUES LESS THAN (18500.00)
 , PARTITION salary_q4 VALUES LESS THAN ( 25000.00 )
 ); 
 
 
 CREATE TABLE MUTABAY.staffs(
	staff_id INT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    store_id INT NOT NULL,
    manager_id INT,
    active NUMBER(3,0) NOT NULL,
    salary NUMBER,
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(manager_id) REFERENCES MUTABAY.staffs(staff_id)
);

 
 ALTER TABLE MUTABAY.STAFFS DROP PARTITION salary_q4;
 
 
 /*5th partition*/
 CREATE TABLE MUTABAY.products_range(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year INT NOT NULL,
    list_price DECIMAL (10, 2) NOT NULL,
    FOREIGN KEY(category_id) REFERENCES MUTABAY.categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY(brand_id) REFERENCES MUTABAY.brands(brand_id) ON DELETE CASCADE
)
PARTITION BY RANGE (list_price)( 
PARTITION list_price1 VALUES LESS THAN (9000)
 , PARTITION list_price2 VALUES LESS THAN (19000)
 , PARTITION list_price3 VALUES LESS THAN (29000)
 , PARTITION list_price4 VALUES LESS THAN (39000)
 , PARTITION list_price5 VALUES LESS THAN (49000)
 , PARTITION list_price6 VALUES LESS THAN (59000)
 , PARTITION list_price7 VALUES LESS THAN (69000)
 , PARTITION list_price8 VALUES LESS THAN (79000)
 , PARTITION list_price9 VALUES LESS THAN (89000)
 , PARTITION list_price10 VALUES LESS THAN ( MAXVALUE )
 ); 
 
 SELECT COUNT(*) FROM MUTABAY.products;
/* 6th partition */ 
ALTER TABLE MUTABAY.customers_hash MODIFY
PARTITION BY HASH(customer_id) PARTITIONS 8;

/* COPY DATA */  
insert into MUTABAY.staffs_column select * from MUTABAY.staffs;
commit;

SELECT COUNT(*)FROM MUTABAY.customers;

BEGIN
    DBMS_STATS.gather_table_stats('MUTABAY', 'STORES_HASH');
end;
   select count(*) from MUTABAY.products;

ALTER TABLE MUTABAY.orders DROP PARTITION
SYS_P821,
SYS_P822,
SYS_P823,
SYS_P824,
SYS_P825,
SYS_P826,
SYS_P827,
SYS_P828,
SYS_P829,
SYS_P830;

ALTER TABLE MUTABAY.orders DROP PARTITION SYS_P821;


-- COLUMN STORE MANAGEMENT--

DROP TABLE MUTABAY.products_column;


-- IN MEMORY COLUMN STORE FOR LIST_PRICE AND MODEL_YEAR FROM PRODUCTS TABLE
CREATE TABLE MUTABAY.products_column(
	product_id INT PRIMARY KEY,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year INT NOT NULL,
    list_price DECIMAL (10, 2) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    FOREIGN KEY(category_id) REFERENCES MUTABAY.categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY(brand_id) REFERENCES MUTABAY.brands(brand_id) ON DELETE CASCADE 
) INMEMORY
INMEMORY MEMCOMPRESS FOR QUERY HIGH (list_price)
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH (model_year)
NO INMEMORY(product_id, product_name, brand_id, category_id);

select table_name inmemory CAPACITY from products_colum;



insert into MUTABAY.order_items_column select * from MUTABAY.order_items;
commit;

-- IN MEMORY COLUMN STORE FOR CITY FROM STORES TABLE
CREATE TABLE MUTABAY.stores_column(
	store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(100),
    street VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip_code VARCHAR(50)
)INMEMORY
INMEMORY MEMCOMPRESS FOR QUERY HIGH (city)
NO INMEMORY(store_id, store_name, phone, email, street, state, zip_code);


DROP TABLE MUTABAY.staffs_column;

-- IN MEMORY COLUMN STORE FOR SALARY FROM STAFFS TABLE
CREATE TABLE MUTABAY.staffs_column(
	staff_id INT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    phone VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    store_id INT NOT NULL,
    manager_id INT,
    active NUMBER(3,0) NOT NULL,
    salary NUMBER,
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores_column(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(manager_id) REFERENCES MUTABAY.staffs_column(staff_id)
)INMEMORY
INMEMORY MEMCOMPRESS FOR QUERY HIGH (salary)
NO INMEMORY(staff_id, first_name, last_name, phone, email, store_id, manager_id, active);


-- IN MEMORY COLUMN STORE FOR DISCOUNT FROM ORDER_ITEMS TABLE
CREATE TABLE MUTABAY.order_items_column(
	order_id INT,
    item_id INT,
    product_id INT NOT NULL,
    quantity_id INT NOT NULL,
    discount DECIMAL (10, 2) ,
    FOREIGN KEY(order_id) REFERENCES MUTABAY.orders_column(order_id) ON DELETE CASCADE ,
    FOREIGN KEY(product_id) REFERENCES MUTABAY.products_column(product_id) ON DELETE CASCADE 
)INMEMORY
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH (discount)
NO INMEMORY(order_id, item_id, product_id, quantity_id);

DROP TABLE MUTABAY.order_items_column;

ALTER TABLE MUTABAY.orders_column ADD (shippeds_date DATE);
UPDATE MUTABAY.orders_column SET shippeds_date=TO_DATE(shipped_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column DROP (shipped_date);
ALTER TABLE MUTABAY.orders_column RENAME COLUMN shippeds_date TO shipped_date;

ALTER TABLE MUTABAY.orders_column ADD (requireds_date DATE);
UPDATE MUTABAY.orders_column SET requireds_date=TO_DATE(required_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column DROP (required_date);
ALTER TABLE MUTABAY.orders_column RENAME COLUMN requireds_date TO required_date;

ALTER TABLE MUTABAY.orders_column ADD (orders_date DATE);
UPDATE MUTABAY.orders_column SET orders_date=TO_DATE(order_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column DROP (order_date);
ALTER TABLE MUTABAY.orders_column RENAME COLUMN orders_date TO order_date;

DROP TABLE MUTABAY.orders_columnar;
-- IN MEMORY COLUMN STORE FOR ORDER_STATUS FROM ORDERS TABLE
CREATE TABLE MUTABAY.orders_column(
	order_id INT PRIMARY KEY,
    customer_id INT,
    order_status NUMBER(3,0),
	-- Order status: 1 = Pending; 2 = Processing; 3 = Rejected; 4 = Completed
    store_id INT NOT NULL,
    staff_id INT NOT NULL,
	order_date DATE ,
    required_date DATE,
    shipped_date DATE,
    FOREIGN KEY(customer_id) REFERENCES MUTABAY.customers(customer_id) ON DELETE CASCADE ,
    FOREIGN KEY(store_id) REFERENCES MUTABAY.stores_column(store_id) ON DELETE CASCADE ,
    FOREIGN KEY(staff_id) REFERENCES MUTABAY.staffs_column(staff_id) 
)INMEMORY
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH(order_status)
NO INMEMORY(order_id, customer_id, order_date, required_date, shipped_date, store_id, staff_id);


-- JOIN GROUPS --

-- JOIN GROUPS FOR ORDER_ID AS USING ORDERS TABLE AND ORDER_ITEMS TABLE
CREATE INMEMORY JOIN GROUP order_id_join (MUTABAY.orders_column(order_id), MUTABAY.order_items_column(order_id));

-- JOIN GROUPS FOR STORE_ID AS USING ORDERS TABLE AND STORES TABLE
CREATE INMEMORY JOIN GROUP store_id_join (MUTABAY.orders_column(store_id), MUTABAY.stores_column(store_id));

-- JOIN GROUPS FOR STAFF_ID AS USING STAFFS TABLE AND ORDERS TABLE
CREATE INMEMORY JOIN GROUP staff_id_join (MUTABAY.staffs_column(staff_id), MUTABAY.orders_column(staff_id));

-- JOIN GROUPS FOR PRODUCT_ID AS USING PRODUCTS TABLE AND ORDER_ITEMS TABLE
CREATE INMEMORY JOIN GROUP product_id_join (MUTABAY.products_column(product_id), MUTABAY.order_items_column(product_id));

-- JOIN GROUPS FOR CUSTOMER_ID AS USING ORDERS TABLE AND CUSTOMERS TABLE
CREATE INMEMORY JOIN GROUP customer_id_join (MUTABAY.orders_column(customer_id), MUTABAY.customers(customers_id));


ALTER SYSTEM SET INMEMORY_SIZE=100M SCOPE=SPFILE
SHOW PARAMETER INMEMORY

ALTER SYSTEM SET SGA_TARGET=3G SCOPE=SPFILE;
ALTER SYSTEM SET INMEMORY_SIZE=2G SCOPE=SPFILE;

SHOW PARAMETER INMEMORY_SIZE
SHOW SGA;

select * from v$IM_segments;

create spfile from pfile;


SELECT table_name,
       inmemory,
       inmemory_priority,
       inmemory_distribute,
       inmemory_compression,
       inmemory_duplicate  
FROM   user_tables
ORDER BY table_name;

SELECT table_name,
       segment_column_id,
       column_name,
       inmemory_compression
FROM   v$im_column_level
WHERE  table_name = 'STAFFS_COLUMN'
ORDER BY segment_column_id;

ALTER TABLE MUTABAY.orders_COLUMN 
  INMEMORY 
  MEMCOMPRESS FOR CAPACITY HIGH;
  rollback;
  
  
DROP TABLE MUTABAY.stores_column

CREATE TABLE MUTABAY.stores_column as select * from MUTABAY.stores;

ALTER TABLE MUTABAY.stores_column
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

EXPLAIN PLAN FOR
SELECT * FROM MUTABAY.stores_column;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());


SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'+ALLSTATS'));

SELECT table_name, inmemory_compression, inmemory_priority, inmemory_distribute FROM dba_tables
WHERE table_name = 'products_column';



-- FIRST ONE
CREATE TABLE MUTABAY.orders_column_partition as select * from MUTABAY.orders;

ALTER TABLE MUTABAY.orders_column_partition
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

ALTER TABLE MUTABAY.orders_column_partition MODIFY
PARTITION BY RANGE ( order_date )
 ( PARTITION sales_q1_2017 VALUES LESS THAN (TO_DATE('1/1/2017','MM/DD/YYYY'))
 , PARTITION sales_q2_2017 VALUES LESS THAN (TO_DATE('2/2/2017','MM/DD/YYYY' ))
 , PARTITION sales_q3_2017 VALUES LESS THAN (TO_DATE('4/4/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q4_2017 VALUES LESS THAN (TO_DATE('6/6/2017' ,'MM/DD/YYYY'))
 , PARTITION sales_q5_2017 VALUES LESS THAN (TO_DATE('8/8/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q6_2017 VALUES LESS THAN (TO_DATE('10/10/2017', 'MM/DD/YYYY'))
 , PARTITION sales_q7_2017 VALUES LESS THAN (TO_DATE('12/14/2017', 'MM/DD/YYYY'))
 );
 
ALTER TABLE MUTABAY.orders_column_partition ADD (shippeds_date DATE);
UPDATE MUTABAY.orders_column_partition SET shippeds_date=TO_DATE(shipped_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column_partition DROP (shipped_date);
ALTER TABLE MUTABAY.orders_column_partition RENAME COLUMN shippeds_date TO shipped_date;

ALTER TABLE MUTABAY.orders_column_partition ADD (requireds_date DATE);
UPDATE MUTABAY.orders_column_partition SET requireds_date=TO_DATE(required_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column_partition DROP (required_date);
ALTER TABLE MUTABAY.orders_column_partition RENAME COLUMN requireds_date TO required_date;

ALTER TABLE MUTABAY.orders_column_partition ADD (orders_date DATE);
UPDATE MUTABAY.orders_column_partition SET orders_date=TO_DATE(order_date,'MM/DD/YYYY');
ALTER TABLE MUTABAY.orders_column_partition DROP (order_date);
ALTER TABLE MUTABAY.orders_column_partition RENAME COLUMN orders_date TO order_date;


-- SECOND ONE
CREATE TABLE MUTABAY.products_column_partition as select * from MUTABAY.products;

ALTER TABLE MUTABAY.products_column_partition
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

ALTER TABLE MUTABAY.products_column_partition MODIFY
    PARTITION BY RANGE (list_price)( 
       PARTITION list_price1 VALUES LESS THAN (9000)
     , PARTITION list_price2 VALUES LESS THAN (19000)
     , PARTITION list_price3 VALUES LESS THAN (29000)
     , PARTITION list_price4 VALUES LESS THAN (39000)
     , PARTITION list_price5 VALUES LESS THAN (49000)
     , PARTITION list_price6 VALUES LESS THAN (59000)
     , PARTITION list_price7 VALUES LESS THAN (69000)
     , PARTITION list_price8 VALUES LESS THAN (79000)
     , PARTITION list_price9 VALUES LESS THAN (89000)
     , PARTITION list_price10 VALUES LESS THAN ( MAXVALUE )
     );


-- THIRD ONE
CREATE TABLE MUTABAY.staffs_column_partition as select * from MUTABAY.staffs;

ALTER TABLE MUTABAY.staffs_column_partition
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

ALTER TABLE MUTABAY.staffs_column_partition MODIFY
 PARTITION BY RANGE (salary)
 ( PARTITION salary_q1 VALUES LESS THAN (6500.00)
 , PARTITION salary_q2 VALUES LESS THAN (13000.00)
 , PARTITION salary_q3 VALUES LESS THAN (18500.00)
 , PARTITION salary_q4 VALUES LESS THAN ( 25000.00 )
 ); 
ALTER TABLE MUTABAY.staffs_column_partition MODIFY
       PARTITION BY HASH(store_id) PARTITIONS 8;
       
       
       
       -- FOURTH ONE
CREATE TABLE MUTABAY.customers_column_partition as select * from MUTABAY.customers;

ALTER TABLE MUTABAY.customers_column_partition
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

ALTER TABLE MUTABAY.customers_column_partition MODIFY
PARTITION BY HASH(customer_id) PARTITIONS 8;

-- FIFTH ONE
CREATE TABLE MUTABAY.brands_column_partition as select * from MUTABAY.customers;

ALTER TABLE MUTABAY.brands_column_partition
INMEMORY MEMCOMPRESS FOR CAPACITY HIGH;

ALTER TABLE MUTABAY.brands MODIFY 
    PARTITION BY HASH(brand_id) PARTITIONS 4;
ALTER TABLE MUTABAY.brands MODIFY 
    PARTITION BY HASH(brand_id) PARTITIONS 4;

