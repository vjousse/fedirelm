import { Elm } from "../src/Main.elm";

const appPrefix = "fedirelm";
const appDatasKey = `${appPrefix}.app_datas`;

// One hour (in seconds)
const appDatasStorageDuration = 60 * 60;

// Get the current registration data stored in local storage
let appDatas = JSON.parse(localStorage.getItem(appDatasKey));

// Clear unused stored app datas (registration processes not finished)
if (appDatas) {
  const appDatasToKeep = appDatas.filter((appData) => {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    return currentTimestamp - appData["createdAt"] < appDatasStorageDuration;
  });

  if (appDatasToKeep.length != appDatas.length) {
    appDatas = appDatasToKeep;
    localStorage.setItem(appDatasKey, JSON.stringify(appDatas));
  }
}

const app = Elm.Main.init({
  flags: {
    location: window.location.href,
    appDatas: appDatas,
  },
});

app.ports.saveAppData.subscribe((jsonString) => {
  const json = JSON.parse(jsonString);

  // Get the current registration data stored in local storage
  let appDatas = JSON.parse(localStorage.getItem(appDatasKey));

  // If none create it
  if (!appDatas) {
    appDatas = [];
  }

  // Store the timestamp of creation to be able to clean later on
  const currentTimestamp = Math.floor(Date.now() / 1000);
  json["createdAt"] = currentTimestamp;
  appDatas.push(json);
  localStorage.setItem(appDatasKey, JSON.stringify(appDatas));
});

app.ports.deleteAppData.subscribe((clientId) => {
  console.log(`Should remove app data with ${clientId}`);
  //localStorage.removeItem(appDataKey);
});
