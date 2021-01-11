select 
	g_o.region, round(
	sum(sales)/
	(select sum(sales) from general_orders g_o)*100,2
					) as "Sales, %"
from general_orders g_o
 group by g_o.region
 	order by "Sales, %" desc