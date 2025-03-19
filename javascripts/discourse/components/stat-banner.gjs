import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { ajax } from "discourse/lib/ajax";
import { defaultHomepage } from "discourse/lib/utilities";

export default class StatBanner extends Component {
  @service site;
  @service siteSettings;
  @service router;

  @tracked stats;

  <template>
    {{! template-lint-disable modifier-name-case }}
    {{#if this.shouldShow}}
      <div class="stat-banner__wrapper" {{didInsert this.getAboutStats}}>
        {{#if settings.banner_title}}
          <div class="stat-banner__title">
            {{htmlSafe settings.banner_title}}
          </div>
        {{/if}}
        <ul>
          {{#each this.filteredStats as |s|}}
            <li>
              {{#if s.link}}
                <a href={{s.link}}><span>{{s.value}}</span>
                  <span>{{s.title}}</span></a>
              {{else}}
                <div>
                  <span>{{s.value}}</span>
                  <span>{{s.title}}</span>
                </div>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      </div>
    {{/if}}
  </template>

  get shouldShow() {
    if (
      !settings.display_stats ||
      (settings.hide_on_mobile && this.site.mobileView)
    ) {
      return false;
    }

    const currentRoute = this.router.currentRouteName;

    switch (settings.show_on) {
      case "everywhere":
        return !currentRoute.includes("admin");

      case "homepage":
        return currentRoute === `discovery.${defaultHomepage()}`;

      case "latest/top/new/categories":
        const topMenu = this.siteSettings.top_menu;
        const targets = topMenu.split("|").map((opt) => `discovery.${opt}`);
        return targets.includes(currentRoute);

      default:
        return false;
    }
  }

  get filteredStats() {
    if (!this.stats) {
      return [];
    }

    const statConfig = JSON.parse(settings.display_stats);
    return statConfig
      .map((config) => {
        const keyName = `${config.source}_${config.period}`;
        const statValue = this.stats[keyName];

        if (statValue !== undefined) {
          return {
            title: config.title,
            value: config.manual_value || statValue,
            link: config.link,
            period: config.period,
          };
        }
      })
      .filter(Boolean);
  }

  saveToCache(key, value, expiryInMilliseconds) {
    if (!key || !value || !expiryInMilliseconds) {
      return;
    }

    const now = new Date();
    const item = {
      value,
      expiry: now.getTime() + expiryInMilliseconds,
    };

    try {
      localStorage.setItem(key, JSON.stringify(item));
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn("Couldn't save to localStorage:", error);
    }
  }

  loadFromCache(key) {
    if (!key) {
      return null;
    }

    try {
      const itemStr = localStorage.getItem(key);

      if (!itemStr) {
        return null;
      }

      const item = JSON.parse(itemStr);
      const now = new Date();

      if (now.getTime() > item.expiry) {
        localStorage.removeItem(key);
        return null;
      }

      return item.value;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.warn("Couldn't read from localStorage:", error);
      return null;
    }
  }

  cacheStats() {
    if (!this.stats || !this.filteredStats.length) {
      return;
    }

    const lowestPeriod = Math.min(
      ...this.filteredStats.map((stat) => this.parseDaysFromStat(stat.period))
    );

    const expiryInMilliseconds = lowestPeriod * 24 * 60 * 60 * 1000;
    this.saveToCache("about_stats", this.stats, expiryInMilliseconds);
    this.saveToCache(
      "banner_stats_setting",
      settings.display_stats,
      expiryInMilliseconds
    );
  }

  parseDaysFromStat(stat) {
    if (stat === "last_day") {
      return 1;
    }
    const parts = stat.split("_");
    return parseInt(parts[0], 10);
  }

  @action
  async getAboutStats() {
    let cachedStats = this.loadFromCache("about_stats");
    let cachedSetting = this.loadFromCache("banner_stats_setting");

    if (
      !settings.disable_cache &&
      cachedStats &&
      settings.display_stats === cachedSetting
    ) {
      this.stats = cachedStats;
      return;
    }

    try {
      const result = await ajax("/about.json");
      this.stats = result.about.stats;
      if (settings.disable_cache) {
        localStorage.removeItem("about_stats");
        localStorage.removeItem("banner_stats_setting");
      } else {
        this.cacheStats();
      }
    } catch (error) {
      this.stats = null;
      // eslint-disable-next-line no-console
      console.error("Stat Banner failed to fetch data", error);
      throw error;
    }
  }
}
