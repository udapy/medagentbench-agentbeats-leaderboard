WITH expanded_submissions AS (
    SELECT
        s.agent_id,
        s.submission_id,
        
        -- Extract Task Details from the nested 'failed_tasks' list
        CAST(json_extract_scalar(task_data, '$.task_id') AS VARCHAR) as task_id,
        CAST(json_extract_scalar(task_data, '$.score') AS DOUBLE) as score,
        
        -- Calculate time per task from group-level aggregate
        -- Check for division by zero
        CASE 
            WHEN CAST(json_extract_scalar(group_data, '$.total_tasks') AS DOUBLE) > 0 
            THEN CAST(json_extract_scalar(group_data, '$.time_used') AS DOUBLE) / CAST(json_extract_scalar(group_data, '$.total_tasks') AS DOUBLE)
            ELSE 0.0 
        END as time_used,

        -- Identify task type based on task_id prefix (e.g., task1_1 -> task1)
        SPLIT_PART(CAST(json_extract_scalar(task_data, '$.task_id') AS VARCHAR), '_', 1) as task_type

    FROM submissions s
    -- 1. Unnest the top-level 'results' array to get task groups
    CROSS JOIN UNNEST(CAST(json_extract(s.results, '$.results') AS ARRAY(JSON))) AS t1(group_data)
    -- 2. Unnest the 'failed_tasks' array within each group to get individual tasks
    -- Note: 'failed_tasks' currently contains ALL tasks (pass & fail)
    CROSS JOIN UNNEST(CAST(json_extract(group_data, '$.failed_tasks') AS ARRAY(JSON))) AS t2(task_data)
    
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
