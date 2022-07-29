-- ------------------------------------------
--                Main KPIs
-- ------------------------------------------
-- Overall satisfaction rating
SELECT 
	ROUND(AVG(sat_rating),2) AS avg_satisfaction
FROM phonenow
WHERE sat_rating != 0  					

-- Overall calls answered / abandoned
SELECT
	COUNT(call_id) AS total_calls
    , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS answered
    , COUNT(CASE WHEN answered = "N" THEN call_id ELSE NULL END) AS abandoned
FROM phonenow 				

-- Calls by time (hour of the day)
SELECT 
	HOUR(date_time) AS hr,
    COUNT(call_id) AS num_of_calls
FROM phonenow
GROUP BY 1
ORDER BY 1 		

-- Avg speed of answer for calls answered (not total calls)
SELECT 
	AVG(spd_of_ans_in_sec) AS avg_ans_speed
FROM phonenow
WHERE sat_rating != 0 	

-- Agent's performance quadrant
-- Measured by each agent's avg talk duration vs calls answered
-- STEP 1: Group total calls answered & total talk time duration (or total handle time) by agent
SELECT
	agent_name
	, COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS total_calls_answ
    , sec_to_time(SUM(time_to_sec(avg_talk_duration))) AS tht
    , SUM(time_to_sec(avg_talk_duration)) AS tht_in_sec
FROM phonenow
WHERE answered = "Y"
GROUP BY 1 
ORDER BY 1 		

-- STEP 2: Divide total handle time by total calls answered to get average handle time
SELECT
	agent_name, total_calls_answ
    , sec_to_time(ROUND((tht_in_sec / total_calls_answ),0)) AS aht       -- Average Handle Time
    , ROUND((tht_in_sec / total_calls_answ),0) AS aht_in_sec
FROM (
    SELECT
        agent_name
        , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS total_calls_answ
        , sec_to_time(SUM(time_to_sec(avg_talk_duration))) AS tht
        , SUM(time_to_sec(avg_talk_duration)) AS tht_in_sec
    FROM phonenow
    WHERE answered = "Y"
    GROUP BY 1 	
    ORDER BY 1	
) subq1


-- ------------------------------------------
--              Agent Analysis
-- ------------------------------------------

-- How many agents does the call center employ? (Ans: 8 agents)
SELECT
	COUNT(DISTINCT agent_name) AS total_agent_count
FROM phonenow 	

-- What's each agent's performance like in terms of calls answered & unanswered?
-- Num of calls answered & unanswered by agent
SELECT
	agent_name
	, COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS total_calls_answ
    , COUNT(CASE WHEN answered = "N" THEN call_id ELSE NULL END) AS total_calls_abandoned
FROM phonenow
GROUP BY 1  		

-- ------------------------------------------
--              Topic Analysis
-- ------------------------------------------

-- How many different types of calls are there within the call center?
-- Total Distinct Topics
SELECT COUNT(DISTINCT topic) AS total_num_of_topics
FROM phonenow 		

-- Total count of each topic by calls, sorted by highest calls first
SELECT
	topic,
	COUNT(topic) AS total_count
FROM phonenow
GROUP BY 1
ORDER BY 2 DESC 			


-- Temp tables to find total count of each topic by calls by hour
-- STEP 1: Create a temp table to find total calls by topic by hour
-- CREATE TEMPORARY TABLE total_calls_by_topic_hr
SELECT
	HOUR(date_time) AS hr,
	topic,
	COUNT(topic) AS total_count
FROM phonenow
GROUP BY 1, 2
ORDER BY 1, 2 

-- STEP 2: Turn STEP 1's table into a pivot table for easier viewing
SELECT
	topic
    , SUM(CASE WHEN hr = 9 THEN total_count ELSE 0 END) AS "09:00"
    , SUM(CASE WHEN hr = 10 THEN total_count ELSE 0 END) AS "10:00"
    , SUM(CASE WHEN hr = 11 THEN total_count ELSE 0 END) AS "11:00"
    , SUM(CASE WHEN hr = 12 THEN total_count ELSE 0 END) AS "12:00"
    , SUM(CASE WHEN hr = 13 THEN total_count ELSE 0 END) AS "13:00"
    , SUM(CASE WHEN hr = 14 THEN total_count ELSE 0 END) AS "14:00"
    , SUM(CASE WHEN hr = 15 THEN total_count ELSE 0 END) AS "15:00"
    , SUM(CASE WHEN hr = 16 THEN total_count ELSE 0 END) AS "16:00"
	, SUM(CASE WHEN hr = 17 THEN total_count ELSE 0 END) AS "17:00"
    , SUM(CASE WHEN hr = 18 THEN total_count ELSE 0 END) AS "18:00"
FROM total_calls_by_topic_hr
GROUP BY 1 				


-- Temp tables to find total count of each topic by calls by day of the week
-- STEP 1: Create a temp table to find total calls by topic by day of the week
-- CREATE TEMPORARY TABLE total_calls_by_topic_day
SELECT
	WEEKDAY(date_time) AS dy,
	topic,
	COUNT(topic) AS total_count
FROM phonenow
GROUP BY 1, 2
ORDER BY 1, 2 		

-- STEP 2: Turn STEP 1's table into a pivot table for easier viewing
SELECT
	topic
    , SUM(CASE WHEN dy = 0 THEN total_count ELSE 0 END) AS "Mon"
    , SUM(CASE WHEN dy = 1 THEN total_count ELSE 0 END) AS "Tue"
    , SUM(CASE WHEN dy = 2 THEN total_count ELSE 0 END) AS "Wed"
    , SUM(CASE WHEN dy = 3 THEN total_count ELSE 0 END) AS "Thur"
    , SUM(CASE WHEN dy = 4 THEN total_count ELSE 0 END) AS "Fri"
    , SUM(CASE WHEN dy = 5 THEN total_count ELSE 0 END) AS "Sat"
    , SUM(CASE WHEN dy = 6 THEN total_count ELSE 0 END) AS "Sun"
FROM total_calls_by_topic_day
GROUP BY 1 				


-- Total calls, calls answered + resolved, resolve rate, total & avg handle time 
SELECT
	topic
    , COUNT(call_id) As total_calls
    , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS calls_answ
    , COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) AS calls_res
    , CONCAT(FORMAT((COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) / 
						COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END))*100,2), "%") AS res_rt
	, sec_to_time(SUM(time_to_sec(avg_talk_duration))) AS total_time_spent
    , sec_to_time(ROUND(AVG(time_to_sec(avg_talk_duration)),0)) AS avg_time_spent 
FROM phonenow
GROUP BY 1
ORDER BY 1 	


-- ------------------------------------------
--          Calls Resolved Analysis
-- ------------------------------------------
-- Overall: total calls, total answered, answer rate, total resolved & resolved rate
SELECT 
	total_calls, answered, 
    CONCAT(ans_rate, "%") AS ans_rate,
    resolved,
    CONCAT(resolve_rate, "%") AS resolve_rate
FROM (
    SELECT
        COUNT(call_id) AS total_calls
        , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS answered
        , FORMAT((COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) / COUNT(call_id))*100,2) AS ans_rate
        , COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) AS resolved
        , FORMAT((COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) / 
                COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END))*100,2) AS resolve_rate
    FROM phonenow 		
) subq1	

-- Grouped by topic: total calls, total answered, answer rate, total resolved & resolved rate
SELECT 
	topic, total_calls, answered,
    CONCAT(ans_rate, "%") AS ans_rate,
    resolved,
    CONCAT(resolve_rate, "%") AS resolve_rate
FROM (
    SELECT
        topic,
        COUNT(call_id) AS total_calls
        , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS answered
        , FORMAT((COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) / COUNT(call_id))*100,2) AS ans_rate
        , COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) AS resolved
        , FORMAT((COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) / 
                COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END))*100,2) AS resolve_rate
    FROM phonenow 
    GROUP BY 1
    ORDER BY 6 DESC 
) subq1			

-- Grouped by agent name: total calls, total answered, answer rate, total resolved & resolved rate
SELECT 
	agent_name, total_calls, answered, 
    CONCAT(ans_rate, "%") AS ans_rate,
    resolved,
    CONCAT(resolve_rate, "%") AS resolve_rate
FROM (
    SELECT
        agent_name,
        COUNT(call_id) AS total_calls
        , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS answered
        , FORMAT((COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) / COUNT(call_id))*100,2) AS ans_rate
        , COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) AS resolved
        , FORMAT((COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) / 
                COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END))*100,2) AS resolve_rate
    FROM phonenow 
    GROUP BY 1
    ORDER BY 6 DESC 
) 	

-- Temp table + Grouped by agent name & topic: total calls, total answered, answer rate, total resolved & resolved rate 
SELECT 
	agent_name, topic, 
    CONCAT(ans_rate, "%") AS ans_rate,
    resolved,
    CONCAT(resolve_rate, "%") AS resolve_rate
FROM (
-- CREATE TEMPORARY TABLE ans_resolve_rate_by_agent_topic   -- Used for the next query.
    SELECT
        agent_name,
        topic,
        COUNT(call_id) AS total_calls
        , COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) AS answered
        , FORMAT((COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END) / COUNT(call_id))*100,2) AS ans_rate
        , COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) AS resolved
        , FORMAT((COUNT(CASE WHEN resolved = "Y" THEN call_id ELSE NULL END) / 
                COUNT(CASE WHEN answered = "Y" THEN call_id ELSE NULL END))*100,2) AS resolve_rate
    FROM phonenow 
    GROUP BY 1, 2
    ORDER BY 1, 2, 7 DESC 
) subq1

-- Pivot table for calls answered & resolved rate
SELECT
	agent_name
    , SUM(CASE WHEN topic = "Admin Support" THEN answered ELSE NULL END) AS adm_calls
    , SUM(CASE WHEN topic = "Admin Support" THEN resolve_rate ELSE NULL END) AS a_res_rt
    , SUM(CASE WHEN topic = "Contract related" THEN answered ELSE NULL END) AS cont_calls
    , SUM(CASE WHEN topic = "Contract related" THEN resolve_rate ELSE NULL END) AS c_res_rt
    , SUM(CASE WHEN topic = "Payment related" THEN answered ELSE NULL END) AS paym_calls
    , SUM(CASE WHEN topic = "Payment related" THEN resolve_rate ELSE NULL END) AS p_res_rt
    , SUM(CASE WHEN topic = "Streaming" THEN answered ELSE NULL END) AS strm_calls
    , SUM(CASE WHEN topic = "Streaming" THEN resolve_rate ELSE NULL END) AS s_res_rt
    , SUM(CASE WHEN topic = "Technical Support" THEN answered ELSE NULL END) AS tech_calls
    , SUM(CASE WHEN topic = "Technical Support" THEN resolve_rate ELSE NULL END) AS t_res_rt
FROM ans_resolve_rate_by_agent_topic
GROUP BY 1 		


-- ------------------------------------------
--           Satisfaction Analysis
-- ------------------------------------------
-- Ratings by number 1 - 5
SELECT 
    sat_rating,
    COUNT(sat_rating) AS total_count
FROM phonenow
WHERE sat_rating != 0
GROUP BY 1
ORDER BY 1 		

-- Pivot & temp table for satisfaction rating by topic
-- STEP 1: Create temp table for total ratings by topic & satisfaction number
-- CREATE TEMPORARY TABLE ratings_by_topic
SELECT 
	topic,
    sat_rating,
    COUNT(sat_rating) AS total_count
FROM phonenow
WHERE sat_rating != 0
GROUP BY 1, 2
ORDER BY 3 DESC 			

-- STEP 2: Create pivot table for STEP 1
SELECT
	topic
    , SUM(CASE WHEN sat_rating = 1 THEN total_count ELSE NULL END) AS "1"
    , SUM(CASE WHEN sat_rating = 2 THEN total_count ELSE NULL END) AS "2"
    , SUM(CASE WHEN sat_rating = 3 THEN total_count ELSE NULL END) AS "3"
    , SUM(CASE WHEN sat_rating = 4 THEN total_count ELSE NULL END) AS "4"
    , SUM(CASE WHEN sat_rating = 5 THEN total_count ELSE NULL END) AS "5"
FROM ratings_by_topic
GROUP BY 1
ORDER BY 1 				

-- Pivot & temp table for satisfaction rating by agent
--STEP 1: Create temp table for total ratings by agent & satisfaction number
-- CREATE TEMPORARY TABLE ratings_by_agent
SELECT 
	agent_name,
    sat_rating,
    COUNT(sat_rating) AS total_count
FROM phonenow
WHERE sat_rating != 0
GROUP BY 1, 2
ORDER BY 3 DESC 			

-- STEP 2: Create pivot table for STEP 1
SELECT
	agent_name
    , SUM(CASE WHEN sat_rating = 1 THEN total_count ELSE NULL END) AS "1"
    , SUM(CASE WHEN sat_rating = 2 THEN total_count ELSE NULL END) AS "2"
    , SUM(CASE WHEN sat_rating = 3 THEN total_count ELSE NULL END) AS "3"
    , SUM(CASE WHEN sat_rating = 4 THEN total_count ELSE NULL END) AS "4"
    , SUM(CASE WHEN sat_rating = 5 THEN total_count ELSE NULL END) AS "5"
FROM ratings_by_agent
GROUP BY 1
ORDER BY 1 				

-- Average Ratings by month
SELECT 
	MONTH(date_time) AS mo,
    AVG(sat_rating) AS avg_rating
FROM phonenow
WHERE sat_rating != 0 
GROUP BY 1 			