#!/usr/bin/env python3
"""
Read comments from an Aligner diagram JSON file.

Usage:
    read-comments.py <diagram.json>
    read-comments.py ~/.aligner/my-flow.json

Output:
    Lists all nodes with comments, showing the conversation thread.
"""

import json
import sys
from pathlib import Path


def read_comments(filepath: str) -> None:
    """Read and display comments from an Aligner diagram."""
    path = Path(filepath).expanduser()
    
    if not path.exists():
        print(f"Error: File not found: {path}")
        sys.exit(1)
    
    try:
        with open(path) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON: {e}")
        sys.exit(1)
    
    diagram_name = data.get("name", path.stem)
    nodes = data.get("nodes", [])
    
    # Find nodes with comments
    commented_nodes = [n for n in nodes if n.get("comments")]
    
    if not commented_nodes:
        print(f"No comments in '{diagram_name}'")
        return
    
    print(f"Comments in '{diagram_name}':")
    print("=" * 50)
    
    for node in commented_nodes:
        label = node.get("label", node.get("id", "Unknown"))
        comments = node.get("comments", [])
        
        print(f"\n📝 {label}")
        print("-" * 40)
        
        for comment in comments:
            author = comment.get("from", "unknown")
            text = comment.get("text", "")
            
            if author == "user":
                print(f"  You: {text}")
            else:
                print(f"  Agent: {text}")
    
    print()


def main():
    if len(sys.argv) < 2:
        print("Usage: read-comments.py <diagram.json>")
        print("Example: read-comments.py ~/.aligner/my-flow.json")
        sys.exit(1)
    
    read_comments(sys.argv[1])


if __name__ == "__main__":
    main()
