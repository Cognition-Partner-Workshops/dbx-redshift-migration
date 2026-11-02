-- BI report: top affinities with product names.
SELECT b.product_id_a, b.product_id_b, pa.product_name || ' + ' || pb.product_name AS pair, b.pair_orders
FROM
    mart.basket_affinity AS b JOIN core.products AS pa ON pa.product_id = b.product_id_a JOIN core.products AS pb
    ON pb.product_id = b.product_id_b
ORDER BY b.pair_orders DESC NULLS FIRST, b.product_id_a NULLS LAST, b.product_id_b NULLS LAST
LIMIT 50;