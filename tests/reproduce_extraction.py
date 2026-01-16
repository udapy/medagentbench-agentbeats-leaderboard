
import sys
import os
import re
import json
import logging

# Mock logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Mock the structure since imports are complex with .patches
class MockAgent:
    def _grade_submission(self, task, submission_text) -> str:
        # Copied logic for testing
        submission_content = submission_text
        if submission_text.startswith("FINISH(") and submission_text.endswith(")"):
            submission_content = submission_text[7:-1]
            
        # --- FIX: ROBUST EXTRACTION FOR TASK 1 (Patient Search) ---
        task_id = task.get("id", "")
        if task_id.startswith("task1"):
             # Look for S followed by 7 digits
             match = re.search(r"\b(S\d{7})\b", submission_content)
             if match:
                 # Reformat as JSON list for the strict evaluator
                 extracted_mrn = match.group(1)
                 print(f"DEBUG: Extracted {extracted_mrn}")
                 submission_content = json.dumps([extracted_mrn])
        # ----------------------------------------------------------
        return submission_content

def test_extraction():
    agent = MockAgent()
    
    # Test Case 1: Natural Language
    task = {"id": "task1_4"}
    text = "The patient MRN is S1234567."
    result = agent._grade_submission(task, text)
    print(f"Input: {text}")
    print(f"Result: {result}")
    assert result == '["S1234567"]'
    
    # Test Case 2: Already JSON
    text = '["S1234567"]'
    result = agent._grade_submission(task, text)
    print(f"Input: {text}")
    print(f"Result: {result}")
    assert result == '["S1234567"]'

    # Test Case 3: No MRN
    text = "Patient not found"
    result = agent._grade_submission(task, text)
    print(f"Input: {text}")
    print(f"Result: {result}")
    assert result == "Patient not found"

if __name__ == "__main__":
    test_extraction()
    print("All tests passed!")
