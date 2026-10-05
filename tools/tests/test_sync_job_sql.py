"""sync_job_sql: generated job task SQL matches its sources."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from tools import sync_job_sql


def test_job_sql_in_sync():
    assert sync_job_sql.main(["--check"]) == 0
