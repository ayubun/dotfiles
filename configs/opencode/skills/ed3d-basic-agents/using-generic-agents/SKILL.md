---
name: using-generic-agents
description: Use to decide what kind of basic agent you should use
---

**CRITICAL NOTE**: The operator's diretions supercedes these directions. Whenever the operator specifies a type of agent to use, you _must_ execute their task with that agent type.

## Model Characteristics

**Haiku:** Excellent at following specific, detailed instructions. Poor at making its own decisions. Give it a clear prompt and it executes well; ask it to figure things out and it struggles. Be detailed.

**Sonnet:** Capable of making decisions but gets off-track easily. Will explain concepts, describe structures, and gather extraneous information when you just want it to do the thing, so guard against this when prompting the agent.

**Opus:** Stays on-track through complex tasks. Better judgment, fewer loops. Expensive and should not be used for easy, clearly-definable tasks where Sonnet or Haiku would suffice instead.

## When to Use Each

Use `haiku-general-purpose` for:
- Extremely well scoped tasks with detailed prompts
- Execution where speed is preferable over quality
- Efficient search of summarizing of text

Use `sonnet-general-purpose` for:
- Reasoning across multiple files
- Well scoped tasks that require some judgement or thinking
- Simple coding work, like small refactors or updates

Use `opus-general-purpose` for:
- Tasks that require sustained focus and judgement
- Ambiguous tasks that require sufficient reasoning and judgement to work through
- Tasks that Sonnet has failed at multiple times
- Complex analysis of large swaths of a codebase
- High-stakes decisions that need nuance
- Medium and large sized coding tasks
