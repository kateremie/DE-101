select 
	date_trunc('month', order_date) ::date as date,
	round((count(distinct order_id) filter (where returned ='Yes')::numeric/count(distinct order_id)::numeric)*100, 2) as "Returned, %"
from general_orders g_o
	group by date
		order by date;
		
select
quantity::numeric
from general_orders g_o