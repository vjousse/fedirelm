import { Elm } from "../src/Main.elm";

const appPrefix = "fedirelm.";
const appDataKey = `${appPrefix}app_data`;

const app = Elm.Main.init({
  flags: {
    location: window.location.href,
    appData: JSON.parse(localStorage.getItem(appDataKey)),
  },
});

app.ports.saveAppData.subscribe((json) => {
  localStorage.setItem(appDataKey, json);
});

app.ports.deleteAppData.subscribe(() => {
  localStorage.removeItem(appDataKey);
});
