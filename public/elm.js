import { Elm } from "../src/Main.elm";

const appPrefix = "fedirelm";
const appDatasKey = `${appPrefix}.app_datas`;
const appSessionsKey = `${appPrefix}.app_sessions`;

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

const seeds = Array.from(crypto.getRandomValues(new Uint32Array(4)));

const appSessions = JSON.parse(localStorage.getItem(appSessionsKey));

const app = Elm.Main.init({
  flags: {
    location: window.origin,
    appDatas: appDatas,
    seeds: {
      seed1: seeds[0],
      seed2: seeds[1],
      seed3: seeds[2],
      seed4: seeds[3],
    },
    sessions: appSessions,
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

app.ports.deleteAppData.subscribe((uuid) => {
  console.log(`Should remove app data with uuid ${uuid}`);

  const appDatas = JSON.parse(localStorage.getItem(appDatasKey));

  if (appDatas) {
    const appDatasToKeep = appDatas.filter(
      (appData) => appData["uuid"] != uuid
    );

    if (appDatasToKeep.length === 0) {
      localStorage.removeItem(appDatasKey);
    } else {
      localStorage.setItem(appDatasKey, JSON.stringify(appDatasToKeep));
    }
  }
});

app.ports.saveSessions.subscribe((jsonString) => {
  localStorage.setItem(appSessionsKey, jsonString);
});
