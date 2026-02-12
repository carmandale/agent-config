#!/usr/bin/env python3
"""
List all Aligner diagrams in ~/.aligner/

Usage:
    list-diagrams.py

Output:
    Shows all diagrams with their names, node counts, and comment counts.
"""

import json
from pathlib import Path


def list_diagrams() -> None:
    """List all diagrams in the Aligner directory."""
    aligner_dir = Path.home() / ".aligner"
    
    if not aligner_dir.exists():
        print("No ~/.aligner directory found")
        return
    
    json_files = list(aligner_dir.glob("*.json"))
    
    if not json_files:
        print("No diagrams found in ~/.aligner/")
        return
    
    print("Aligner Diagrams")
    print("=" * 60)
    
    for filepath in sorted(json_files):
        try:
            with open(filepath) as f:
                data = json.load(f)
            
            name = data.get("name", filepath.stem)
            nodes = data.get("nodes", [])
            edges = data.get("edges", [])
            
            # Count comments
            comment_count = sum(
                len(n.get("comments", [])) 
                for n in nodes
            )
            
            # Count nodes with comments
            nodes_with_comments = sum(
                1 for n in nodes if n.get("comments")
            )
            
            print(f"\n📊 {name}")
            print(f"   File: {filepath.name}")
            print(f"   Nodes: {len(nodes)}, Edges: {len(edges)}")
            
            if comment_count > 0:
                print(f"   💬 {comment_count} comments on {nodes_with_comments} nodes")
        
        except (json.JSONDecodeError, KeyError) as e:
            print(f"\n⚠️  {filepath.name}: Error reading - {e}")
    
    print()


if __name__ == "__main__":
    list_diagrams()
