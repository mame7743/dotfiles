/**
 * Jev decision tools (OpenCode V2 plugin).
 *
 * Registers three namespaced tools:
 *   - jev_yesno  : one explicit yes/no decision
 *   - jev_choice : one option from an explicit closed set
 *   - jev_score  : one level from an ordered rubric
 *
 * Jev is treated as an external decision service. The endpoint, model, and
 * credentials are supplied through environment variables so the same tool code
 * works with OpenCode Zen or a different provider (for example OpenRouter):
 *
 *   JEV_ENDPOINT  default: https://opencode.ai/zen/v1/systemone
 *   JEV_MODEL     default: jev-1.13-free
 *   JEV_API_KEY   optional explicit override
 *   OPENCODE_API_KEY / OPENROUTER_API_KEY  used as fallback credentials
 *
 * When none of the environment variables is set, the credential stored by
 * OpenCode itself is used instead: the `key` of the first matching provider in
 * `$XDG_DATA_HOME/opencode/auth.json` (default
 * `~/.local/share/opencode/auth.json`). Set `OPENCODE_AUTH_FILE` to override
 * that path. This keeps the plugin working out of the box on a machine where
 * `opencode auth login` has already been run, without exporting secrets into
 * the shell environment.
 *
 * Do not commit credentials. Inject them through the shell or a secret manager.
 */

import { readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

type JevDecisionType = "noul" | "choice" | "score"

type JevDecision = {
  type: JevDecisionType
  instructions: string
  criteria?: Record<string, string> | string[]
}

const DEFAULT_ENDPOINT = "https://opencode.ai/zen/v1/systemone"
const DEFAULT_MODEL = "jev-1.13-free"

// Provider ids in `auth.json`, ordered by preference. OpenCode Zen stores its
// credential under `opencode-go`; `opencode` and `openrouter` are accepted as
// fallbacks because they can also front the same endpoint.
const AUTH_PROVIDER_IDS = ["opencode-go", "opencode", "openrouter"]

function endpoint(): string {
  return process.env.JEV_ENDPOINT ?? DEFAULT_ENDPOINT
}

function model(): string {
  return process.env.JEV_MODEL ?? DEFAULT_MODEL
}

function authFile(): string {
  if (process.env.OPENCODE_AUTH_FILE) {
    return process.env.OPENCODE_AUTH_FILE
  }
  const dataHome =
    process.env.XDG_DATA_HOME ?? join(homedir(), ".local", "share")
  return join(dataHome, "opencode", "auth.json")
}

/** Read the OpenCode-managed credential, if any. Never throws. */
function authFileKey(): string | undefined {
  try {
    const parsed = JSON.parse(readFileSync(authFile(), "utf8")) as Record<
      string,
      { key?: unknown } | undefined
    >
    for (const id of AUTH_PROVIDER_IDS) {
      const key = parsed[id]?.key
      if (typeof key === "string" && key.length > 0) {
        return key
      }
    }
  } catch {
    // Missing, unreadable, or malformed auth.json: fall through to no key.
  }
  return undefined
}

function apiKey(): string | undefined {
  return (
    process.env.JEV_API_KEY ??
    process.env.OPENCODE_API_KEY ??
    process.env.OPENROUTER_API_KEY ??
    authFileKey()
  )
}

async function callJev(input: {
  state: string
  decision: JevDecision
  signal?: AbortSignal
}): Promise<string> {
  const key = apiKey()
  if (!key) {
    throw new Error(
      `Jev API key is not set. Provide JEV_API_KEY, OPENCODE_API_KEY (OpenCode Zen), or OPENROUTER_API_KEY, or run 'opencode auth login' so ${authFile()} exists.`,
    )
  }

  const response = await fetch(endpoint(), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: model(),
      state: input.state,
      questions: { decision: input.decision },
    }),
    signal: input.signal,
  })

  const body = await response.text()

  if (!response.ok) {
    throw new Error(`Jev API error ${response.status}: ${body}`)
  }

  return body
}

// Minimal local types for the OpenCode V2 plugin context. `Plugin.define` from
// `@opencode/plugin` is an identity helper, so a plain object with `id` and
// `setup` is enough and avoids a runtime dependency in this dotfiles repo.
type JevToolEditor = {
  namespace(input: { name: string; description: string }): void
  add(tool: {
    name: string
    description: string
    input: Record<string, unknown>
    options?: Record<string, unknown>
    execute(
      input: unknown,
      context: { signal?: AbortSignal },
    ): Promise<{ content: string }>
  }): void
}

type JevPluginContext = {
  tool: {
    transform(callback: (editor: JevToolEditor) => void): Promise<unknown>
  }
}

export default {
  id: "jev",
  async setup(ctx: JevPluginContext) {
    await ctx.tool.transform((editor) => {
      editor.namespace({
        name: "jev",
        description: "Jev decision tools for closed, evidence-based decisions",
      })

      editor.add({
        name: "yesno",
        description:
          "Evaluate a clearly defined yes/no decision using Jev. Supply concise factual evidence, not raw source code.",
        input: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description:
                "Concise factual state and evidence for the decision",
            },
            question: {
              type: "string",
              description: "A single unambiguous yes/no question",
            },
          },
          required: ["state", "question"],
          additionalProperties: false,
        },
        options: { namespace: "jev", codemode: true },
        async execute(args, context) {
          const input = args as { state: string; question: string }
          const content = await callJev({
            state: input.state,
            decision: { type: "noul", instructions: input.question },
            signal: context.signal,
          })
          return { content }
        },
      })

      editor.add({
        name: "choice",
        description:
          "Select one decision from explicitly defined alternatives using Jev.",
        input: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description: "Concise factual state and evidence",
            },
            question: {
              type: "string",
              description: "Question Jev should decide",
            },
            options: {
              type: "array",
              description: "Closed set of alternatives",
              items: {
                type: "object",
                properties: {
                  key: {
                    type: "string",
                    description: "Stable machine-readable option identifier",
                  },
                  description: {
                    type: "string",
                    description:
                      "Objective criterion for selecting this option",
                  },
                },
                required: ["key", "description"],
                additionalProperties: false,
              },
            },
          },
          required: ["state", "question", "options"],
          additionalProperties: false,
        },
        options: { namespace: "jev", codemode: true },
        async execute(args, context) {
          const input = args as {
            state: string
            question: string
            options: { key: string; description: string }[]
          }
          const criteria = Object.fromEntries(
            input.options.map((option) => [option.key, option.description]),
          )
          const content = await callJev({
            state: input.state,
            decision: {
              type: "choice",
              instructions: input.question,
              criteria,
            },
            signal: context.signal,
          })
          return { content }
        },
      })

      editor.add({
        name: "score",
        description:
          "Evaluate evidence against an ordered scoring rubric using Jev.",
        input: {
          type: "object",
          properties: {
            state: {
              type: "string",
              description: "Concise factual state and evidence",
            },
            question: {
              type: "string",
              description: "Quality or risk dimension to score",
            },
            levels: {
              type: "array",
              description: "Ordered rubric levels from lowest to highest",
              items: { type: "string" },
            },
          },
          required: ["state", "question", "levels"],
          additionalProperties: false,
        },
        options: { namespace: "jev", codemode: true },
        async execute(args, context) {
          const input = args as {
            state: string
            question: string
            levels: string[]
          }
          const content = await callJev({
            state: input.state,
            decision: {
              type: "score",
              instructions: input.question,
              criteria: input.levels,
            },
            signal: context.signal,
          })
          return { content }
        },
      })
    })
  },
}
