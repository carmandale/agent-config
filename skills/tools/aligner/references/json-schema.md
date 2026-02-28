# Aligner JSON Schema Reference

Complete schema for Aligner diagram files.

## Root Object

```typescript
interface AlignerDiagram {
  version: string          // Always "1.0"
  name: string             // Display name for the diagram
  type?: "flowchart" | "mockup"  // Optional, defaults to flowchart
  nodes: AlignerNode[]     // Array of nodes
  edges: AlignerEdge[]     // Array of connections
  metadata?: {
    description?: string   // What the diagram represents
    created?: string       // ISO timestamp
    modified?: string      // ISO timestamp (auto-updated by server)
  }
}
```

## Node Object

```typescript
interface AlignerNode {
  id: string               // Unique identifier (used in edge from/to)
  type: "rect" | "circle" | "diamond" | "text" | "group"
  label: string            // Display text (supports \n for newlines)
  position: {
    x: number              // X coordinate in pixels
    y: number              // Y coordinate in pixels
  }
  size?: {
    width: number          // Width in pixels (default: 150)
    height: number         // Height in pixels (default: 50)
  }
  style?: {
    fill?: string          // Background color (hex, e.g., "#dbeafe")
    stroke?: string        // Border color (hex, e.g., "#3b82f6")
    strokeWidth?: number   // Border width (default: 2)
    cornerRadius?: number  // Rounded corners for rect (default: 4)
    fontSize?: number      // Text size (default: 13)
    fontColor?: string     // Text color (default: "#000000")
  }
  comments?: Comment[]     // Threaded conversation
}
```

## Edge Object

```typescript
interface AlignerEdge {
  id: string               // Unique identifier
  from: string             // Source node ID
  to: string               // Target node ID
  type?: "arrow" | "dashed" | "line" | "orthogonal" | "curved"
  label?: string           // Text on the edge
  style?: {
    stroke?: string        // Line color
    strokeWidth?: number   // Line width
    animated?: boolean     // Animated dashes (for dashed type)
  }
}
```

## Comment Object

```typescript
interface Comment {
  from: "user" | "agent"   // Who wrote the comment
  text: string             // The comment content
}
```

## Recommended Sizes

| Node Type | Width | Height |
|-----------|-------|--------|
| rect (single line) | 150-180 | 50 |
| rect (multi-line) | 160-200 | 60-80 |
| diamond | 130-160 | 70-90 |
| circle | 60-80 | 60-80 |

## Spacing Guidelines

| Direction | Gap |
|-----------|-----|
| Vertical (between rows) | 100-120px |
| Horizontal (between columns) | 200-250px |
| Diagonal decision branches | 150px horizontal, 100px vertical |

## Color Reference

### Semantic Colors

| Purpose | Fill | Stroke |
|---------|------|--------|
| Primary action | #dbeafe | #3b82f6 |
| Success/Complete | #dcfce7 | #22c55e |
| Decision/Warning | #fef3c7 | #f59e0b |
| Error/Failure | #fee2e2 | #ef4444 |
| External system | #e0e7ff | #6366f1 |
| Neutral/Secondary | #f3f4f6 | #6b7280 |
| User action | #fce7f3 | #ec4899 |
| Data/Storage | #cffafe | #06b6d4 |

### Tailwind-based Palette

All colors use Tailwind CSS color values for consistency:

- Blue: 50 (#eff6ff) through 900 (#1e3a8a)
- Green: 50 (#f0fdf4) through 900 (#14532d)
- Yellow/Amber: 50 (#fffbeb) through 900 (#78350f)
- Red: 50 (#fef2f2) through 900 (#7f1d1d)
- Purple/Indigo: 50 (#eef2ff) through 900 (#312e81)
- Gray: 50 (#f9fafb) through 900 (#111827)
- Pink: 50 (#fdf2f8) through 900 (#831843)
- Cyan: 50 (#ecfeff) through 900 (#164e63)

## Example: Complete Diagram

```json
{
  "version": "1.0",
  "name": "Order Processing",
  "type": "flowchart",
  "nodes": [
    {
      "id": "start",
      "type": "circle",
      "label": "Order\nReceived",
      "position": { "x": 200, "y": 50 },
      "size": { "width": 70, "height": 70 },
      "style": { "fill": "#dcfce7", "stroke": "#22c55e" }
    },
    {
      "id": "validate",
      "type": "rect",
      "label": "Validate Order",
      "position": { "x": 160, "y": 160 },
      "size": { "width": 150, "height": 50 },
      "style": { "fill": "#dbeafe", "stroke": "#3b82f6", "cornerRadius": 8 }
    },
    {
      "id": "check-stock",
      "type": "diamond",
      "label": "In Stock?",
      "position": { "x": 170, "y": 260 },
      "size": { "width": 130, "height": 80 },
      "style": { "fill": "#fef3c7", "stroke": "#f59e0b" }
    },
    {
      "id": "process",
      "type": "rect",
      "label": "Process Payment",
      "position": { "x": 50, "y": 390 },
      "size": { "width": 150, "height": 50 },
      "style": { "fill": "#dbeafe", "stroke": "#3b82f6", "cornerRadius": 8 },
      "comments": [
        { "from": "user", "text": "Should we add fraud check here?" },
        { "from": "agent", "text": "Good idea - I'll add a fraud detection step before payment." }
      ]
    },
    {
      "id": "backorder",
      "type": "rect",
      "label": "Create Backorder",
      "position": { "x": 270, "y": 390 },
      "size": { "width": 150, "height": 50 },
      "style": { "fill": "#fef3c7", "stroke": "#f59e0b", "cornerRadius": 8 }
    },
    {
      "id": "ship",
      "type": "rect",
      "label": "Ship Order",
      "position": { "x": 50, "y": 490 },
      "size": { "width": 150, "height": 50 },
      "style": { "fill": "#dcfce7", "stroke": "#22c55e", "cornerRadius": 8 }
    },
    {
      "id": "notify",
      "type": "rect",
      "label": "Notify Customer",
      "position": { "x": 270, "y": 490 },
      "size": { "width": 150, "height": 50 },
      "style": { "fill": "#fce7f3", "stroke": "#ec4899", "cornerRadius": 8 }
    },
    {
      "id": "end",
      "type": "circle",
      "label": "Done",
      "position": { "x": 200, "y": 590 },
      "size": { "width": 60, "height": 60 },
      "style": { "fill": "#fee2e2", "stroke": "#ef4444" }
    }
  ],
  "edges": [
    { "id": "e1", "from": "start", "to": "validate", "type": "arrow" },
    { "id": "e2", "from": "validate", "to": "check-stock", "type": "arrow" },
    { "id": "e3", "from": "check-stock", "to": "process", "type": "arrow", "label": "Yes" },
    { "id": "e4", "from": "check-stock", "to": "backorder", "type": "arrow", "label": "No" },
    { "id": "e5", "from": "process", "to": "ship", "type": "arrow" },
    { "id": "e6", "from": "backorder", "to": "notify", "type": "arrow" },
    { "id": "e7", "from": "ship", "to": "end", "type": "arrow" },
    { "id": "e8", "from": "notify", "to": "end", "type": "dashed" }
  ],
  "metadata": {
    "description": "E-commerce order processing workflow with inventory check"
  }
}
```
