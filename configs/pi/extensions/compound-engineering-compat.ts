import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { fileURLToPath } from "node:url"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { Type } from "@sinclair/typebox"

const MAX_BYTES = 50 * 1024

function truncate(value: string): string {
  const input = value ?? ""
  if (Buffer.byteLength(input, "utf8") <= MAX_BYTES) return input
  const head = input.slice(0, MAX_BYTES)
  return head + "\n\n[Output truncated to 50KB]"
}

function resolveBundledMcporterConfigPath(): string | undefined {
  try {
    const extensionDir = path.dirname(fileURLToPath(import.meta.url))
    const candidates = [
      path.join(extensionDir, "..", "pi-resources", "compound-engineering", "mcporter.json"),
      path.join(extensionDir, "..", "compound-engineering", "mcporter.json"),
    ]

    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) return candidate
    }
  } catch {
    // noop: bundled path is best-effort fallback
  }

  return undefined
}

function resolveMcporterConfigPath(cwd: string, explicit?: string): string | undefined {
  if (explicit && explicit.trim()) {
    return path.resolve(explicit)
  }

  const projectPath = path.join(cwd, ".pi", "compound-engineering", "mcporter.json")
  if (fs.existsSync(projectPath)) return projectPath

  const globalPath = path.join(os.homedir(), ".pi", "agent", "compound-engineering", "mcporter.json")
  if (fs.existsSync(globalPath)) return globalPath

  return resolveBundledMcporterConfigPath()
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user_question",
    label: "Ask User Question",
    description: "Ask the user a question with optional choices.",
    parameters: Type.Object({
      question: Type.String({ description: "Question shown to the user" }),
      options: Type.Optional(Type.Array(Type.String(), { description: "Selectable options" })),
      allowCustom: Type.Optional(Type.Boolean({ default: true })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) {
        return {
          isError: true,
          content: [{ type: "text", text: "UI is unavailable in this mode." }],
          details: {},
        }
      }

      const options = params.options ?? []
      const allowCustom = params.allowCustom ?? true

      if (options.length === 0) {
        const answer = await ctx.ui.input(params.question)
        if (!answer) {
          return {
            content: [{ type: "text", text: "User cancelled." }],
            details: { answer: null },
          }
        }

        return {
          content: [{ type: "text", text: "User answered: " + answer }],
          details: { answer, mode: "input" },
        }
      }

      const customLabel = "Other (type custom answer)"
      const selectable = allowCustom ? [...options, customLabel] : options
      const selected = await ctx.ui.select(params.question, selectable)

      if (!selected) {
        return {
          content: [{ type: "text", text: "User cancelled." }],
          details: { answer: null },
        }
      }

      if (selected === customLabel) {
        const custom = await ctx.ui.input("Your answer")
        if (!custom) {
          return {
            content: [{ type: "text", text: "User cancelled." }],
            details: { answer: null },
          }
        }

        return {
          content: [{ type: "text", text: "User answered: " + custom }],
          details: { answer: custom, mode: "custom" },
        }
      }

      return {
        content: [{ type: "text", text: "User selected: " + selected }],
        details: { answer: selected, mode: "select" },
      }
    },
  })

  pi.registerTool({
    name: "mcporter_list",
    label: "MCPorter List",
    description: "List tools on an MCP server through MCPorter.",
    parameters: Type.Object({
      server: Type.String({ description: "Configured MCP server name" }),
      allParameters: Type.Optional(Type.Boolean({ default: false })),
      json: Type.Optional(Type.Boolean({ default: true })),
      configPath: Type.Optional(Type.String({ description: "Optional mcporter config path" })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const args = ["list", params.server]
      if (params.allParameters) args.push("--all-parameters")
      if (params.json ?? true) args.push("--json")

      const configPath = resolveMcporterConfigPath(ctx.cwd, params.configPath)
      if (configPath) {
        args.push("--config", configPath)
      }

      const result = await pi.exec("mcporter", args, { signal })
      const output = truncate(result.stdout || result.stderr || "")

      return {
        isError: result.code !== 0,
        content: [{ type: "text", text: output || "(no output)" }],
        details: {
          exitCode: result.code,
          command: "mcporter " + args.join(" "),
          configPath,
        },
      }
    },
  })

  pi.registerTool({
    name: "mcporter_call",
    label: "MCPorter Call",
    description: "Call a specific MCP tool through MCPorter.",
    parameters: Type.Object({
      call: Type.Optional(Type.String({ description: "Function-style call, e.g. linear.list_issues(limit: 5)" })),
      server: Type.Optional(Type.String({ description: "Server name (if call is omitted)" })),
      tool: Type.Optional(Type.String({ description: "Tool name (if call is omitted)" })),
      args: Type.Optional(Type.Record(Type.String(), Type.Any(), { description: "JSON arguments object" })),
      configPath: Type.Optional(Type.String({ description: "Optional mcporter config path" })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const args = ["call"]

      if (params.call && params.call.trim()) {
        args.push(params.call.trim())
      } else {
        if (!params.server || !params.tool) {
          return {
            isError: true,
            content: [{ type: "text", text: "Provide either call, or server + tool." }],
            details: {},
          }
        }
        args.push(params.server + "." + params.tool)
        if (params.args) {
          args.push("--args", JSON.stringify(params.args))
        }
      }

      args.push("--output", "json")

      const configPath = resolveMcporterConfigPath(ctx.cwd, params.configPath)
      if (configPath) {
        args.push("--config", configPath)
      }

      const result = await pi.exec("mcporter", args, { signal })
      const output = truncate(result.stdout || result.stderr || "")

      return {
        isError: result.code !== 0,
        content: [{ type: "text", text: output || "(no output)" }],
        details: {
          exitCode: result.code,
          command: "mcporter " + args.join(" "),
          configPath,
        },
      }
    },
  })
}
