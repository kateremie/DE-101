-- *************** SqlDBM: PostgreSQL ****************;
-- ***************************************************;


-- ************************************** calendar_dim
drop table if exists ddl.calendar_dim;

CREATE TABLE ddl.calendar_dim
(
 --date_id integer GENERATED ALWAYS AS IDENTITY PRIMARY key,
 "date" date NOT NULL,
 "year"       int4 NOT NULL,
 quarter    varchar(5) NOT NULL,
 "month"      int4 NOT NULL,
 "week"       int4 NOT NULL,
 week_day   int4 NOT null,
 weekend BOOLEAN NOT null,
 CONSTRAINT PK_calendar_dim PRIMARY KEY ( "date" )
);

--deleting rows
truncate table ddl.calendar_dim;

--insert unique values
insert into ddl.calendar_dim ("date", "year", quarter, "month", "week", week_day, weekend)
select next_day as "date", 
		extract (year from next_day) as "year", 
		EXTRACT(QUARTER from next_day) as quarter, 
		EXTRACT(month from next_day) as "month", 
		EXTRACT(week from next_day) as week, 
		EXTRACT(ISODOW from next_day) as week_day,
		  CASE
           WHEN EXTRACT(ISODOW FROM next_day) IN (6, 7) THEN TRUE
           ELSE FALSE
           END AS weekend
	from generate_series('2016-01-01'::date, '2030-12-31'::date, '1 day') next_day;

--checking
select * from ddl.calendar_dim; 

-- ************************************** customer_dim

drop table if exists ddl.customer_dim;

CREATE TABLE ddl.customer_dim
(
 customer_id   varchar(8) NOT NULL,
 customer_name varchar(22) NOT NULL,
 segment       varchar(11) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( customer_id )
);

truncate table ddl.customer_dim;

--insert unique values
insert into ddl.customer_dim (customer_id, customer_name, segment)
select customer_id, customer_name, segment from (select distinct on (customer_id) customer_id, customer_name, segment from public.orders) a;

--checking
select * from ddl.customer_dim; 

-- ************************************** geography_dim

drop table if exists ddl.geography_dim;

CREATE TABLE ddl.geography_dim
(
 geo_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 country     varchar(13) NOT NULL,
 city        varchar(17) NOT NULL,
 "state"     varchar(20) NOT NULL,
 region      varchar(7) NOT NULL,
 postal_code int4 NOT NULL
);

truncate table ddl.geography_dim;

select country, city, "state", region, postal_code
	from orders o
	where postal_code is null;

update public.orders
	set postal_code = 05401::int4
	where postal_code is null;

--insert unique values and generate id
insert into ddl.geography_dim (country, city, "state", region, postal_code)
select country, city, "state", region, postal_code from (select distinct on (postal_code) country, city, "state", region, postal_code from public.orders) a;

--checking
select * from ddl.geography_dim;

-- ************************************** manager_dim

drop table if exists ddl.manager_dim;

CREATE TABLE ddl.manager_dim
(
 manager_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 person     varchar(17) NOT NULL
);

truncate table ddl.manager_dim;

--insert unique values and generate id
insert into ddl.manager_dim (person)
select person from (select distinct person from public.people) p;

--checking
select * from ddl.manager_dim;

-- ************************************** product_dim

drop table if exists ddl.product_dim;

CREATE TABLE ddl.product_dim
(
 product_id   varchar(15) NOT NULL,
 category     varchar(15) NOT NULL,
 subcategory  varchar(11) NOT NULL,
 product_name varchar(127) NOT null,
 CONSTRAINT PK_product_dim PRIMARY KEY (product_id)
);

truncate table ddl.product_dim;

--insert unique values and generate id 43:23
insert into ddl.product_dim (product_id, category, subcategory, product_name)
select product_id, category, subcategory, product_name from (select distinct on (product_id) product_id, category, subcategory, product_name from public.orders) a;

--checking
select * from ddl.product_dim; 

-- ************************************** shippind_dim

drop table if exists ddl.shippind_dim;

CREATE TABLE ddl.shippind_dim
(
 ship_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 ship_mode varchar(14) NOT NULL
 
);

truncate table ddl.shippind_dim;

--insert unique values and generate id 43:23
insert into ddl.shippind_dim (ship_mode)
select ship_mode from (select distinct ship_mode from public.orders) a;

--checking
select * from ddl.shippind_dim; 

-- ************************************** sales_fact

drop table if exists ddl.sales_fact;

CREATE TABLE ddl.sales_fact
(
 row_id      integer NOT NULL,
 order_id    varchar(14) NOT NULL,
 sales       numeric(9,4) NOT NULL,
 quantity    int4 NOT NULL,
 order_date  date NOT NULL,
 discount    numeric(4,2) NOT NULL,
 profit      numeric(21,16) NOT NULL,
 ship_id     integer NOT NULL,
 product_id  varchar(15) NOT NULL,
 geo_id      integer NOT NULL,
 ship_date   date NOT NULL,
 customer_id varchar(8) NOT NULL,
 manager_id  integer NOT NULL,
 returned    boolean NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( row_id ),
 CONSTRAINT FK_17 FOREIGN KEY ( order_date ) REFERENCES ddl.calendar_dim ( "date" ),
 CONSTRAINT FK_18 FOREIGN KEY ( ship_date ) REFERENCES ddl.calendar_dim ( "date" ),
 CONSTRAINT FK_35 FOREIGN KEY ( ship_id ) REFERENCES ddl.shippind_dim ( ship_id ),
 CONSTRAINT FK_46 FOREIGN KEY ( geo_id ) REFERENCES ddl.geography_dim ( geo_id ),
 CONSTRAINT FK_59 FOREIGN KEY ( product_id ) REFERENCES ddl.product_dim ( product_id ),
 CONSTRAINT FK_67 FOREIGN KEY ( customer_id ) REFERENCES ddl.customer_dim ( customer_id ),
 CONSTRAINT FK_77 FOREIGN KEY ( manager_id ) REFERENCES ddl.manager_dim ( manager_id )
);

CREATE INDEX fkIdx_17 ON ddl.sales_fact
(
 order_date
);

CREATE INDEX fkIdx_18 ON ddl.sales_fact
(
 order_date
);

CREATE INDEX fkIdx_35 ON ddl.sales_fact
(
 ship_id
);

CREATE INDEX fkIdx_46 ON ddl.sales_fact
(
 geo_id
);

CREATE INDEX fkIdx_59 ON ddl.sales_fact
(
 product_id
);

CREATE INDEX fkIdx_67 ON ddl.sales_fact
(
 customer_id
);

CREATE INDEX fkIdx_77 ON ddl.sales_fact
(
 manager_id
);

truncate table ddl.sales_fact;

--44:50
insert into ddl.sales_fact
select
	distinct on (o.row_id) o.row_id,
	o.order_id,
	o.sales,
	o.quantity,
	o.order_date,
	o.discount,
	o.profit,
	s.ship_id,
	o.product_id,
	g.geo_id,
	o.ship_date,
	o.customer_id,
	m.manager_id,
	CASE
           WHEN r.returned = 'Yes' THEN TRUE
           ELSE FALSE
           END AS returned
from public.orders o
		left join ddl.shippind_dim s on o.ship_mode = s.ship_mode
		left join ddl.geography_dim g on o.postal_code = g.postal_code
		left join public.people p on o.region = p.region
		left join ddl.manager_dim m on p.person = m.person
		left join public."returns" r on o.order_id = r.order_id
	

--checking
select * from ddl.sales_fact;

--9994 total rows count for join checking