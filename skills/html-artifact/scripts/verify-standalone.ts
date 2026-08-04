const minInlineStyleChars = 200;

function problems(html: string): string[] {
  const found: string[] = [];

  if (!/^\s*<!doctype html\b/i.test(html)) {
    found.push("missing <!doctype html>");
  }
  if (!/<html\b[^>]*\blang\s*=\s*(?:"[^"]+"|'[^']+'|[^\s>]+)/i.test(html)) {
    found.push("missing <html lang>");
  }
  if (!/<title\b[^>]*>\s*\S[\s\S]*?<\/title>/i.test(html)) {
    found.push("missing <title>");
  }
  if (!/<main\b[^>]*>/i.test(html)) found.push("missing <main>");

  const styleChars = [...html.matchAll(/<style\b[^>]*>([\s\S]*?)<\/style>/gi)]
    .reduce((total, match) => total + match[1].trim().length, 0);
  if (styleChars < minInlineStyleChars) {
    found.push(
      `needs at least ${minInlineStyleChars} characters of inline CSS`,
    );
  }

  for (const tag of html.matchAll(/<link\b[^>]*>/gi)) {
    const rel = tag[0].match(/\brel\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i);
    const value = rel?.[1] ?? rel?.[2] ?? rel?.[3] ?? "";
    if (value.toLowerCase().split(/\s+/).includes("stylesheet")) {
      found.push('contains <link rel="stylesheet">');
    }
  }
  if (/<script\b[^>]*\bsrc\s*=/i.test(html)) {
    found.push("contains <script src>");
  }

  return found;
}

if (Deno.args.length === 0) {
  console.error(
    "usage: deno run --allow-read verify-standalone.ts <html-path> [...html-path]",
  );
  Deno.exit(2);
}

let failed = false;
for (const path of Deno.args) {
  try {
    const found = problems(await Deno.readTextFile(path));
    if (found.length === 0) {
      console.log(`${path}: standalone`);
    } else {
      failed = true;
      console.error(`${path}: ${found.join("; ")}`);
    }
  } catch (error) {
    failed = true;
    console.error(
      `${path}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

if (failed) Deno.exit(1);
