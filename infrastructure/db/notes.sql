-- CHECKING FOR INCONSISTENCIES OR DUPLICATION

SELECT local_beneficiary_id, COUNT(DISTINCT age_group)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT age_group) > 1;
-- returned 0 rows

SELECT local_beneficiary_id, Count(DISTINCT gender)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT gender) > 1;
-- returned 92 rows; affects 650 scores

UPDATE scores_by_child
    SET gender = 'unknown'
    WHERE local_beneficiary_id IN (
        SELECT local_beneficiary_id
        FROM scores_by_child
        GROUP BY local_beneficiary_id
        HAVING Count(DISTINCT gender) > 1);

SELECT local_beneficiary_id, Count(DISTINCT fcp_id)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT fcp_id) > 1;
-- returned 0 rows

SELECT local_beneficiary_id, Count(DISTINCT region)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT region) > 1;
-- returned 0 rows

SELECT local_beneficiary_id
FROM scores_by_child
WHERE ci_natl_office_name != 'Wakanda';
-- returned 0 rows

SELECT DISTINCT local_beneficiary_id, variable_code, Count(score_id)
FROM scores_by_child
GROUP BY local_beneficiary_id, variable_code
HAVING Count(score_id) > 1;
-- returned 0 rows

-- standardizing scores so they are all scored out of a common range.
UPDATE scores_by_child
SET normalized_score = score;

UPDATE scores_by_child
SET normalized_score = score/4
WHERE variable_code IN ('EDU_SOFT_HOTS_AVG', 'EDU_SOFT_SCS_AVG');

-- understanding NEET score
SELECT local_beneficiary_id, variable_name, normalized_score
FROM scores_by_child
INNER JOIN variable_names vn on scores_by_child.variable_code = vn.variable_code
WHERE local_beneficiary_id IN (
    SELECT local_beneficiary_id
    FROM scores_by_child
    WHERE age_group = '15-18'
      AND variable_code = 'EDU_WORK_NEET'
      AND score = 1
)
ORDER BY local_beneficiary_id;

-- determine number of beneficiaries in each age group
SELECT age_group, Count(DISTINCT local_beneficiary_id)
FROM scores_by_child
GROUP BY age_group
