---Create pivot table--- 
DROP TABLE IF EXISTS general_orders;

CREATE TABLE general_orders as
select o.*, p.person, r.returned 
from orders o 
	join people p on p.region = o.region 
	left join (
		select distinct *
		from "returns"
	) r on r.order_id = o.order_id;
 
--- Fill NA in returned-column---
update general_orders
set returned = 'No'
where returned is null;
 
---Test---
 select 
 *
 from general_orders