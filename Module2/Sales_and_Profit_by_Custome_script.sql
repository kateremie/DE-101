select 
	g_o.customer_name, 
	sum(sales) as Sales, 
	sum(profit) as Profit 
from general_orders g_o
group by g_o.customer_name
	order by Profit desc
limit 10