import { apiInitializer } from "discourse/lib/api";
import StatBanner from "../components/stat-banner";

export default apiInitializer((api) => {
  api.renderInOutlet(settings.plugin_outlet.trim(), StatBanner);
});
