# Fedirelm: a multi backend Fediverse client (Mastodon, Pleroma, GoToSocial,…)

> **Warning**
>
> This is still a Work In Progress

## Why?

I love the diversity of the Fediverse, I hate having to use multiple clients to be able to connect to my servers.

The main goal of this code is to provide a client and a library that can connect to multiple Fediverse backends while providing an unified UX to do so.

## How?

The code is splitted in two parts:

- `Fediverse` is the library abstracting the connection to the backends
- `Fedirelm` is the web client using the `Fediverse` library to provide an usable UI

## Inspiration

I'm reading [megalodon-rs](https://github.com/h3poteto/megalodon-rs) source code a lot to check how they are doing the backend abstraction.

## FAQ

### Can I use it?

No really for now. You can contribute by mapping some backends if you want to, but it's not usable in production for now.

### What are the supported backend?

For now I plan to support:

- Mastodon
- Pleroma
- GoToSocial

Mostly because I have accounts on some servers. _Firefish_ and _Friendica_ support may come in the future.

### Will it support backend X

Who knows? The goal of the library is to abstract the backends, so any new backend could be supported in the future.

### Why Elm?

[Elm](https://elm-lang.org/) is still, by far, the best language to make reliable frontend web apps. The [community](https://elm-lang.org/community) is thriving, the language is very stable and I know I will be able to maintain this code ten years from now thanks to Elm type system.

### Will it be available as a Desktop or Mobile app?

It's part of the plan, at some point using [Tauri](https://tauri.app/) as I did for [Pomodorolm](https://github.com/vjousse/pomodorolm).

## License

[AGPL-3.0-or-later](https://www.gnu.org/licenses/agpl-3.0.html
![AGDL v3 logo](agplv3.png)
