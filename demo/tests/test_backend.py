import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src-backend'))

from main import app


def test_index_endpoint(client):
    """Test the index endpoint returns running status"""
    pass


def test_tasks_get_endpoint():
    """Test GET /tasks returns empty list initially"""
    pass


def test_tasks_post_endpoint():
    """Test POST /tasks creates a new task"""
    pass


def test_tasks_delete_endpoint():
    """Test DELETE /tasks removes a task"""
    pass