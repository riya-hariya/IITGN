-- 1
SELECT event_id, store_id, product_code,base_price,promo_type FROM fact_events WHERE base_price > 1000;

-- 2
SELECT event_id,product_code,promo_type,`quantity_sold(before_promo)`, `quantity_sold(after_promo)`
FROM fact_events WHERE `quantity_sold(after_promo)` > 100 
ORDER BY `quantity_sold(after_promo)` DESC;

-- 3
SELECT DISTINCT promo_type from fact_events;

-- 4.
SELECT COUNT(event_id), SUM(`quantity_sold(before_promo)`),
SUM(`quantity_sold(after_promo)`), AVG(base_price), MAX(base_price), MIN(base_price) from fact_events;

-- 5.
SELECT COUNT(event_id), SUM(`quantity_sold(before_promo)`), SUM(`quantity_sold(after_promo)`) FROM fact_events
GROUP BY promo_type ORDER BY SUM(`quantity_sold(after_promo)`) DESC;

-- 6
SELECT SUM(`quantity_sold(before_promo)`), SUM(`quantity_sold(after_promo)`), SUM(`quantity_sold(after_promo)`) -
SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events
GROUP BY promo_type
ORDER BY quantity_change DESC;

-- 7
SELECT f.product_code,
d.product_name,
d.category, 
SUM(f.`quantity_sold(after_promo)`) 
from fact_events as f INNER JOIN dim_products as d ON f.product_code=d.product_code 
GROUP BY f.product_code 
ORDER BY SUM(f.`quantity_sold(after_promo)`) DESC;

-- 8
SELECT d.category, COUNT(*) as number_of_events, SUM(f.`quantity_sold(before_promo)`), SUM(f.`quantity_sold(after_promo)`),
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events f
INNER JOIN dim_products d ON f.product_code = d.product_code
GROUP BY d.category
ORDER BY SUM(f.`quantity_sold(after_promo)`) DESC;

-- 9
SELECT d.city, COUNT(*) as event_count, SUM(f.`quantity_sold(before_promo)`), SUM(f.`quantity_sold(after_promo)`)
FROM fact_events f
INNER JOIN dim_stores d ON f.store_id = d.store_id
GROUP BY d.city
ORDER BY SUM(f.`quantity_sold(after_promo)`) DESC;

-- 10
SELECT d.campaign_name, d.start_date, d.end_date, COUNT(*) as event_count, SUM(f.`quantity_sold(before_promo)`) as total_before,
SUM(f.`quantity_sold(after_promo)`) as total_after FROM fact_events f INNER JOIN dim_campaigns d ON f.campaign_id = d.campaign_id 
GROUP BY d.campaign_id, d.campaign_name, d.start_date, d.end_date
ORDER BY total_after DESC;

-- 11
SELECT d.category, SUM(f.`quantity_sold(after_promo)`) as total_quantity_after_promo, AVG(f.base_price) as average_base_price
FROM fact_events f
INNER JOIN dim_products d ON f.product_code = d.product_code
GROUP BY d.category
HAVING SUM(f.`quantity_sold(after_promo)`) > 1000
ORDER BY total_quantity_after_promo DESC;


-- 12
SELECT SUM(f.`quantity_sold(after_promo)`) as total_quantity_after_promo, s.city, p.category
FROM fact_events f
INNER JOIN dim_stores s
ON f.store_id = s.store_id
INNER JOIN dim_products p
ON f.product_code = p.product_code
GROUP BY s.city, p.category
ORDER BY s.city ASC, total_quantity_after_promo DESC;

-- 13
SELECT p.product_name, p.category, SUM(f.`quantity_sold(before_promo)`) as total_before, SUM(f.`quantity_sold(after_promo)`) as total_after,
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) as quantity_change,
(( SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`)) / NULLIF(SUM(f.`quantity_sold(before_promo)`), 0)) * 100 as percentage_change
FROM fact_events f
INNER JOIN dim_products p
ON f.product_code = p.product_code
GROUP BY f.product_code, p.product_name, p.category
ORDER BY percentage_change DESC;

-- 14
SELECT c.campaign_name, f.promo_type, COUNT(*) as event_count,
SUM(f.`quantity_sold(before_promo)`) as total_before,
SUM(f.`quantity_sold(after_promo)`) as total_after,
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) as quantity_change
FROM fact_events f
INNER JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
GROUP BY c.campaign_name, f.promo_type
ORDER BY c.campaign_name ASC, quantity_change DESC;

-- 15
SELECT p.product_name, p.category, SUM(f.base_price * f.`quantity_sold(before_promo)`) as revenue_before,
SUM(f.base_price * f.`quantity_sold(after_promo)`) as revenue_after,
SUM(f.base_price * f.`quantity_sold(after_promo)`) -
SUM(f.base_price * f.`quantity_sold(before_promo)`) as revenue_difference
FROM fact_events f INNER JOIN dim_products p
ON f.product_code = p.product_code
GROUP BY f.product_code, p.product_name, p.category
ORDER BY revenue_difference DESC;

-- 16
WITH promotion_summary as (SELECT promo_type, SUM(`quantity_sold(before_promo)`) as total_before, SUM(`quantity_sold(after_promo)`) as total_after
FROM fact_events
GROUP BY promo_type
)
SELECT promo_type, total_before, total_after,
((total_after - total_before) / NULLIF(total_before, 0)) * 100 as percentage_change,
CASE WHEN ((total_after - total_before) / NULLIF(total_before, 0)) * 100 >= 50
THEN 'High Impact'
WHEN ((total_after - total_before)/ NULLIF(total_before, 0)) * 100 >= 20
THEN 'Medium Impact'
ELSE 'Low Impact'
END as performance_category
FROM promotion_summary
ORDER BY percentage_change DESC;

-- 17
WITH promotion_summary as(
SELECT f.product_code, p.product_name, p.category, SUM(f.`quantity_sold(after_promo)`) as total_quantity_after
FROM fact_events f INNER JOIN dim_products p
ON f.product_code = p.product_code
GROUP BY f.product_code, p.product_name, p.category
),
ranked_products as (
SELECT category, product_name, total_quantity_after, DENSE_RANK() OVER (
PARTITION BY category ORDER BY total_quantity_after DESC) as category_rank
FROM promotion_summary
)
SELECT category, product_name, total_quantity_after, category_rank
FROM ranked_products WHERE category_rank <= 2
ORDER BY category, category_rank;

-- 18
WITH store_summary as (SELECT f.store_id, s.city, SUM(f.`quantity_sold(after_promo)`) as total_quantity_after
FROM fact_events f
INNER JOIN dim_stores s ON f.store_id = s.store_id
GROUP BY f.store_id, s.city
),
ranked_stores as (SELECT city, store_id, total_quantity_after, DENSE_RANK() OVER (
PARTITION BY city ORDER BY total_quantity_after DESC) as city_rank
FROM store_summary
)
SELECT city, store_id, total_quantity_after, city_rank
FROM ranked_stores
WHERE city_rank <= 2
ORDER BY city, city_rank;

-- 19
WITH campaign_product_summary as (SELECT c.campaign_name, p.product_name, SUM(f.`quantity_sold(before_promo)`) as total_before,
SUM(f.`quantity_sold(after_promo)`) AS total_after,
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
((SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`))
/ NULLIF(SUM(f.`quantity_sold(before_promo)`), 0)
) * 100 as percentage_change
FROM fact_events f
INNER JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
INNER JOIN dim_products p ON f.product_code = p.product_code
GROUP BY c.campaign_id, c.campaign_name, f.product_code, p.product_name
),
ranked_products as (SELECT campaign_name, product_name, total_before, total_after,
quantity_change, percentage_change, DENSE_RANK() OVER (
PARTITION BY campaign_name ORDER BY percentage_change DESC
) as campaign_rank
FROM campaign_product_summary
)
SELECT campaign_name, product_name, total_before,total_after, quantity_change,
percentage_change, campaign_rank
FROM ranked_products
WHERE campaign_rank <= 3
ORDER BY campaign_name, campaign_rank;

-- 20
WITH product_analysis as (SELECT f.product_code, p.product_name, p.category, COUNT(*) as event_count,
SUM(f.`quantity_sold(before_promo)`) as total_before, SUM(f.`quantity_sold(after_promo)`) as total_after,
SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`) as quantity_change,
((SUM(f.`quantity_sold(after_promo)`) - SUM(f.`quantity_sold(before_promo)`)) / NULLIF(SUM(f.`quantity_sold(before_promo)`),0)) * 100 
as percentage_change, SUM(f.base_price * f.`quantity_sold(before_promo)`) AS revenue_before,
SUM(f.base_price * f.`quantity_sold(after_promo)`) as revenue_after,
SUM(f.base_price * f.`quantity_sold(after_promo)`) -
SUM(f.base_price * f.`quantity_sold(before_promo)`) as revenue_change,
AVG(f.base_price) AS average_base_price
FROM fact_events f INNER JOIN dim_products p ON f.product_code = p.product_code
GROUP BY f.product_code, p.product_name, p.category
),
ranked_products as (SELECT product_name, category,
event_count, total_before, total_after, quantity_change, percentage_change, revenue_before, revenue_after,revenue_change,average_base_price, 
DENSE_RANK() OVER (
PARTITION BY category
ORDER BY revenue_change DESC
) as product_rank
FROM product_analysis
)
SELECT product_name, category, event_count, total_before, total_after, quantity_change, percentage_change,revenue_before,
revenue_after,revenue_change,average_base_price,product_rank
FROM ranked_products
WHERE product_rank <= 2
ORDER BY category, product_rank;
