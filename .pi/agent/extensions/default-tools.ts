import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls"];

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async () => {
    pi.setActiveTools(DEFAULT_TOOLS);
  });
}
