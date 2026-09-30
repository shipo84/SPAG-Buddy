"use client";

import { createDemoApi } from "./demo-api";
import { createHttpApi } from "./http-api";
import { apiBaseUrl, DEMO_MODE, supabase } from "./supabase";
import type { Api } from "./types";

let instance: Api | null = null;

export function api(): Api {
  if (instance) return instance;
  instance = DEMO_MODE
    ? createDemoApi()
    : createHttpApi(apiBaseUrl(), async () => (await supabase().auth.getSession()).data.session?.access_token ?? null);
  return instance;
}
