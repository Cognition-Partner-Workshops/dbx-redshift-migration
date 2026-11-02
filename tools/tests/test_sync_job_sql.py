"""Job SQL wrappers must match the unit SQL they wrap."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from tools import sync_job_sql


def test_job_sql_wrappers_are_in_sync():
    assert sync_job_sql.staleWrappers() == []
