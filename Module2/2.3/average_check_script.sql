select
	g_o.customer_name,
	(sum(sales)/count(distinct order_id)) as Average_Check
from general_orders g_o
group by g_o.customer_name
	order by Average_Check desc
limit 10;

select
	g_o.state,
	(sum(sales)/count(distinct order_id)) as Average_Check
from general_orders g_o
group by g_o.state
	order by Average_Check desc
limit 10