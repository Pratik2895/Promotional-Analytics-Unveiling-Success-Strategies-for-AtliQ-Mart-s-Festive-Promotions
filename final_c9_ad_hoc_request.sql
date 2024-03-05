
-- BR1 --

SELECT
distinct dp.product_name,
    dp.product_code,
 dp.category,
    fe.base_price,
    fe.promo_type
FROM
   fact_events fe 
JOIN
    dim_products dp ON dp.product_code = fe.product_code
WHERE
    fe.base_price > 500 AND fe.promo_type='BOGOF';
    
    
    
-- BR2 --
SELECT
    distinct de.city,
    COUNT(distinct fe.store_id) AS store_count
FROM
    fact_events fe
join 
	dim_stores de on fe.store_id=de.store_id
GROUP BY
    city
ORDER by store_count desc
;




-- BR3  --



select * from 
fact_events;


with cte as (

select * ,
    (CASE promo_type
        WHEN 'BOGOF' THEN base_price * 0.5
        WHEN '25% OFF' THEN base_price * 0.75
        WHEN '50% OFF' THEN base_price * 0.5
        WHEN '33% OFF' THEN base_price * 0.67
        WHEN '500 Cashback' THEN base_price - 500
        ELSE base_price
    END) as promotional_price ,
    
(CASE promo_type
        WHEN 'BOGOF' THEN `quantity_sold(after_promo)` * 2
        ELSE `quantity_sold(after_promo)`
    END) as new_quantity,
    base_price*`quantity_sold(before_promo)` as  revenue_before_pramotion
    
from fact_events)
    
    



select * , new_quantity*promotional_price as revenue_after_pramotion
from cte ;




select  dc.campaign_name, sum(revenue_before_pramotion) as total_revenue_bp, sum(revenue_after_pramotion) as total_revenue_ap
 from promotional_price pp
 join dim_campaigns dc 
 on pp.campaign_id=dc.campaign_id
 group by dc.campaign_name
;

-- B4 --
SELECT
    dp.category,SUM(new_quantity) as Total_quantity_sold_after_promo,SUM(`quantity_sold(before_promo)`) as Total_quantity_sold_before_promo,
    
        ((SUM(new_quantity) - SUM(`quantity_sold(before_promo)`) )/ SUM(`quantity_sold(before_promo)`)
        * 100) AS isu_percentage,
    RANK() OVER (ORDER BY ((SUM(new_quantity) - SUM(`quantity_sold(before_promo)`) )/ SUM(`quantity_sold(before_promo)`)
        * 100) DESC) AS rank_order
FROM
  dim_campaigns dc  
join  promotional_price pp
on pp.campaign_id = dc.campaign_id
join dim_products dp
on dp.product_code= pp.product_code
where dc.campaign_name='Diwali'
GROUP BY
    dp.category
ORDER BY
    rank_order;
    
-- B5 --
with cte as (
 SELECT
   dp.product_name, 
   dp.category,
   -- SUM(revenue_before_pramotion) as TOTAL_REVENUE_BP ,
   -- SUM(revenue_after_pramotion) AS TOTAL_REVENUE_AP ,
   dc.campaign_name,
	((SUM(revenue_after_pramotion) - SUM(revenue_before_pramotion) )/ SUM(revenue_before_pramotion)
        * 100) AS ir_percentage,
    RANK() OVER (partition by campaign_name ORDER BY ((SUM(revenue_after_pramotion) - SUM(revenue_before_pramotion) )/ SUM(revenue_before_pramotion)
        * 100) DESC) AS rank_order
FROM
  dim_campaigns dc  
join  promotional_price pp
on pp.campaign_id = dc.campaign_id
join dim_products dp
on dp.product_code= pp.product_code
GROUP BY
    dp.product_name, dp.category,dc.campaign_name
    
)
select *  from cte 
where rank_order < 6;