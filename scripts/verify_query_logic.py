import json
import os

def verify_logic():
    results_path = 'output/results.json'
    if not os.path.exists(results_path):
        print(f"File not found: {results_path}")
        return

    with open(results_path, 'r') as f:
        data = json.load(f)

    results_array = data.get('results', [])
    print(f"Found {len(results_array)} result groups.")

    extracted_rows = []

    for group_idx, group in enumerate(results_array):
        # SQL: CROSS JOIN UNNEST(results) AS t(r)
        
        # Group level metrics
        # SQL: COALESCE(CAST(json_extract_scalar(r.metrics, '$.time_used') AS DOUBLE), 0.0)
        # In new JSON, time_used is top level in the group object
        time_used_total = group.get('time_used', 0.0)
        total_tasks = group.get('total_tasks', 1) # avoid div by zero
        time_per_task = time_used_total / total_tasks if total_tasks else 0

        print(f"Group {group_idx}: time_used={time_used_total}, total_tasks={total_tasks}")

        # SQL: CROSS JOIN UNNEST(failed_tasks)
        # Note: calling it 'failed_tasks' is weird if it contains all tasks, but that's what the file shows.
        tasks = group.get('failed_tasks', [])
        print(f"  - Found {len(tasks)} nested tasks in 'failed_tasks'.")

        for task in tasks:
            task_id = task.get('task_id')
            score = float(task.get('score', 0.0))
            task_type_from_id = task_id.split('_')[0] if task_id else 'unknown'
            
            row = {
                'task_id': task_id,
                'score': score,
                'time_used': time_per_task, # Distributed time
                'task_type': task_type_from_id
            }
            extracted_rows.append(row)
            print(f"    - Extracted: {row}")

    print(f"\nTotal extracted rows: {len(extracted_rows)}")

if __name__ == "__main__":
    verify_logic()
