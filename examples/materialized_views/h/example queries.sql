-- Active LMS users per semester

WITH
    active_groups AS (
        SELECT
            academic_half_year,
            group_id
        FROM reporting.annotation_group_counts
        JOIN reporting.authorities ON
            authorities.id = annotation_group_counts.authority_id
            AND authorities.authority = 'lms.hypothes.is'
        WHERE group_id IS NOT NULL
        GROUP BY academic_half_year, group_id
    )

SELECT
    academic_half_year,
    COUNT(1)
FROM active_groups
JOIN user_group
    ON user_group.group_id = active_groups.group_id
GROUP BY academic_half_year
ORDER BY academic_half_year;

-- Total monthly active users

SELECT
    created_month, authority_id, COUNT(1) as active_users
FROM reporting.annotation_user_counts
GROUP BY created_month, authority_id
LIMIT 100;

---

SELECT created_week, authority, SUM(count)
FROM reporting.annotation_group_counts
JOIN reporting.authorities ON authorities.id = authority_id
WHERE group_id IS NULL
GROUP BY authority, created_week;
-- 27ms

SELECT
    academic_half_year, SUM(count)
FROM reporting.annotation_group_counts
JOIN reporting.authorities
    ON authorities.id = authority_id
    AND authority='lms.hypothes.is'
WHERE group_id IS NULL
GROUP BY academic_half_year;