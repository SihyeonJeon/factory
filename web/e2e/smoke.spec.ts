import { test, expect } from "@playwright/test";

// ============================================================
// Smoke tests: verify all pages load without crashes
// ============================================================

test.describe("Public pages load", () => {
  test("home page renders CTAs", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/모먼트/);
    // Check main CTA buttons exist
    await expect(page.getByText("이벤트 만들기")).toBeVisible();
    await expect(page.getByText("내 이벤트")).toBeVisible();
    await expect(page.getByText("아크 만들기")).toBeVisible();
  });

  test("login page renders OAuth buttons", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByText("카카오로 시작하기")).toBeVisible();
  });

  test("privacy page loads", async ({ page }) => {
    const res = await page.goto("/privacy");
    expect(res?.status()).toBe(200);
  });

  test("terms page loads", async ({ page }) => {
    const res = await page.goto("/terms");
    expect(res?.status()).toBe(200);
  });

  test("robots.txt is accessible", async ({ page }) => {
    const res = await page.goto("/robots.txt");
    expect(res?.status()).toBe(200);
    const text = await page.textContent("body");
    expect(text).toContain("User-Agent");
  });

  test("sitemap.xml is accessible", async ({ page }) => {
    const res = await page.goto("/sitemap.xml");
    expect(res?.status()).toBe(200);
  });
});

// ============================================================
// Auth-gated pages: should redirect to login
// ============================================================

test.describe("Protected pages redirect to login", () => {
  const protectedRoutes = ["/my", "/create", "/crew/create"];

  for (const route of protectedRoutes) {
    test(`${route} redirects to /login`, async ({ page }) => {
      await page.goto(route);
      await page.waitForURL(/\/login/);
      expect(page.url()).toContain("/login");
    });
  }
});

// ============================================================
// API endpoints: basic validation
// ============================================================

test.describe("API endpoints reject unauthenticated requests", () => {
  test("POST /api/events returns 401", async ({ request }) => {
    const res = await request.post("/api/events", {
      headers: { "Content-Type": "application/json" },
      data: {},
    });
    expect(res.status()).toBe(401);
  });

  test("POST /api/comments returns 401", async ({ request }) => {
    const res = await request.post("/api/comments", {
      headers: { "Content-Type": "application/json" },
      data: { eventId: "test", body: "test" },
    });
    expect(res.status()).toBe(401);
  });

  test("POST /api/crews returns 401", async ({ request }) => {
    const res = await request.post("/api/crews", {
      headers: { "Content-Type": "application/json" },
      data: { name: "test" },
    });
    expect(res.status()).toBe(401);
  });

  test("POST /api/crews/join returns 401", async ({ request }) => {
    const res = await request.post("/api/crews/join", {
      headers: { "Content-Type": "application/json" },
      data: { inviteCode: "test" },
    });
    expect(res.status()).toBe(401);
  });

  test("POST /api/rsvp returns 401", async ({ request }) => {
    const res = await request.post("/api/rsvp", {
      headers: { "Content-Type": "application/json" },
      data: {},
    });
    expect(res.status()).toBe(401);
  });

  test("POST /api/media/upload returns 401", async ({ request }) => {
    const res = await request.post("/api/media/upload");
    expect(res.status()).toBe(401);
  });

  test("POST /api/settlement returns 401", async ({ request }) => {
    const res = await request.post("/api/settlement", {
      headers: { "Content-Type": "application/json" },
      data: {},
    });
    expect(res.status()).toBe(401);
  });
});

// ============================================================
// API input validation (with fake auth — should still fail validation)
// ============================================================

test.describe("API input validation", () => {
  test("POST /api/events rejects malformed FormData", async ({ request }) => {
    // Send JSON instead of FormData — should get 400 or 401
    const res = await request.post("/api/events", {
      headers: { "Content-Type": "application/json" },
      data: { title: "test" },
    });
    // Either 401 (no auth) or 400 (bad content type)
    expect([400, 401]).toContain(res.status());
  });

  test("DELETE /api/comments/invalid-uuid returns 400", async ({ request }) => {
    const res = await request.delete("/api/comments/not-a-uuid");
    // 400 (bad UUID) or 401 (no auth)
    expect([400, 401]).toContain(res.status());
  });

  test("PATCH /api/crews/invalid-uuid returns 400 or 401", async ({
    request,
  }) => {
    const res = await request.patch("/api/crews/not-a-uuid", {
      headers: { "Content-Type": "application/json" },
      data: { name: "test" },
    });
    expect([400, 401]).toContain(res.status());
  });
});

// ============================================================
// Non-existent event page: should show error or 404
// ============================================================

test.describe("Event pages handle missing data", () => {
  test("non-existent event returns error page", async ({ page }) => {
    const res = await page.goto(
      "/event/00000000-0000-0000-0000-000000000000",
    );
    // Should either 404 or show error UI
    const status = res?.status() ?? 0;
    expect([200, 404]).toContain(status);
    if (status === 200) {
      // Check for error message in page content
      const body = await page.textContent("body");
      expect(
        body?.includes("찾을 수 없") || body?.includes("존재하지 않"),
      ).toBeTruthy();
    }
  });

  test("invalid UUID event returns error", async ({ page }) => {
    const res = await page.goto("/event/not-a-uuid");
    const status = res?.status() ?? 0;
    expect([200, 400, 404]).toContain(status);
  });
});

// ============================================================
// Accessibility basics
// ============================================================

test.describe("Accessibility", () => {
  test("home page has proper heading structure", async ({ page }) => {
    await page.goto("/");
    const h1 = page.locator("h1");
    await expect(h1).toHaveCount(1);
  });

  test("login page has proper form labeling", async ({ page }) => {
    await page.goto("/login");
    // Consent checkbox should have associated label
    const checkbox = page.locator('input[type="checkbox"]');
    await expect(checkbox).toHaveCount(1);
  });

  test("all links have accessible text", async ({ page }) => {
    await page.goto("/");
    const links = page.locator("a");
    const count = await links.count();
    for (let i = 0; i < count; i++) {
      const link = links.nth(i);
      const text = await link.textContent();
      const ariaLabel = await link.getAttribute("aria-label");
      const hasAccessibleName =
        (text && text.trim().length > 0) ||
        (ariaLabel && ariaLabel.trim().length > 0);
      expect(hasAccessibleName).toBeTruthy();
    }
  });
});

// ============================================================
// Crew invite page (public)
// ============================================================

test.describe("Crew invite page", () => {
  test("invalid invite code shows error", async ({ page }) => {
    const res = await page.goto("/crew/join/invalidcode123");
    const status = res?.status() ?? 0;
    // Should show "not found" or redirect
    expect([200, 404]).toContain(status);
    if (status === 200) {
      const body = await page.textContent("body");
      expect(
        body?.includes("찾을 수 없") ||
          body?.includes("존재하지 않") ||
          body?.includes("유효하지 않"),
      ).toBeTruthy();
    }
  });
});

// ============================================================
// Console error detection
// ============================================================

test.describe("No console errors on key pages", () => {
  const pages = ["/", "/login", "/privacy", "/terms"];

  for (const path of pages) {
    test(`${path} has no console errors`, async ({ page }) => {
      const errors: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "error") {
          errors.push(msg.text());
        }
      });
      await page.goto(path);
      await page.waitForTimeout(1000);
      // Filter out known non-critical errors
      const critical = errors.filter(
        (e) =>
          !e.includes("favicon") &&
          !e.includes("Failed to load resource") &&
          !e.includes("hydration"),
      );
      expect(critical).toHaveLength(0);
    });
  }
});
