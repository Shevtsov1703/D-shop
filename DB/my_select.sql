-- Выборка продаж интернет-магазина на определенную дату
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS total_item_price
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    customers c ON o.customer_id = c.customer_id
WHERE 
    o.order_date = '2024-02-15'
ORDER BY 
    o.order_id, p.product_name;

-- Выборка покупок больше и меньше средней суммы с подсчетом количества и общей суммы
WITH order_totals AS (
    SELECT 
        o.order_id,
        o.order_date,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price) AS total_order_amount
    FROM 
        orders o
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        customers c ON o.customer_id = c.customer_id
    GROUP BY 
        o.order_id, o.order_date, c.customer_name
),
average_order AS (
    SELECT 
        AVG(total_order_amount) AS avg_order_amount
    FROM 
        order_totals
)

SELECT 
    'Above Average' AS order_category,
    COUNT(*) AS order_count,
    ROUND(SUM(total_order_amount), 2) AS total_amount,
    ROUND((SELECT avg_order_amount FROM average_order), 2) AS average_order_amount
FROM 
    order_totals, average_order
WHERE 
    total_order_amount > avg_order_amount

UNION ALL

SELECT 
    'Below Average' AS order_category,
    COUNT(*) AS order_count,
    ROUND(SUM(total_order_amount), 2) AS total_amount,
    ROUND((SELECT avg_order_amount FROM average_order), 2) AS average_order_amount
FROM 
    order_totals, average_order
WHERE 
    total_order_amount <= avg_order_amount;

-- Найти среднюю сумму продаж  определенной категории товаров / или товара за указанный промежуток времени
WITH sales_data AS (
    SELECT 
        c.category_name,
        p.product_name,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM 
        orders o
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    WHERE 
        o.order_date BETWEEN '2024-01-01' AND '2024-03-31'
        -- Необязательные фильтры для конкретизации
        AND (c.category_name = 'Электроника' OR p.product_name = 'Смартфон iPhone')
    GROUP BY 
        c.category_name, 
        p.product_name, 
        o.order_date
)

SELECT 
    category_name,
    product_name,
    COUNT(*) AS sales_count,
    ROUND(AVG(total_sales), 2) AS average_daily_sales,
    ROUND(SUM(total_sales), 2) AS total_sales_amount
FROM 
    sales_data
GROUP BY 
    category_name, 
    product_name
ORDER BY 
    average_daily_sales DESC;

-- Запрос для создания представления товаров, доступных на складе
CREATE OR REPLACE VIEW available_products AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    w.warehouse_name,
    si.quantity_in_stock,
    p.unit_price,
    CASE 
        WHEN si.quantity_in_stock > 20 THEN 'High'
        WHEN si.quantity_in_stock BETWEEN 10 AND 20 THEN 'Medium'
        WHEN si.quantity_in_stock > 0 THEN 'Low'
        ELSE 'Out of Stock'
    END AS stock_status,
    p.product_description
FROM 
    products p
JOIN 
    stock_inventory si ON p.product_id = si.product_id
JOIN 
    warehouses w ON si.warehouse_id = w.warehouse_id
JOIN 
    categories c ON p.category_id = c.category_id
WHERE 
    si.quantity_in_stock > 0
ORDER BY 
    si.quantity_in_stock DESC, 
    p.product_name;

