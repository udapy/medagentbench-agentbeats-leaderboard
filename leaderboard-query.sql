-- MedAgentBench Leaderboard Query
-- "First Principles" Approach: Segment performance by distinct task types (Task 1 to Task 10)
-- to provide transparency. Missing tasks (not run) are displayed as '-'.

WITH expanded_submissions AS (
    SELECT
        s.agent_id,
        s.submission_id,
        r.task_id,
        -- Normalize score (assuming 0-1 range)
        CAST(r.score AS DOUBLE) as score,
        -- Extract execution time if available, else default to 0
        COALESCE(CAST(json_extract_scalar(r.metrics, '$.time_used') AS DOUBLE), 0.0) as time_used,
        -- Identify task type based on task_id prefix (e.g., task1_1 -> task1)
        SPLIT_PART(r.task_id, '_', 1) as task_type
    FROM submissions s
    -- Flatten the results array from the JSON payload
    CROSS JOIN UNNEST(CAST(json_extract(s.results, '$.results') AS ARRAY(JSON))) AS t(r)
    WHERE s.leaderboard_id = 'medagentbench-leaderboard'
),
agent_performance AS (
    SELECT
        agent_id,
        COUNT(*) as total_tasks,
        
        -- Overall Aggregates
        AVG(score) as overall_pass_rate,
        AVG(time_used) as avg_time_per_task,

        -- Granular Breakdowns by Task Type
        AVG(CASE WHEN task_type = 'task1' THEN score END) as task1_score,
        AVG(CASE WHEN task_type = 'task2' THEN score END) as task2_score,
        AVG(CASE WHEN task_type = 'task3' THEN score END) as task3_score,
        AVG(CASE WHEN task_type = 'task4' THEN score END) as task4_score,
        AVG(CASE WHEN task_type = 'task5' THEN score END) as task5_score,
        AVG(CASE WHEN task_type = 'task6' THEN score END) as task6_score,
        AVG(CASE WHEN task_type = 'task7' THEN score END) as task7_score,
        AVG(CASE WHEN task_type = 'task8' THEN score END) as task8_score,
        AVG(CASE WHEN task_type = 'task9' THEN score END) as task9_score,
        AVG(CASE WHEN task_type = 'task10' THEN score END) as task10_score

    FROM expanded_submissions
    GROUP BY agent_id
)
SELECT
    RANK() OVER (ORDER BY overall_pass_rate DESC, avg_time_per_task ASC) as "Rank",
    agent_id as "Agent ID",
    
    -- Formatted Scores
    FORMAT('%.1f%%', overall_pass_rate * 100) as "Pass Rate",

    -- Task Columns (Task 1 - Task 10) with '-' for NULL
    COALESCE(FORMAT('%.1f%%', task1_score * 100), '-') as "Task 1",
    COALESCE(FORMAT('%.1f%%', task2_score * 100), '-') as "Task 2",
    COALESCE(FORMAT('%.1f%%', task3_score * 100), '-') as "Task 3",
    COALESCE(FORMAT('%.1f%%', task4_score * 100), '-') as "Task 4",
    COALESCE(FORMAT('%.1f%%', task5_score * 100), '-') as "Task 5",
    COALESCE(FORMAT('%.1f%%', task6_score * 100), '-') as "Task 6",
    COALESCE(FORMAT('%.1f%%', task7_score * 100), '-') as "Task 7",
    COALESCE(FORMAT('%.1f%%', task8_score * 100), '-') as "Task 8",
    COALESCE(FORMAT('%.1f%%', task9_score * 100), '-') as "Task 9",
    COALESCE(FORMAT('%.1f%%', task10_score * 100), '-') as "Task 10",
    
    -- Efficiency
    FORMAT('%.1fs', avg_time_per_task) as "Avg Time",
    total_tasks as "Tasks Completed"
FROM agent_performance
ORDER BY overall_pass_rate DESC;
