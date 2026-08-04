const verifier = new URL("./verify-standalone.ts", import.meta.url).pathname;

async function run(html: string): Promise<number> {
  const dir = await Deno.makeTempDir();
  try {
    const path = `${dir}/artifact.html`;
    await Deno.writeTextFile(path, html);
    const result = await new Deno.Command(Deno.execPath(), {
      args: ["run", "--allow-read", verifier, path],
      stdout: "piped",
      stderr: "piped",
    }).output();
    return result.code;
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
}

const inline =
  `<!doctype html><html lang="en"><head><title>Test</title><style>${
    ".x { color: #123; }".repeat(12)
  }</style></head><body><main>Ready</main></body></html>`;

Deno.test("accepts an inline standalone artifact", async () => {
  if (await run(inline) !== 0) {
    throw new Error("expected inline artifact to pass");
  }
});

Deno.test("rejects linked stylesheet fixtures", async () => {
  if (
    await run(
      inline.replace(
        "</head>",
        '<link rel="stylesheet" href="styles.css"></head>',
      ),
    ) === 0
  ) {
    throw new Error("expected linked stylesheet to fail");
  }
});

Deno.test("rejects external script fixtures", async () => {
  if (
    await run(
      inline.replace("</body>", '<script src="quiz.js"></script></body>'),
    ) === 0
  ) {
    throw new Error("expected external script to fail");
  }
});
