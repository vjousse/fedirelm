import { Elm } from "../src/Main.elm";

const app = Elm.Main.init({
  flags: {
    location: window.location.href,
    appData: JSON.parse(localStorage.getItem("fedirelm.app_data")),
  },
});

app.ports.saveAppData.subscribe((json) => {
  localStorage.setItem("fedirelm.app_data", json);
});

app.ports.deleteAppData.subscribe((json) => {
  localStorage.removeItem("fedirelm.app_data");
});
