/********** CHECKING FOR INCONSISTENCIES OR DUPLICATION **********/

-- find any beneficiaries who have records for more than one age group
SELECT local_beneficiary_id, COUNT(DISTINCT age_group)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT age_group) > 1;
-- returned 0 rows

-- find any beneficiaries who have records for more than one gender
SELECT local_beneficiary_id, Count(DISTINCT gender)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT gender) > 1;
-- returned 92 rows; affects 650 scores

-- mark all beneficiaries with records for more than one gender as gender 'unknown'
UPDATE scores_by_child
    SET gender = 'unknown'
    WHERE local_beneficiary_id IN (
        SELECT local_beneficiary_id
        FROM scores_by_child
        GROUP BY local_beneficiary_id
        HAVING Count(DISTINCT gender) > 1);

-- find any beneficiaries who have records for more than one fcp_id
SELECT local_beneficiary_id, Count(DISTINCT fcp_id)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT fcp_id) > 1;
-- returned 0 rows

-- find any beneficiaries who have records for more than one region
SELECT local_beneficiary_id, Count(DISTINCT region)
FROM scores_by_child
GROUP BY local_beneficiary_id
HAVING Count(DISTINCT region) > 1;
-- returned 0 rows

-- find any beneficiaries who have records with national office other than Wakanda
SELECT local_beneficiary_id
FROM scores_by_child
WHERE ci_natl_office_name != 'Wakanda';
-- returned 0 rows

-- find any beneficiaries who have more than a single record for each self-sufficiency variable
SELECT DISTINCT local_beneficiary_id, variable_code, Count(score_id)
FROM scores_by_child
GROUP BY local_beneficiary_id, variable_code
HAVING Count(score_id) > 1;
-- returned 0 rows

/********** standardizing scores so they are all scored out of a common range. **********/

-- add new column
ALTER TABLE scores_by_child
ADD column normalized_score decimal;

-- default column to score
UPDATE scores_by_child
SET normalized_score = score;

-- if variable code for a given record is a variable scored out of 1-4 scale, normalize score by dividing score by 4
-- NOTE: opting to divide score by 4 instead of multiplying binary scores by 4 to reduce the impact of positive answers 
-- (i.e. binary score of yes could represent "4" while no still represents "0")
UPDATE scores_by_child
SET normalized_score = score/4
WHERE variable_code IN ('EDU_SOFT_HOTS_AVG', 'EDU_SOFT_SCS_AVG');

/********** checking representation **********/

-- gender
SELECT gender, Count(score_id)
FROM scores_by_child
GROUP BY gender;

SELECT gender, Count(DISTINCT local_beneficiary_id)
FROM scores_by_child
GROUP BY gender;

-- age group
SELECT age_group, Count(score_id)
FROM scores_by_child
GROUP BY age_group;

SELECT age_group, Count(DISTINCT local_beneficiary_id)
FROM scores_by_child
GROUP BY age_group;

-- region
SELECT region, Count(score_id)
FROM scores_by_child
GROUP BY region;

SELECT region, Count(DISTINCT local_beneficiary_id)
FROM scores_by_child
GROUP BY region;

SELECT region, Count(DISTINCT fcp_id), COUNT(DISTINCT local_beneficiary_id), Count(score_id)
FROM scores_by_child
GROUP BY region;

-- overall avg score per variable
SELECT vn.variable_name, avg(normalized_score)
FROM scores_by_child
INNER JOIN variable_names vn on scores_by_child.variable_code = vn.variable_code
GROUP BY vn.variable_code;

-- create view containing overall avg and stddev for each variable
CREATE OR REPLACE VIEW code_with_avg_and_stddev(variable_code, avg, stddev, avg_normalized, stddev_normalized) as
SELECT scores_by_child.variable_code,
       avg(scores_by_child.score)    AS avg,
       stddev(scores_by_child.score) AS stddev,
       avg(scores_by_child.normalized_score)    AS avg_normalized,
       stddev(scores_by_child.normalized_score) AS stddev_normalized
FROM scores_by_child
GROUP BY scores_by_child.variable_code;

/********** Look for missing data **********/
-- determine data present by age group
SELECT variable_code,
       SUM(CASE age_group WHEN '6-8' THEN 1 ELSE 0 END) AS "6-8",
       SUM(CASE age_group WHEN '9-11' THEN 1 ELSE 0 END) AS "9-11",
       SUM(CASE age_group WHEN '12-14' THEN 1 ELSE 0 END) AS "12-14",
       SUM(CASE age_group WHEN '15-18' THEN 1 ELSE 0 END) AS "15-18",
       SUM(CASE age_group WHEN '19+' THEN 1 ELSE 0 END) AS "19+"
FROM scores_by_child
GROUP BY variable_code
ORDER BY variable_code;

-- determine data present by region
SELECT variable_code,
       SUM(CASE region WHEN 'T''Challa' THEN 1 ELSE 0 END) AS "T'Challa",
       SUM(CASE region WHEN 'Shuri' THEN 1 ELSE 0 END) AS "Shuri",
       SUM(CASE region WHEN 'Birnin Zana' THEN 1 ELSE 0 END) AS "Birnin Zana",
       SUM(CASE region WHEN 'Nakia' THEN 1 ELSE 0 END) AS "Nakia",
       SUM(CASE region WHEN 'Okoye' THEN 1 ELSE 0 END) AS "Okoye",
       SUM(CASE region WHEN 'Dora Milaje' THEN 1 ELSE 0 END) AS "Dora Milaje",
       SUM(CASE region WHEN 'Ramonda' THEN 1 ELSE 0 END) AS "Ramonda",
       SUM(CASE region WHEN 'W''Kabi' THEN 1 ELSE 0 END) AS "W'Kabi",
       SUM(CASE region WHEN 'M''Baku' THEN 1 ELSE 0 END) AS "M'Baku",
       SUM(CASE region WHEN 'N''Jobu' THEN 1 ELSE 0 END) AS "N'Jobu",
       SUM(CASE region WHEN 'Ayo' THEN 1 ELSE 0 END) AS "Ayo",
       SUM(CASE region WHEN 'T''Chaka' THEN 1 ELSE 0 END) AS "T'Chaka",
       SUM(CASE region WHEN 'Vibranium Mound' THEN 1 ELSE 0 END) AS "Vibranium Mound"
FROM scores_by_child
GROUP BY variable_code
ORDER BY variable_code;

--determine data present by gender
SELECT variable_code,
       SUM(CASE gender WHEN 'female' THEN 1 ELSE 0 END) AS "female",
       SUM(CASE gender WHEN 'male' THEN 1 ELSE 0 END) AS "male"
FROM scores_by_child
GROUP BY variable_code
ORDER BY variable_code;

/********** exploratory **********/
-- filter by age group; group by variable_name, and region
SELECT variable_name, region, avg(normalized_score), Count(score_id)
FROM scores_by_child
INNER JOIN variable_names vn on scores_by_child.variable_code = vn.variable_code
WHERE age_group = '6-8'
GROUP BY variable_name, region;


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
