export interface RouteContext {
  req: Request;
  url: URL;
  params: Record<string, string>;
}

export type Handler = (ctx: RouteContext) => Promise<Response>;

interface Route {
  method: string;
  parts: string[];
  handler: Handler;
}

export class Router {
  private routes: Route[] = [];

  on(method: string, pattern: string, handler: Handler): this {
    this.routes.push({ method, parts: split(pattern), handler });
    return this;
  }

  get(pattern: string, handler: Handler) {
    return this.on("GET", pattern, handler);
  }
  post(pattern: string, handler: Handler) {
    return this.on("POST", pattern, handler);
  }
  patch(pattern: string, handler: Handler) {
    return this.on("PATCH", pattern, handler);
  }
  delete(pattern: string, handler: Handler) {
    return this.on("DELETE", pattern, handler);
  }

  /** Returns the handler and path parameters, `"method_not_allowed"`, or `null` when nothing matches. */
  match(method: string, path: string): { handler: Handler; params: Record<string, string> } | "method_not_allowed" | null {
    const parts = split(path);
    let pathMatched = false;
    for (const route of this.routes) {
      const params = matchParts(route.parts, parts);
      if (!params) continue;
      pathMatched = true;
      if (route.method === method) return { handler: route.handler, params };
    }
    return pathMatched ? "method_not_allowed" : null;
  }
}

function split(path: string): string[] {
  return path.split("/").filter(Boolean);
}

function matchParts(pattern: string[], actual: string[]): Record<string, string> | null {
  if (pattern.length !== actual.length) return null;
  const params: Record<string, string> = {};
  for (let i = 0; i < pattern.length; i++) {
    if (pattern[i].startsWith(":")) {
      params[pattern[i].slice(1)] = decodeURIComponent(actual[i]);
    } else if (pattern[i] !== actual[i]) {
      return null;
    }
  }
  return params;
}

/**
 * Supabase serves the function at `/functions/v1/api/...`, which reaches the function as `/api/...`.
 * `/api/v1/...` is also accepted.
 */
export function routePath(pathname: string): string {
  return pathname.replace(/^\/api(?=\/|$)/, "").replace(/^\/v1(?=\/|$)/, "") || "/";
}
