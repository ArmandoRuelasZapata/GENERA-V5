-- Set timeout to avoid hanging
SET statement_timeout = '15s';

-- Step 1: Show current state
SELECT id, sort_order, is_active, extra->>'source' AS source, left(title, 30) AS title, left(image_url, 60) AS image_url
FROM home_content_items i
JOIN home_sections s ON s.id = i.section_id
WHERE s.section_key = 'ads'
ORDER BY sort_order, id;

-- Step 2: Renormalize sort_order for slidertienda items (those with sort_order >= 1000)
-- They will be renumbered starting from (max_tarjeta_sort_order + 10) in steps of 10
WITH base AS (
  SELECT COALESCE(MAX(i.sort_order), 0) AS max_normal
  FROM home_content_items i
  JOIN home_sections s ON s.id = i.section_id
  WHERE s.section_key = 'ads'
    AND i.sort_order < 1000
),
ranked AS (
  SELECT i.id, ROW_NUMBER() OVER (ORDER BY i.sort_order, i.id) AS rn
  FROM home_content_items i
  JOIN home_sections s ON s.id = i.section_id
  WHERE s.section_key = 'ads'
    AND i.sort_order >= 1000
)
UPDATE home_content_items
SET sort_order = (base.max_normal + ranked.rn * 10)
FROM ranked, base
WHERE home_content_items.id = ranked.id;

-- Step 3: Confirm results
SELECT id, sort_order, is_active, extra->>'source' AS source, left(title, 30) AS title
FROM home_content_items i
JOIN home_sections s ON s.id = i.section_id
WHERE s.section_key = 'ads'
ORDER BY sort_order, id;
