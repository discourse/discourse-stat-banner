import { apiInitializer } from "discourse/lib/api";
import StatBanner from "../components/stat-banner";

export default apiInitializer("1.14.0", (api) => {
  api.renderInOutlet(settings.plugin_outlet.trim(), StatBanner);
});
