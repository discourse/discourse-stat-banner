import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

function setupDisplayStats() {
  settings.display_stats = JSON.stringify([
    { source: "topics", period: "30_days", title: "Cool Topics" },
    { source: "likes", period: "7_days", title: "Total Likes", link: "/likes" },
  ]);
}

acceptance("Stat Banner", function () {
  test("Banner shows based on settings", async function (assert) {
    setupDisplayStats();

    await visit("/");

    assert.dom(".stat-banner__wrapper li").exists("the banner displays stats");
  });

  test("Banner does not appear without setting", async function (assert) {
    settings.display_stats = "";

    await visit("/");

    assert
      .dom(".stat-banner__wrapper")
      .doesNotExist("the banner does not display");
  });

  test("Banner only appears on the homepage based on setting", async function (assert) {
    setupDisplayStats();

    settings.show_on = "homepage";

    await visit("/");

    assert
      .dom(".stat-banner__wrapper")
      .exists("the banner displays on the homepage");

    await visit("/top");

    assert
      .dom(".stat-banner__wrapper")
      .doesNotExist("the banner does not display on other pages");
  });

  test("Banner only appears on the top_menu routes based on setting", async function (assert) {
    setupDisplayStats();

    settings.show_on = "latest/top/new/categories";

    await visit("/categories");

    assert
      .dom(".stat-banner__wrapper")
      .exists("the banner displays on /categories");

    await visit("/latest");

    assert
      .dom(".stat-banner__wrapper")
      .exists("the banner displays on /latest");

    await visit("/u");

    assert
      .dom(".stat-banner__wrapper")
      .doesNotExist("the banner does not display on /u");
  });

  test("Banner sets local storage cache", async function (assert) {
    setupDisplayStats();
    settings.show_on = "homepage";

    await visit("/");

    assert.ok(
      localStorage.getItem("about_stats"),
      "creates localStorage cache",
    );
  });

  test("Color settings set CSS", async function (assert) {
    setupDisplayStats();
    settings.show_on = "homepage";

    await visit("/");

    assert.ok(
      localStorage.getItem("about_stats"),
      "creates localStorage cache",
    );
  });
});

acceptance("Stat Banner - Mobile", function (needs) {
  needs.mobileView();
  settings.show_on = "everywhere";

  test("Banner appears on mobile when allowed", async function (assert) {
    setupDisplayStats();

    settings.hide_on_mobile = true;

    await visit("/");

    assert
      .dom(".stat-banner__wrapper")
      .doesNotExist("the banner does not display on mobile");
  });

  test("Banner appears on mobile when allowed", async function (assert) {
    setupDisplayStats();

    settings.hide_on_mobile = false;

    await visit("/");

    assert.dom(".stat-banner__wrapper").exists("the banner displays on mobile");
  });
});
