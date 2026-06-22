"""AquaTrack Coach Agent.

A personal hydration concierge that reasons over a user's data and takes actions
on their behalf. It connects to the AquaTrack MCP Server (``mcp_server/server.py``)
as an MCP client over stdio, exposes those tools to Claude, and runs a tool-use
loop: Claude decides which tools to call, the results flow back, and it keeps
going until it has an answer or has completed an action for the user.

This is the "Agent" piece of the capstone — meaningful, multi-step tool use —
and it consumes the "MCP Server" piece, so the two course concepts compose.

Usage (one-shot):
    python -m agent.coach_agent "Hôm nay mình uống đủ chưa?"

Usage (interactive chat):
    python -m agent.coach_agent

Environment:
    ANTHROPIC_API_KEY        Claude API key (required)
    AQUATRACK_AGENT_MODEL    Model id (default claude-sonnet-4-6)
    AQUATRACK_API_BASE_URL   Backend base URL (passed through to the MCP server)
    AQUATRACK_USER_TOKEN     User JWT access token (passed through to the MCP server)
"""

import asyncio
import os
import sys

from anthropic import AsyncAnthropic
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

MODEL = os.environ.get("AQUATRACK_AGENT_MODEL", "claude-sonnet-4-6")

# Absolute path to the MCP server entrypoint (one dir up from agent/).
_MCP_SERVER = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "mcp_server",
    "server.py",
)

SYSTEM_PROMPT = """You are AquaTrack Coach, a personal hydration concierge for ONE user.

You have tools to read the user's hydration data, check the weather, run a photo
Smart Scan, log drinks, and adjust the daily goal. Use them — never guess a
number you could look up with a tool.

How to behave:
- Reply to the user in Vietnamese (the app's language). Be concise: lead with the
  answer, then a short reason. No filler.
- TAKING AN ACTION that changes the user's data must reflect what they actually
  want:
  * Call log_water only when the user says they drank something, or confirmed a
    Smart Scan result. Never log a hypothetical.
  * Call update_daily_goal only when the user agrees to a new goal. If you think
    the goal should change, propose it and wait for a yes.
  Read-only tools (get_today_hydration, get_weekly_stats, get_weather,
  analyze_drink_photo) you may use freely whenever they help.
- When weather could matter (heat, exercise, or a goal question), check it and
  factor it into your advice.
- After any action, confirm what you did and state the user's updated progress.
"""


def _tool_result_text(result) -> str:
    """Flatten an MCP call_tool result into plain text for the tool_result block."""
    parts = []
    for block in result.content:
        text = getattr(block, "text", None)
        if text is not None:
            parts.append(text)
    return "\n".join(parts) if parts else "(no content)"


async def _run_turn(client, session, anthropic_tools, messages) -> None:
    """Drive one user turn to completion: loop until Claude stops calling tools."""
    while True:
        response = await client.messages.create(
            model=MODEL,
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            tools=anthropic_tools,
            messages=messages,
        )

        # Surface any assistant text as it arrives.
        for block in response.content:
            if block.type == "text" and block.text.strip():
                print(f"\nCoach: {block.text.strip()}")

        if response.stop_reason != "tool_use":
            break

        # Echo the assistant turn (with tool_use blocks) back into history.
        messages.append({"role": "assistant", "content": response.content})

        # Execute each requested tool via the MCP server, collect results.
        tool_results = []
        for block in response.content:
            if block.type == "tool_use":
                print(f"  [tool] {block.name}({block.input})")
                result = await session.call_tool(block.name, block.input)
                tool_results.append(
                    {
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": _tool_result_text(result),
                    }
                )

        messages.append({"role": "user", "content": tool_results})


async def main() -> None:
    one_shot = " ".join(sys.argv[1:]).strip() or None

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("ANTHROPIC_API_KEY is not set.")
    if not os.environ.get("AQUATRACK_USER_TOKEN"):
        sys.exit("AQUATRACK_USER_TOKEN is not set (the MCP server needs it).")

    client = AsyncAnthropic()
    server_params = StdioServerParameters(
        command=sys.executable,
        args=[_MCP_SERVER],
        env=dict(os.environ),  # pass through API base URL + user token
    )

    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = (await session.list_tools()).tools
            anthropic_tools = [
                {
                    "name": t.name,
                    "description": t.description or "",
                    "input_schema": t.inputSchema,
                }
                for t in tools
            ]
            print(f"AquaTrack Coach ready ({MODEL}) — {len(anthropic_tools)} tools.")

            messages: list = []

            if one_shot:
                messages.append({"role": "user", "content": one_shot})
                await _run_turn(client, session, anthropic_tools, messages)
                return

            print("Type a message (Ctrl-C to quit).")
            while True:
                try:
                    user_text = (await asyncio.to_thread(input, "\nYou: ")).strip()
                except (EOFError, KeyboardInterrupt):
                    print("\nBye.")
                    return
                if not user_text:
                    continue
                messages.append({"role": "user", "content": user_text})
                await _run_turn(client, session, anthropic_tools, messages)


if __name__ == "__main__":
    asyncio.run(main())
